import 'package:archive/archive.dart';

Archive _decodePackageArchive(List<int> archiveBytes) {
  final tarBytes = GZipDecoder().decodeBytes(archiveBytes);
  return TarDecoder().decodeBytes(tarBytes);
}

/// The entry paths inside a pub.dev package archive (a gzip-compressed tar),
/// without extracting any file contents.
List<String> listArchiveEntryPaths(List<int> archiveBytes) {
  return _decodePackageArchive(archiveBytes).files
      .map((file) => file.name)
      .toList();
}

/// The contents of every entry inside a pub.dev package archive whose path
/// satisfies [predicate], keyed by entry path.
Map<String, List<int>> extractArchiveEntries(
  List<int> archiveBytes,
  bool Function(String path) predicate,
) {
  final archive = _decodePackageArchive(archiveBytes);
  return {
    for (final file in archive.files)
      if (predicate(file.name)) file.name: file.content as List<int>,
  };
}
