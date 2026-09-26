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
  });
}
