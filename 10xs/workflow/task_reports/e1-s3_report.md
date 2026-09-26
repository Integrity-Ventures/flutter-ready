# Completion Report: e1-s3 — 16 KB native alignment check

Instruction: `10xs/workflow/instructions/20260926_04_e1-s3-alignment.md`

## Work Completed

Extends `packages/readiness_check` (from e1-s2, merged to `develop` at
`9233677`) with the 16 KB native-library alignment check from SPEC §3.1.2.

| File | Lines | Purpose |
|---|---|---|
| `lib/src/package_archive.dart` | 27 (+18) | Factors the gzip+tar decode into a private `_decodePackageArchive` helper shared by the existing `listArchiveEntryPaths` and the new `extractArchiveEntries(bytes, predicate)`, which returns entry *contents* (not just paths) for entries matching a predicate |
| `lib/src/elf_alignment_check.dart` | 102 | `isSharedLibraryPath(path)`, `checkSoAlignment(path, bytes)` → `ElfAlignmentResult {path, aligned, minLoadSegmentAlignment}`, `checkPackageAlignment(soFileContents)`, and `NotElfException` |
| `lib/readiness_check.dart` | 13 (+9) | Exports the new public symbols |
| `test/elf_alignment_check_test.dart` | 149 | Synthetic ELF32/ELF64 byte buffers (hand-built headers, no fixture binaries) covering aligned/misaligned, both bit-widths, multi-segment, and non-ELF input |
| `test/package_archive_test.dart` | 78 (+33) | `extractArchiveEntries` predicate matching and empty-match cases |

All implementation files are well under the 150-line stop-and-refactor limit
(largest is 102 lines).

## Design Notes

- `checkSoAlignment` reads the ELF header directly (magic number, `EI_CLASS`
  for 32/64-bit, `EI_DATA` for endianness) and then every program header's
  `p_type`/`p_align`, rather than depending on an ELF-parsing package —
  SPEC §3.1.2 only needs `PT_LOAD` alignment, so a full ELF/DWARF parser
  would be unused surface area.
- `aligned` follows SPEC §3.1.2's literal wording: every `PT_LOAD` segment's
  alignment must be `>= 0x4000`. A segment with `p_align` of `0` or `1`
  ("no particular alignment" in the ELF spec) is therefore reported as
  misaligned — this matches how Android's own 16 KB alignment-check tooling
  reads the field, rather than treating it as a free pass.
- `minLoadSegmentAlignment` carries the *smallest* `PT_LOAD` alignment found,
  so a misaligned result names the actual value — SPEC §3.2 needs this for
  the board's evidence column ("the misaligned library and its alignment").
  It's `null` only when a `.so` has no `PT_LOAD` segment at all (vacuously
  `aligned: true`).
- `package_archive.dart`'s gzip+tar decode was previously inlined in
  `listArchiveEntryPaths`; factoring it into `_decodePackageArchive` lets
  `extractArchiveEntries` reuse it instead of decoding the archive twice.
- `isSharedLibraryPath` (`path.endsWith('.so')`) is exported as the
  `.so`-selection predicate so a caller can pass it straight into
  `extractArchiveEntries(bytes, isSharedLibraryPath)` — the wiring itself
  (fetching an archive and running both together) is e2-s1's scope (snapshot
  assembly), not this microtask's.
- Both 32-bit (`armeabi-v7a`, `x86`) and 64-bit (`arm64-v8a`, `x86_64`) ELF
  layouts are handled, since Android plugins ship both; endianness is read
  from `EI_DATA` rather than assumed, though every real Android target is
  little-endian.

## Automated Test Results

```
$ dart analyze --fatal-infos
Analyzing readiness_check...
No issues found!

$ dart test
00:00 +23: All tests passed!
```

23 tests total (12 pre-existing, 9 new in `elf_alignment_check_test.dart`, 2
new in `package_archive_test.dart`). Zero network calls: every ELF byte
buffer is built by hand in test setup with chosen `p_align` values; no
fixture binaries are committed. Real aligned/misaligned `.so` fixtures are
e6-s1's scope (recorded fixtures), not this microtask's.

## Build Verification

No production build step applies to a library package. `dart analyze
--fatal-infos` (exit 0) and `dart format --output=none --set-exit-if-changed
.` (clean after running `dart format .`) both pass.

## Known Issues / Limitations

- No live pub.dev archive was fetched for this microtask — `checkSoAlignment`
  is exercised only against synthetic ELF buffers. Wiring it against a real
  plugin's archive bytes (via `PubDevClient.fetchArchiveBytes` +
  `extractArchiveEntries`) is e2-s1's scope.
- No UI component in this microtask, so no screenshot evidence applies.

## Suggested Commit Message

```
Add 16 KB native alignment check to readiness_check package

Implements SPEC §3.1.2: reads each .so file's ELF program headers and
flags any PT_LOAD segment aligned below 16 KB (0x4000), reporting the
actual alignment found for the board's evidence column (SPEC §3.2).

Co-Authored-By: 10xs.ai
```
