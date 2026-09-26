import 'dart:typed_data';

import 'package:readiness_check/readiness_check.dart';
import 'package:test/test.dart';

/// Builds a minimal synthetic ELF file (header + one `PT_LOAD` program
/// header per entry in [loadSegmentAlignments]) with the given `p_align`
/// values. No section headers, no code — only what [checkSoAlignment] reads.
Uint8List _buildElf({
  required bool is64Bit,
  required List<int> loadSegmentAlignments,
}) {
  final ehsize = is64Bit ? 64 : 52;
  final phentsize = is64Bit ? 56 : 32;
  final phnum = loadSegmentAlignments.length;
  final headerStart = ehsize;
  final totalSize = headerStart + phentsize * phnum;

  final bytes = Uint8List(totalSize);
  final data = ByteData.sublistView(bytes);

  bytes[0] = 0x7f;
  bytes[1] = 0x45; // 'E'
  bytes[2] = 0x4c; // 'L'
  bytes[3] = 0x46; // 'F'
  bytes[4] = is64Bit ? 2 : 1; // EI_CLASS
  bytes[5] = 1; // EI_DATA: little-endian

  if (is64Bit) {
    data.setUint64(32, headerStart, Endian.little); // e_phoff
    data.setUint16(54, phentsize, Endian.little); // e_phentsize
    data.setUint16(56, phnum, Endian.little); // e_phnum
  } else {
    data.setUint32(28, headerStart, Endian.little); // e_phoff
    data.setUint16(42, phentsize, Endian.little); // e_phentsize
    data.setUint16(44, phnum, Endian.little); // e_phnum
  }

  for (var i = 0; i < phnum; i++) {
    final offset = headerStart + i * phentsize;
    data.setUint32(offset, 1, Endian.little); // p_type = PT_LOAD
    if (is64Bit) {
      data.setUint64(offset + 48, loadSegmentAlignments[i], Endian.little);
    } else {
      data.setUint32(offset + 28, loadSegmentAlignments[i], Endian.little);
    }
  }

  return bytes;
}

void main() {
  group('checkSoAlignment', () {
    test('64-bit LOAD segment aligned at exactly 16 KB is aligned', () {
      final bytes = _buildElf(is64Bit: true, loadSegmentAlignments: [0x4000]);

      final result = checkSoAlignment('lib/libfoo.so', bytes);

      expect(result.aligned, isTrue);
      expect(result.minLoadSegmentAlignment, 0x4000);
    });

    test('64-bit LOAD segment aligned below 16 KB is misaligned', () {
      final bytes = _buildElf(is64Bit: true, loadSegmentAlignments: [0x1000]);

      final result = checkSoAlignment('lib/libfoo.so', bytes);

      expect(result.aligned, isFalse);
      expect(result.minLoadSegmentAlignment, 0x1000);
    });

    test('32-bit LOAD segment aligned at 16 KB is aligned', () {
      final bytes = _buildElf(is64Bit: false, loadSegmentAlignments: [0x4000]);

      final result = checkSoAlignment('lib/libfoo.so', bytes);

      expect(result.aligned, isTrue);
      expect(result.minLoadSegmentAlignment, 0x4000);
    });

    test('32-bit LOAD segment aligned below 16 KB is misaligned', () {
      final bytes = _buildElf(is64Bit: false, loadSegmentAlignments: [0x1000]);

      final result = checkSoAlignment('lib/libfoo.so', bytes);

      expect(result.aligned, isFalse);
      expect(result.minLoadSegmentAlignment, 0x1000);
    });

    test('reports the smallest alignment when only one of several LOAD segments is misaligned', () {
      final bytes = _buildElf(
        is64Bit: true,
        loadSegmentAlignments: [0x4000, 0x1000, 0x8000],
      );

      final result = checkSoAlignment('lib/libfoo.so', bytes);

      expect(result.aligned, isFalse);
      expect(result.minLoadSegmentAlignment, 0x1000);
    });

    test('throws NotElfException for bytes without the ELF magic number', () {
      final bytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);

      expect(
        () => checkSoAlignment('lib/libfoo.so', bytes),
        throwsA(isA<NotElfException>()),
      );
    });
  });

  group('checkPackageAlignment', () {
    test('runs checkSoAlignment over every entry', () {
      final results = checkPackageAlignment({
        'lib/aligned.so': _buildElf(
          is64Bit: true,
          loadSegmentAlignments: [0x4000],
        ),
        'lib/misaligned.so': _buildElf(
          is64Bit: true,
          loadSegmentAlignments: [0x1000],
        ),
      });

      expect(results, hasLength(2));
      expect(
        results.firstWhere((r) => r.path == 'lib/aligned.so').aligned,
        isTrue,
      );
      expect(
        results.firstWhere((r) => r.path == 'lib/misaligned.so').aligned,
        isFalse,
      );
    });
  });

  group('isSharedLibraryPath', () {
    test('matches paths ending in .so', () {
      expect(
        isSharedLibraryPath('android/src/main/jniLibs/arm64-v8a/libfoo.so'),
        isTrue,
      );
    });

    test('does not match other paths', () {
      expect(isSharedLibraryPath('ios/some_plugin/Package.swift'), isFalse);
    });
  });
}
