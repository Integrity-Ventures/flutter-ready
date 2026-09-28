import 'pub_dev_client.dart';

/// Platform keys checked, in priority order, when resolving which package
/// carries a plugin's iOS implementation (SPEC e2-s1 rework). A plugin that
/// declares an `ios` entry — in any form — is never resolved via `macos`.
const _iosPlatformPriority = ['ios', 'macos', 'darwin'];

/// Directories a `.podspec` can live in for a plugin's iOS/macOS
/// implementation.
const _podspecDirs = ['ios', 'macos', 'darwin'];

/// Which package — and which platform key on it — carries a plugin's iOS
/// implementation.
class IosResolution {
  const IosResolution({required this.checkedPackage, required this.platform});

  /// The package whose archive carries the SwiftPM/CocoaPods evidence: a
  /// federated `default_package`, or the plugin's own name.
  final String checkedPackage;

  /// Which of the app-facing package's platform entries this came from
  /// (`ios`, `macos` or `darwin`) — used to read the *resolved* package's
  /// own declaration for that same platform in [declaresNativeIos].
  final String platform;
}

/// Resolves which package's archive should be checked for a plugin's iOS
/// readiness (SPEC e2-s1 rework). Federated plugins declare their real
/// per-platform implementation via `default_package`; some declare it
/// inline via `pluginClass`/`ffiPlugin`. iOS is preferred over macOS/darwin,
/// and falling back to macOS only happens when the app-facing pubspec has
/// no `ios` entry at all.
IosResolution resolveIosPackage(String pluginName, PackageInfo? appInfo) {
  for (final platform in _iosPlatformPriority) {
    final entry = appInfo?.platformInfo(platform);
    if (entry != null) {
      return IosResolution(
        checkedPackage: entry.defaultPackage ?? pluginName,
        platform: platform,
      );
    }
  }
  return IosResolution(checkedPackage: pluginName, platform: 'ios');
}

/// Whether the resolved package ([resolution]) ships native iOS code at all
/// (SPEC e2-s1 rework): true when it declares `pluginClass` or
/// `ffiPlugin: true` for [IosResolution.platform] itself, or its archive has
/// a `.podspec` under `ios/`, `macos/` or `darwin/`. False when it's
/// Dart-only (`dartPluginClass`) with no podspec — nothing to migrate off
/// CocoaPods, so the CocoaPods deadline can't block it.
bool declaresNativeIos(
  IosResolution resolution,
  PackageInfo? resolvedInfo,
  List<String> archiveEntryPaths,
) {
  final platformInfo = resolvedInfo?.platformInfo(resolution.platform);
  if (platformInfo?.declaresNativeImplementation ?? false) return true;
  return _podspecDirs.any(
    (dir) =>
        archiveEntryPaths.contains('$dir/${resolution.checkedPackage}.podspec'),
  );
}

/// Whether a plugin has native iOS code that could be blocked by the
/// CocoaPods deadline, and why not when it doesn't (SPEC e2-s1 rework 2).
class NativeIosResult {
  const NativeIosResult({required this.nativeIos, required this.reason});

  final bool nativeIos;

  /// Set only when [nativeIos] is false.
  final String? reason;
}

/// Combines the "not an iOS plugin at all" and "declares iOS but it's
/// Dart-only" cases (SPEC e2-s1 rework 2). When the app-facing pubspec
/// ([appInfo]) declares neither an `ios` nor a `macos` platform, Flutter
/// never registers pods for this plugin on an iOS app, so a leftover
/// `ios/<name>.podspec` in its own archive (a `flutter create
/// --template=plugin` artifact) doesn't apply — [declaresNativeIos] isn't
/// even consulted in that case.
NativeIosResult resolveNativeIos(
  PackageInfo? appInfo,
  IosResolution resolution,
  PackageInfo? resolvedInfo,
  List<String> archiveEntryPaths,
) {
  if (appInfo?.platformInfo('ios') == null &&
      appInfo?.platformInfo('macos') == null) {
    return const NativeIosResult(nativeIos: false, reason: 'not-ios-plugin');
  }
  final native = declaresNativeIos(resolution, resolvedInfo, archiveEntryPaths);
  return NativeIosResult(
    nativeIos: native,
    reason: native ? null : 'no-native-ios-code',
  );
}
