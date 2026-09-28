// Regenerates the binary fixtures under test/fixtures/archives/ and
// test/fixtures/so_files/, from the plain-text sources under
// test/fixtures/sources/. Run from the flutter_ready package root:
//
//   dart run test/fixtures/generate_fixtures.dart
//
// The JSON fixtures under test/fixtures/pub_dev/ are not touched by this
// script — they were captured by hand from live pub.dev responses (see
// README.md) and are edited directly.
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

const _sourcesDir = 'test/fixtures/sources';
const _archivesDir = 'test/fixtures/archives';
const _soDir = 'test/fixtures/so_files';

void main() {
  if (!Directory('test/fixtures').existsSync()) {
    stderr.writeln(
      'Run this from the flutter_ready package root (test/fixtures/ not found here).',
    );
    exitCode = 1;
    return;
  }
  Directory(_archivesDir).createSync(recursive: true);
  Directory(_soDir).createSync(recursive: true);

  final alignedSo = buildElf(loadSegmentAlignments: [0x4000]);
  final misalignedSo = buildElf(loadSegmentAlignments: [0x1000]);
  File('$_soDir/aligned_arm64-v8a.so').writeAsBytesSync(alignedSo);
  File('$_soDir/misaligned_arm64-v8a.so').writeAsBytesSync(misalignedSo);

  // Real archives, trimmed to the files the readiness checks read, copied
  // verbatim from pub.dev on 2026-09-26 (see README.md for source versions
  // and which readiness state each represents).
  writeArchive('url_launcher_ios.tar.gz', {
    'pubspec.yaml': sourceFile('url_launcher_ios', 'pubspec.yaml'),
    'ios/url_launcher_ios/Package.swift': sourceFile(
      'url_launcher_ios',
      'Package.swift',
    ),
  });
  writeArchive('url_launcher_android.tar.gz', {
    'pubspec.yaml': sourceFile('url_launcher_android', 'pubspec.yaml'),
    'android/build.gradle.kts': sourceFile(
      'url_launcher_android',
      'build.gradle.kts',
    ),
  });
  writeArchive('flutter_barcode_scanner.tar.gz', {
    'pubspec.yaml': sourceFile('flutter_barcode_scanner', 'pubspec.yaml'),
    'ios/flutter_barcode_scanner.podspec': sourceFile(
      'flutter_barcode_scanner',
      'flutter_barcode_scanner.podspec',
    ),
    'android/build.gradle': sourceFile(
      'flutter_barcode_scanner',
      'build.gradle',
    ),
  });

  // Synthetic: tagged is:swiftpm-plugin (see its score fixture) but the
  // archive ships only a legacy podspec — the disagreement class SPEC
  // §3.1.2 calls out (flutter/flutter#187330).
  writeArchive('fixture_swiftpm_disagree.tar.gz', {
    'pubspec.yaml': sourceFile('fixture_swiftpm_disagree', 'pubspec.yaml'),
    'ios/fixture_swiftpm_disagree.podspec': sourceFile(
      'fixture_swiftpm_disagree',
      'fixture_swiftpm_disagree.podspec',
    ),
  });

  // Synthetic: a real Gradle file (reused from url_launcher_android,
  // including its unresolved `flutter.compileSdkVersion` expression) plus
  // one aligned and one misaligned .so, so checkPackageAlignment has a
  // mixed-result archive to run against.
  writeArchiveBytes('fixture_alignment_plugin.tar.gz', {
    'pubspec.yaml': sourceFile(
      'fixture_alignment_plugin',
      'pubspec.yaml',
    ).codeUnits,
    'android/build.gradle.kts': sourceFile(
      'url_launcher_android',
      'build.gradle.kts',
    ).codeUnits,
    'android/src/main/jniLibs/arm64-v8a/libfixture_alignment_plugin.so':
        alignedSo,
    'android/src/main/jniLibs/armeabi-v7a/libfixture_alignment_plugin.so':
        misalignedSo,
  });

  stdout.writeln('Wrote fixtures to $_archivesDir and $_soDir');
}

String sourceFile(String package, String name) =>
    File('$_sourcesDir/$package/$name').readAsStringSync();

/// Builds a minimal synthetic 64-bit ELF (header + one `PT_LOAD` program
/// header per entry in [loadSegmentAlignments]) with the given `p_align`
/// values. No section headers, no code — only what [checkSoAlignment] reads.
/// Mirrors the builder in test/elf_alignment_check_test.dart.
Uint8List buildElf({required List<int> loadSegmentAlignments}) {
  const ehsize = 64;
  const phentsize = 56;
  final phnum = loadSegmentAlignments.length;
  const headerStart = ehsize;
  final totalSize = headerStart + phentsize * phnum;

  final bytes = Uint8List(totalSize);
  final data = ByteData.sublistView(bytes);

  bytes[0] = 0x7f;
  bytes[1] = 0x45; // 'E'
  bytes[2] = 0x4c; // 'L'
  bytes[3] = 0x46; // 'F'
  bytes[4] = 2; // EI_CLASS: ELFCLASS64
  bytes[5] = 1; // EI_DATA: little-endian

  data.setUint64(32, headerStart, Endian.little); // e_phoff
  data.setUint16(54, phentsize, Endian.little); // e_phentsize
  data.setUint16(56, phnum, Endian.little); // e_phnum

  for (var i = 0; i < phnum; i++) {
    final offset = headerStart + i * phentsize;
    data.setUint32(offset, 1, Endian.little); // p_type = PT_LOAD
    data.setUint64(offset + 48, loadSegmentAlignments[i], Endian.little);
  }

  return bytes;
}

/// Packs [entries] (path -> UTF-8 text content) into a gzip-then-tar
/// archive at `test/fixtures/archives/[name]`, the same shape as a pub.dev
/// package archive.
void writeArchive(String name, Map<String, String> entries) {
  writeArchiveBytes(
    name,
    entries.map((path, text) => MapEntry(path, text.codeUnits)),
  );
}

/// Packs [entries] (path -> raw byte content) into a gzip-then-tar archive.
///
/// Every entry's mod time is pinned to the epoch so re-running this script
/// reproduces byte-identical output — `ArchiveFile` otherwise defaults
/// `lastModTime` to `DateTime.now()`, which would make the committed
/// fixture change on every regeneration for no reason.
void writeArchiveBytes(String name, Map<String, List<int>> entries) {
  final archive = Archive();
  for (final entry in entries.entries) {
    final file = ArchiveFile(entry.key, entry.value.length, entry.value);
    file.lastModTime = 0;
    archive.addFile(file);
  }
  final tarBytes = TarEncoder().encodeBytes(archive);
  File('$_archivesDir/$name')
      .writeAsBytesSync(GZipEncoder().encodeBytes(tarBytes));
}
