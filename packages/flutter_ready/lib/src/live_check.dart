import 'package:flutter_ready/readiness_check.dart';

import 'pubspec_lock.dart';

/// One hosted package's outcome from checking it live (CLI live-check task,
/// 2026-09-27): a package the Flutter Ready data doesn't cover at its
/// locked version, checked on the spot against pub.dev.
class LiveCheckResult {
  const LiveCheckResult._({
    required this.name,
    required this.version,
    required this.isPlugin,
    this.grade,
    this.checkedPackage,
    this.usedFallbackLatest = false,
    this.notCheckedReason,
  });

  /// Not a Flutter plugin (no `flutter.plugin` in its pubspec) — skipped
  /// silently, since a pure Dart package can't block a native build.
  factory LiveCheckResult.skipped(String name, String version) =>
      LiveCheckResult._(name: name, version: version, isPlugin: false);

  factory LiveCheckResult.checked(
    String name,
    String version, {
    required LiveGrade grade,
    required String checkedPackage,
    required bool usedFallbackLatest,
  }) => LiveCheckResult._(
    name: name,
    version: version,
    isPlugin: true,
    grade: grade,
    checkedPackage: checkedPackage,
    usedFallbackLatest: usedFallbackLatest,
  );

  /// A network failure, a 404, or a corrupt archive — never green, and never
  /// aborts the run of the other packages.
  factory LiveCheckResult.notChecked(String name, String version, String reason) =>
      LiveCheckResult._(name: name, version: version, isPlugin: true, notCheckedReason: reason);

  final String name;
  final String version;
  final bool isPlugin;

  /// Set only when the archive was successfully graded.
  final LiveGrade? grade;

  /// The package whose archive [grade] came from — its own, for an
  /// unfederated plugin, or the resolved `ios`/`macos` `default_package`.
  final String? checkedPackage;

  /// Whether [checkedPackage] wasn't locked in the app's pubspec.lock, so
  /// its latest published version was checked instead of the exact version
  /// the app resolved.
  final bool usedFallbackLatest;

  /// Set only when the check failed; never combined with [grade].
  final String? notCheckedReason;
}

/// Checks every package in [toCheck] live, at its exact locked
/// [LockedPackage.version] (CLI live-check task, 2026-09-27): the on-the-spot
/// equivalent of the nightly snapshot, for a plugin the Flutter Ready data
/// doesn't cover. Runs at most [concurrency] at a time; a single package's
/// failure never aborts the batch. [onProgress], if given, is called once
/// per completed package.
Future<List<LiveCheckResult>> runLiveChecks(
  PubDevClient client,
  List<LockedPackage> toCheck,
  Map<String, LockedPackage> lockedByName, {
  int concurrency = 4,
  void Function(String message)? onProgress,
}) {
  var done = 0;
  return mapWithConcurrency(toCheck, concurrency, (locked) async {
    final result = await _checkOne(client, locked, lockedByName);
    done++;
    onProgress?.call('flutter_ready: checked ${locked.name} live ($done/${toCheck.length})');
    return result;
  });
}

Future<LiveCheckResult> _checkOne(
  PubDevClient client,
  LockedPackage locked,
  Map<String, LockedPackage> lockedByName,
) async {
  try {
    final appVersion = await client.fetchPackageVersion(locked.name, locked.version);
    if (!appVersion.info.isFlutterPlugin) {
      return LiveCheckResult.skipped(locked.name, locked.version);
    }

    final resolution = resolveIosPackage(locked.name, appVersion.info);
    final federated = resolution.checkedPackage != locked.name;

    PackageVersion resolvedVersion;
    var usedFallbackLatest = false;
    if (!federated) {
      resolvedVersion = appVersion;
    } else {
      final lockedResolved = lockedByName[resolution.checkedPackage];
      if (lockedResolved != null) {
        resolvedVersion = await client.fetchPackageVersion(
          resolution.checkedPackage,
          lockedResolved.version,
        );
      } else {
        usedFallbackLatest = true;
        resolvedVersion = await client.fetchLatestPackageVersion(resolution.checkedPackage);
      }
    }

    final archiveBytes = await client.fetchArchiveBytes(resolvedVersion.archiveUrl);
    final grade = gradeLivePlugin(
      appInfo: appVersion.info,
      resolution: resolution,
      resolvedInfo: resolvedVersion.info,
      archiveBytes: archiveBytes,
    );

    return LiveCheckResult.checked(
      locked.name,
      locked.version,
      grade: grade,
      checkedPackage: resolution.checkedPackage,
      usedFallbackLatest: usedFallbackLatest,
    );
  } catch (error) {
    return LiveCheckResult.notChecked(locked.name, locked.version, '$error');
  }
}
