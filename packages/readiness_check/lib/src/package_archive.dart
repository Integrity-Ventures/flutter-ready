import 'package:archive/archive.dart';

/// The entry paths inside a pub.dev package archive (a gzip-compressed tar),
/// without extracting any file contents.
List<String> listArchiveEntryPaths(List<int> archiveBytes) {
  final tarBytes = GZipDecoder().decodeBytes(archiveBytes);
  final archive = TarDecoder().decodeBytes(tarBytes);
  return archive.files.map((file) => file.name).toList();
}
