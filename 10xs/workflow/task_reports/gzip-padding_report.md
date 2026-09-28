# Tolerate zero-padded gzip archives — completion report

Instruction: `10xs/workflow/instructions/20260927_18_gzip-trailing-padding.md`

Branch: `feature/gzip-padding`
Commit: `caa012a`

## Finding recap

`packages/readiness_check`'s archive decoding called
`GZipDecoder().decodeBytes(archiveBytes)`, which on the VM delegates to
`dart:io`'s `GZipCodec().decode`. Some pub.dev archives are followed by
zero-byte padding up to a 10240-byte tar record boundary; that codec treats
any trailing bytes as the start of a second gzip member and raises
`FormatException: Filter error, bad data` when they don't parse as one — even
though the archive's own gzip member is complete and valid.

Separately, while building the fix I found that `GZipDecoder().decodeBytes`
(the method the old code called) has no way to detect a **truncated**
archive at all: `dart:io`'s decoder silently returns however much it managed
to decode, with no exception and no other signal. The instruction's own test
list ("a truncated archive still errors") requires this to error, so the fix
had to add real truncation detection, not just padding tolerance.

## Fix

`packages/readiness_check/lib/src/package_archive.dart`: replaced the single
`decodeBytes` call with `_decodeGZipMember`, which uses
`GZipDecoder().decodeStream(InputMemoryStream, OutputMemoryStream)` instead.
`decodeStream` returns `false` (rather than throwing) for a member that
never completes — that's the truncation signal `decodeBytes` doesn't give.

For the padding case: I first tried the simpler fix the instruction
suggested literally ("retry after trimming trailing 0x00 bytes"), but it's
unsafe — a gzip trailer's ISIZE field is the uncompressed size mod 2^32
little-endian, so it legitimately ends in zero bytes for almost any file
under 16 MB (and both trailing bytes are zero under 64 KB). Blindly
stripping all trailing zeros from a padded buffer strips into the real
trailer too, and I reproduced this concretely: a 5000-byte payload's gzip
member itself ends in `...,26,0,0`, so naive stripping removed the genuine
final two trailer bytes along with the padding and turned a valid decode
into a false "truncated" error.

Instead, `_decodeGZipMember` treats `decodeStream`'s outcome at prefix
length `L` as a three-zone function of `L` — incomplete while short of the
member's true end, complete exactly at that end (verified empirically:
complete at the true end and at one byte past it, since the decoder can't
yet tell a lone stray byte apart from noise; erroring once two or more bytes
past it fail to parse as a continuation — and bisects over `L` to land in
the complete zone in O(log n) tries instead of scanning byte-by-byte. Once a
complete prefix is found, everything after it must be all zero or the
function throws (`FormatException`), which is what actually rejects
non-zero trailing garbage — bisection alone would tolerate it too, since a
single leftover garbage byte is exactly as invisible to the decoder as a
single leftover zero byte.

Reused `package:archive`'s own `InputMemoryStream`/`OutputMemoryStream`
(both public exports of `package:archive/archive.dart`, not `src/`-only
internals) rather than adding a new dependency.

## Tests added

`packages/readiness_check/test/package_archive_test.dart`, new group
`zero-padded gzip archives`:
- a valid tar.gz padded with zero bytes to a 10240-byte boundary decodes
  correctly (entries listed, matches pre-padding content)
- the same archive with non-zero trailing garbage in place of the padding
  still throws
- a truncated archive (last 20 bytes cut) still throws

All three pass; the existing corrupt-archive test (`[0x1f, 0x8b, 1..10]`, a
non-zero non-multiple-of-10240-friendly stub) still throws unchanged.

Manually verified the fix against 6 payload sizes (0, 1, 100, 5000, 20000,
65600 bytes — straddling the 65536-byte ISIZE-byte-3 boundary and the
16 MB-adjacent shape of real packages) crossed with all four scenarios
(valid / zero-padded / non-zero-garbage / truncated) before writing the
final test file, plus a 2 MB payload for timing (135 ms with padding,
dominated by the archive encode/decode itself, not the bisection).

