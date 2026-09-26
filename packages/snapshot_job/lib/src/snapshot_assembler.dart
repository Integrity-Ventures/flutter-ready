import 'package:readiness_check/readiness_check.dart';

import 'concurrency_pool.dart';
import 'plugin_snapshot.dart';

/// Assembles one [PluginSnapshot] per candidate (SPEC §3.1.2-3), running up
/// to [concurrency] plugins at a time. A single plugin's failure never
/// aborts the run — it's recorded in that plugin's `errors` list instead.
Future<List<PluginSnapshot>> assembleSnapshot(
  PubDevClient client,
  List<PluginCandidate> candidates, {
  int concurrency = 4,
}) {
  return mapWithConcurrency(
    candidates,
    concurrency,
    (candidate) => _assembleOne(client, candidate),
  );
}

Future<PluginSnapshot> _assembleOne(
  PubDevClient client,
  PluginCandidate candidate,
) async {
  final errors = <String>[];
  final score = await _safeCall(
    errors,
    'score',
    () => client.fetchPackageScore(candidate.name),
  );
  final info = await _safeCall(
    errors,
    'package info',
    () => client.fetchPackageInfo(candidate.name),
  );

  // Federated plugins (e1-s2 review finding): the app-facing package's own
  // archive carries no Package.swift/.so/Gradle file. When a platform
  // declares a default_package, the platform's real archive lives there.
  final iosPackage =
      info?.defaultPackageFor('ios') ??
      info?.defaultPackageFor('macos') ??
      candidate.name;
  final androidPackage = info?.defaultPackageFor('android') ?? candidate.name;

  // Shared so a non-federated plugin (iosPackage == androidPackage) only
  // has its archive fetched once.
  final archiveCache = <String, Future<List<int>?>>{};
  Future<List<int>?> archiveFor(String packageName) {
    return archiveCache.putIfAbsent(
      packageName,
      () => _safeCall(errors, '$packageName archive', () async {
        final archiveUri = await client.fetchLatestArchiveUrl(packageName);
        return client.fetchArchiveBytes(archiveUri);
      }),
    );
  }

  final swiftpm = await _assembleSwiftPm(candidate, iosPackage, archiveFor);
  final (:alignment, :android) = await _assembleAndroid(
    androidPackage,
    archiveFor,
    errors,
  );

  return PluginSnapshot(
    name: candidate.name,
    version: info?.version,
    published: info?.published,
    downloadCount30Days: score?.downloadCount30Days,
    likeCount: score?.likeCount,
    swiftpm: swiftpm,
    alignment: alignment,
    android: android,
    errors: errors,
  );
}

Future<SwiftPmSnapshot?> _assembleSwiftPm(
  PluginCandidate candidate,
  String checkedPackage,
  Future<List<int>?> Function(String packageName) archiveFor,
) async {
  final bytes = await archiveFor(checkedPackage);
  if (bytes == null) return null;
  final entryPaths = listArchiveEntryPaths(bytes);
  // The is:swiftpm-plugin tag stays the app-facing package's own tag
  // (architect decision) — only the archive lookup moves to checkedPackage.
  final readiness = checkSwiftPmReadiness(
    PluginCandidate(name: checkedPackage, tags: candidate.tags),
    entryPaths,
  );
  return SwiftPmSnapshot(checkedPackage: checkedPackage, readiness: readiness);
}

Future<({AlignmentSnapshot? alignment, AndroidSnapshot? android})>
_assembleAndroid(
  String checkedPackage,
  Future<List<int>?> Function(String packageName) archiveFor,
  List<String> errors,
) async {
  final bytes = await archiveFor(checkedPackage);
  if (bytes == null) return (alignment: null, android: null);

  final entries = extractArchiveEntries(
    bytes,
    (path) => isSharedLibraryPath(path) || isAndroidGradleFilePath(path),
  );

  final soFiles = <ElfAlignmentResult>[];
  final gradleFiles = <String, List<int>>{};
  for (final entry in entries.entries) {
    if (isSharedLibraryPath(entry.key)) {
      try {
        soFiles.add(checkSoAlignment(entry.key, entry.value));
      } on NotElfException catch (error) {
        errors.add('$checkedPackage: $error');
      }
    } else {
      gradleFiles[entry.key] = entry.value;
    }
  }

  return (
    alignment: AlignmentSnapshot(
      checkedPackage: checkedPackage,
      soFiles: soFiles,
    ),
    android: AndroidSnapshot(
      checkedPackage: checkedPackage,
      settings: extractAndroidBuildSettings(gradleFiles),
    ),
  );
}

Future<T?> _safeCall<T>(
  List<String> errors,
  String what,
  Future<T> Function() call,
) async {
  try {
    return await call();
  } catch (error) {
    errors.add('$what: $error');
    return null;
  }
}
