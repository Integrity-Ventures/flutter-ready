import 'dart:typed_data';

import 'package:archive/archive.dart';

Archive _decodePackageArchive(List<int> archiveBytes) {
  final tarBytes = _decodeGZipMember(archiveBytes);
  return TarDecoder().decodeBytes(tarBytes);
}

/// Decodes the first gzip member in [archiveBytes], tolerating trailing
/// zero-byte padding after it (pub.dev serves some archives padded with
/// zeros up to a tar record boundary, which dart:io's ZLibDecoder otherwise
/// rejects with "Filter error, bad data"). Trailing bytes that are not all
/// zero, or a member that never completes, still throw.
Uint8List _decodeGZipMember(List<int> archiveBytes) {
  final bytes = Uint8List.fromList(archiveBytes);

  Uint8List? tryDecodePrefix(int length) {
    final input = InputMemoryStream(bytes.sublist(0, length));
    final output = OutputMemoryStream();
    final complete = GZipDecoder().decodeStream(input, output);
    return complete ? output.getBytes() : null;
  }

  try {
    final wholeInput = tryDecodePrefix(bytes.length);
    if (wholeInput != null) return wholeInput;
  } on FormatException {
    // Extra trailing bytes after a complete member: find where the member
    // actually ends below, via a search over prefix lengths.
  }

  // decodeStream's readiness at prefix length L is a simple three-zone
  // function of L: incomplete (returns null) while L is short of the
  // member's true end, complete (returns bytes) right at that end, and
  // erroring (throws) once L runs into bytes past it that don't parse as a
  // continuation. That shape is exactly what binary search needs to land
  // inside the (possibly one-byte-wide) complete zone in O(log n) tries.
  var low = 0, high = bytes.length;
  Uint8List? decoded;
  var decodedAt = -1;
  while (low <= high) {
    final mid = low + (high - low) ~/ 2;
    try {
      final result = tryDecodePrefix(mid);
      if (result != null) {
        decoded = result;
        decodedAt = mid;
        break;
      }
      low = mid + 1;
    } on FormatException {
      high = mid - 1;
    }
  }

  if (decoded == null) {
    throw const FormatException('Truncated gzip archive');
  }
  if (bytes.skip(decodedAt).any((b) => b != 0)) {
    throw const FormatException('Filter error, bad data');
  }
  return decoded;
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
