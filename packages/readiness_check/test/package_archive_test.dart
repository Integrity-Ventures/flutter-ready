import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:readiness_check/readiness_check.dart';
import 'package:test/test.dart';

List<int> _buildPackageArchiveBytes(List<String> entryPaths) {
  final archive = Archive();
  for (final path in entryPaths) {
    final data = utf8.encode('contents of $path');
    archive.addFile(ArchiveFile(path, data.length, data));
  }
  final tarBytes = TarEncoder().encodeBytes(archive);
  return GZipEncoder().encodeBytes(tarBytes);
}

void main() {
  group('listArchiveEntryPaths', () {
    test('lists every entry path in a gzip-then-tar package archive', () {
      final bytes = _buildPackageArchiveBytes([
        'pubspec.yaml',
        'lib/some_plugin.dart',
        'ios/some_plugin/Package.swift',
      ]);

      final paths = listArchiveEntryPaths(bytes);

      expect(
        paths,
        containsAll([
          'pubspec.yaml',
          'lib/some_plugin.dart',
          'ios/some_plugin/Package.swift',
        ]),
      );
    });

    test('returns an empty list for an archive with no entries', () {
      final bytes = _buildPackageArchiveBytes([]);

      expect(listArchiveEntryPaths(bytes), isEmpty);
    });

    test(
      'throws (rather than hangs or returns garbage) on a corrupt archive, '
      'so callers can catch and record it per plugin',
      () {
        final corruptBytes = [0x1f, 0x8b, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

        expect(() => listArchiveEntryPaths(corruptBytes), throwsA(anything));
      },
    );
  });

  group('extractArchiveEntries', () {
    test('returns content only for entries matching the predicate', () {
      final bytes = _buildPackageArchiveBytes([
        'pubspec.yaml',
        'android/src/main/jniLibs/arm64-v8a/libsome_plugin.so',
        'ios/some_plugin/Package.swift',
      ]);

      final entries = extractArchiveEntries(
        bytes,
        (path) => path.endsWith('.so'),
      );

      expect(entries.keys, [
        'android/src/main/jniLibs/arm64-v8a/libsome_plugin.so',
      ]);
      expect(
        utf8.decode(
          entries['android/src/main/jniLibs/arm64-v8a/libsome_plugin.so']!,
        ),
        'contents of android/src/main/jniLibs/arm64-v8a/libsome_plugin.so',
      );
    });

    test('returns an empty map when nothing matches', () {
      final bytes = _buildPackageArchiveBytes(['pubspec.yaml']);

      expect(
        extractArchiveEntries(bytes, (path) => path.endsWith('.so')),
        isEmpty,
      );
    });

    test('throws on a corrupt archive', () {
      final corruptBytes = [0x1f, 0x8b, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

      expect(
        () => extractArchiveEntries(corruptBytes, (path) => true),
        throwsA(anything),
      );
    });
  });
}