## Gates

```
$ cd packages/flutter_ready    && dart pub get && dart analyze --fatal-infos && dart test   # 26 tests, pass
$ cd packages/readiness_check  && dart analyze --fatal-infos && dart test                   # 69 tests, pass (66 pre-existing + 3 new)
$ cd packages/snapshot_job     && dart pub get && dart analyze --fatal-infos && dart test    # 10 tests, pass
$ cd site                      && dart pub get && dart analyze --fatal-infos && dart test    # 28 tests, pass
```

`flutter_ready`, `snapshot_job` and `site` needed `dart pub get` first (no
`.dart_tool/` yet in this fresh clone) — no source changes were needed in
any of the three; they were unaffected by this fix and gate clean as-is.

## Data regenerated in the foreground

```
$ cd packages/snapshot_job && dart run bin/snapshot.dart --top 100 --out ../../data/snapshots/
Assembled 145 plugin(s) from 145 candidate(s) in 0:00:34.
```

Diffed `data/latest.json` before/after by `errors` field across all 145
plugins: exactly two changed, both from the instruction's list, both from
erroring to a clean real verdict, nothing else moved:

- `flutter_widgetkit`: `["...archive decode: FormatException: Filter error, bad data", ...]` → `[]` (now: `swiftpm.tag=false, archive=false, agrees=true`; `alignment.soFiles=[]`; `android.compileSdk=null`)
- `ios_insecure_screen_detector`: same error shape → `[]` (now: `swiftpm` same as above; `android.compileSdk="30", agp="4.1.0"`)

`flutter_barcode_scanner`, the instruction's third named plugin, is not
among the top-100 discovered candidates in this run (confirmed it's also
absent from the pre-fix `data/latest.json` on `develop`) — it's outside
this package's discovery-driven data path; the instruction's "Checker:
check unknown plugins live" card's CLI live-check path handles packages
outside the top-N by construction, so this is expected, not a gap this
card leaves open. Both plugins the nightly job actually reaches are fixed.

## Files changed

| File | Notes |
|---|---|
| `packages/readiness_check/lib/src/package_archive.dart` | Replaced `decodeBytes` with `_decodeGZipMember` (bisection + trailing-zero check + truncation detection) |
| `packages/readiness_check/test/package_archive_test.dart` | New `zero-padded gzip archives` test group (3 tests) |
| `data/latest.json` | Regenerated in the foreground; only the two plugins above changed |
| `data/snapshots/2026-09-28.json` | New dated snapshot from the same run |

## Known issues or limitations

- The bisection's "complete zone" is at most 2 bytes wide (the true member
  end and one byte past it), which is inherent to how far `dart:io`'s
  decoder can see with under 2 trailing bytes — pre-existing leniency, not
  introduced here (confirmed the original `decodeBytes` call also silently
  accepted a single stray trailing byte of any value). The explicit
  all-zero check on whatever remains past the found prefix is what actually
  enforces "non-zero trailing garbage still errors" for anything longer
  than that.
- Per the architect gate: this branch was pushed to this clone's local
  `origin` (`~/flutter-ready`), not to github.com. The architect moves it
  from there.

## Suggested commit message

Already used verbatim for this card's single commit:

```
Tolerate zero-padded gzip archives in package_archive decoding

Some pub.dev archives are padded with zero bytes to a 10240-byte tar
record boundary, which dart:io's ZLibDecoder rejects with "Filter
error, bad data" even though the gzip member itself is complete and
valid. Locate the true end of the first gzip member via a bisection
search over decodeStream's incomplete/complete/error response at each
prefix length, and accept the member only if everything past that
point is zero; non-zero trailing garbage and genuinely truncated
archives still throw. Regenerated data/latest.json in the foreground:
flutter_widgetkit and ios_insecure_screen_detector now grade instead
of erroring, no other plugin's result changed.

Co-Authored-By: 10xs.ai
```
