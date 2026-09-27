# Microtask Instruction: tolerate zero-padded gzip archives (OPEN, needs an owner card)

Status: **OPEN.** Found by the architect on 2026-09-27 while reviewing
"Checker: check unknown plugins live". It needs an owner-created card to
run. Read `00_ARCHITECT_GATE.md` first: claim first, stop if the claim fails.

## Finding

Some pub.dev archives fail in our code with
`FormatException: Filter error, bad data`, while `tar tzf` and `gzip -t`
read them fine. Measured 2026-09-27 on flutter_barcode_scanner 2.0.0,
flutter_widgetkit and ios_insecure_screen_detector (latest):
- Content-Type `application/octet-stream`, gzip magic `1f8b`, and a size that's
  an exact multiple of 10240 bytes (174080, 358400, 61440): the gzip stream
  is followed by zero padding up to a tar record boundary.
- Standard gzip ignores trailing zeros; dart:io's ZLibDecoder (used by
  package:archive's GZipDecoder on the VM) raises "Filter error, bad data".

Impact: those plugins show "Not checked" on the board (3 today) and in the
CLI. That's safe (never green), but wrong.

## Fix

In `packages/readiness_check` archive decoding: decode only the first gzip
member and ignore the trailing bytes when they're all zero. For example,
try the normal decode, and on FormatException retry after trimming
trailing 0x00 bytes; or use package:archive's pure-Dart inflater with the
explicit member length. Never swallow a real corruption: if non-zero
trailing garbage remains, keep it as an error.

## Tests and check

- Offline test: a valid tar.gz with 10240-byte zero padding decodes; a
  tar.gz with non-zero trailing garbage still errors; a truncated archive
  still errors.
- Regenerate data in the FOREGROUND; the 3 current "Not checked" plugins
  get real verdicts (or a different, real error).
- Gates in all four packages. Lane branch `feature/gzip-padding`.
