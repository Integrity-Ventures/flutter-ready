// Tests gradeLivePlugin (CLI live-check task, 2026-09-27) against the e6-s1
// archive fixtures directly — it's a pure function over already-downloaded
// bytes, so no network or PubDevClient is needed here.
import 'package:readiness_check/readiness_check.dart';
import 'package:test/test.dart';

import 'fixtures/fixture_loader.dart';

final _published = DateTime.utc(2026, 1, 1);

final _barcodeScannerInfo = PackageInfo(
  version: '2.0.0',
  published: _published,
  isFlutterPlugin: true,
  platforms: const {
    'android': PluginPlatformInfo(pluginClass: 'FlutterBarcodeScannerPlugin'),
    'ios': PluginPlatformInfo(pluginClass: 'SwiftFlutterBarcodeScannerPlugin'),
  },
);

final _urlLauncherIosInfo = PackageInfo(
  version: '6.4.2',
  published: _published,
  isFlutterPlugin: true,
  platforms: const {'ios': PluginPlatformInfo(pluginClass: 'URLLauncherPlugin')},
);

final _urlLauncherAppInfo = PackageInfo(
  version: '6.3.2',
  published: _published,
  isFlutterPlugin: true,
  platforms: const {
    'ios': PluginPlatformInfo(defaultPackage: 'url_launcher_ios'),
    'android': PluginPlatformInfo(defaultPackage: 'url_launcher_android'),
  },
);

final _androidOnlyInfo = PackageInfo(
  version: '1.0.0',
  published: _published,
  isFlutterPlugin: true,
  platforms: const {'android': PluginPlatformInfo(pluginClass: 'SomeAndroidPlugin')},
);

void main() {
  test('unfederated plugin with no Package.swift grades a SwiftPM blocker', () {
    final resolution = resolveIosPackage('flutter_barcode_scanner', _barcodeScannerInfo);

    final grade = gradeLivePlugin(
      appInfo: _barcodeScannerInfo,
      resolution: resolution,
      resolvedInfo: _barcodeScannerInfo,
      archiveBytes: fixtureBytes('archives/flutter_barcode_scanner.tar.gz'),
    );

    expect(grade.swiftPm, Status.red);
    expect(grade.swiftPmEvidence, contains('No Package.swift'));
    expect(grade.alignment, Status.green);
  });

  test('unfederated plugin with Package.swift grades ready', () {
    final resolution = resolveIosPackage('url_launcher_ios', _urlLauncherIosInfo);

    final grade = gradeLivePlugin(
      appInfo: _urlLauncherIosInfo,
      resolution: resolution,
      resolvedInfo: _urlLauncherIosInfo,
      archiveBytes: fixtureBytes('archives/url_launcher_ios.tar.gz'),
    );

    expect(grade.swiftPm, Status.green);
    expect(grade.swiftPmEvidence, contains('Package.swift found'));
  });

  test('a federated plugin is graded from its default_package archive', () {
    final resolution = resolveIosPackage('url_launcher', _urlLauncherAppInfo);
    expect(resolution.checkedPackage, 'url_launcher_ios');

    final grade = gradeLivePlugin(
      appInfo: _urlLauncherAppInfo,
      resolution: resolution,
      resolvedInfo: _urlLauncherIosInfo,
      archiveBytes: fixtureBytes('archives/url_launcher_ios.tar.gz'),
    );

    expect(grade.swiftPm, Status.green);
    expect(grade.swiftPmEvidence, contains('url_launcher_ios archive'));
  });

  test('a plugin with no ios/macos platform at all is not affected', () {
    final resolution = resolveIosPackage('android_only_plugin', _androidOnlyInfo);

    final grade = gradeLivePlugin(
      appInfo: _androidOnlyInfo,
      resolution: resolution,
      resolvedInfo: _androidOnlyInfo,
      archiveBytes: fixtureBytes('archives/url_launcher_android.tar.gz'),
    );

    expect(grade.swiftPm, Status.green);
    expect(grade.swiftPmEvidence, 'Not affected: not an iOS plugin.');
  });

  test('a misaligned .so grades an alignment blocker, independent of SwiftPM', () {
    const resolution = IosResolution(checkedPackage: 'fixture_alignment_plugin', platform: 'ios');

    final grade = gradeLivePlugin(
      appInfo: null,
      resolution: resolution,
      resolvedInfo: null,
      archiveBytes: fixtureBytes('archives/fixture_alignment_plugin.tar.gz'),
    );

    expect(grade.alignment, Status.red);
    expect(grade.alignmentEvidence, contains('1 of 2'));
  });
}
