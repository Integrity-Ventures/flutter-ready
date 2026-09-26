import 'dart:typed_data';

const _elfMagic = [0x7f, 0x45, 0x4c, 0x46]; // \x7fELF
const _ptLoad = 1;

/// The 16 KB page-alignment threshold Play requires (SPEC §3.1.2, §1).
const requiredLoadSegmentAlignment = 0x4000;

/// Whether an archive entry path is a native shared library.
bool isSharedLibraryPath(String path) => path.endsWith('.so');

/// Thrown by [checkSoAlignment] when the given bytes don't start with the
/// ELF magic number.
class NotElfException implements Exception {
  NotElfException(this.path);

  final String path;

  @override
  String toString() => 'NotElfException: $path is not an ELF file';
}

/// The 16 KB alignment result for a single `.so` file (SPEC §3.1.2).
class ElfAlignmentResult {
  const ElfAlignmentResult({
    required this.path,
    required this.aligned,
    required this.minLoadSegmentAlignment,
  });

  /// The archive entry path of the checked `.so` file.
  final String path;

  /// True when every `PT_LOAD` segment's alignment is
  /// >= [requiredLoadSegmentAlignment]. Vacuously true when the file has no
  /// `PT_LOAD` segment.
  final bool aligned;

  /// The smallest `PT_LOAD` segment alignment found, in bytes — the evidence
  /// a misaligned result shows (SPEC §3.2). Null if the file has no
  /// `PT_LOAD` segment.
  final int? minLoadSegmentAlignment;
}

/// Reads [path]'s ELF program headers (32-bit or 64-bit, either endianness)
/// and checks every `PT_LOAD` segment's alignment against
/// [requiredLoadSegmentAlignment] (SPEC §3.1.2).
ElfAlignmentResult checkSoAlignment(String path, List<int> bytes) {
  if (bytes.length < 6 ||
      bytes[0] != _elfMagic[0] ||
      bytes[1] != _elfMagic[1] ||
      bytes[2] != _elfMagic[2] ||
      bytes[3] != _elfMagic[3]) {
    throw NotElfException(path);
  }
  final is64Bit = bytes[4] == 2;
  final endian = bytes[5] == 2 ? Endian.big : Endian.little;
  final data = ByteData.sublistView(Uint8List.fromList(bytes));

  final int phoff;
  final int phentsize;
  final int phnum;
  if (is64Bit) {
    phoff = data.getUint64(32, endian);
    phentsize = data.getUint16(54, endian);
    phnum = data.getUint16(56, endian);
  } else {
    phoff = data.getUint32(28, endian);
    phentsize = data.getUint16(42, endian);
    phnum = data.getUint16(44, endian);
  }

  int? minAlignment;
  for (var i = 0; i < phnum; i++) {
    final headerOffset = phoff + i * phentsize;
    final pType = data.getUint32(headerOffset, endian);
    if (pType != _ptLoad) continue;
    final pAlign = is64Bit
        ? data.getUint64(headerOffset + 48, endian)
        : data.getUint32(headerOffset + 28, endian);
    if (minAlignment == null || pAlign < minAlignment) {
      minAlignment = pAlign;
    }
  }

  return ElfAlignmentResult(
    path: path,
    aligned:
        minAlignment == null || minAlignment >= requiredLoadSegmentAlignment,
    minLoadSegmentAlignment: minAlignment,
  );
}

/// Runs [checkSoAlignment] over every entry in [soFileContents].
List<ElfAlignmentResult> checkPackageAlignment(
  Map<String, List<int>> soFileContents,
) {
  return [
    for (final entry in soFileContents.entries)
      checkSoAlignment(entry.key, entry.value),
  ];
}
