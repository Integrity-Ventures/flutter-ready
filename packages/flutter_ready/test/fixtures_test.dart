// Runs the readiness checks end-to-end against the recorded fixtures in
// test/fixtures/ (SPEC §5): one plugin per SwiftPM readiness state, a
// federated plugin set, and a package archive with both an aligned and a
// misaligned .so. No test in this file calls the network.
import 'package:flutter_ready/readiness_check.dart';
import 'package:test/test.dart';

import 'fixtures/fixture_loader.dart';

void main() {
  group('SwiftPM readiness from fixtures', () {
    test('federated plugin: url_launcher tag + url_launcher_ios archive agree it is ready', () {
      // Per the federation rule (architect notes, e2-s1): the tag comes
      // from the app-facing package (url_launcher); the archive comes
      // from the platform's default_package (url_launcher_ios).
      final candidate = PluginCandidate(
        name: 'url_launcher_ios',
        tags: fixtureTags('url_launcher'),
      );
      final archivePaths = listArchiveEntryPaths(
        fixtureBytes('archives/url_launcher_ios.tar.gz'),
      );

      final result = checkSwiftPmReadiness(candidate, archivePaths);

      expect(result.tagSaysReady, isTrue);
      expect(result.archiveSaysReady, isTrue);
      expect(result.agrees, isTrue);
    });

    test('flutter_barcode_scanner: tag and archive agree it is not ready', () {
      final candidate = PluginCandidate(
        name: 'flutter_barcode_scanner',
        tags: fixtureTags('flutter_barcode_scanner'),
      );
      final archivePaths = listArchiveEntryPaths(
        fixtureBytes('archives/flutter_barcode_scanner.tar.gz'),
      );

      final result = checkSwiftPmReadiness(candidate, archivePaths);

      expect(result.tagSaysReady, isFalse);
      expect(result.archiveSaysReady, isFalse);
      expect(result.agrees, isTrue);
    });

    test('fixture_swiftpm_disagree: tag says ready but the archive has no Package.swift', () {
      final candidate = PluginCandidate(
        name: 'fixture_swiftpm_disagree',
        tags: fixtureTags('fixture_swiftpm_disagree'),
      );
      final archivePaths = listArchiveEntryPaths(
        fixtureBytes('archives/fixture_swiftpm_disagree.tar.gz'),
      );

      final result = checkSwiftPmReadiness(candidate, archivePaths);

      expect(result.tagSaysReady, isTrue);
      expect(result.archiveSaysReady, isFalse);
      expect(result.agrees, isFalse);
    });
  });

  group('16 KB alignment from fixtures', () {
    test('url_launcher_android archive ships no .so files at all', () {
      final soEntries = extractArchiveEntries(
        fixtureBytes('archives/url_launcher_android.tar.gz'),
        isSharedLibraryPath,
      );

      expect(soEntries, isEmpty);
    });

    test(
      'fixture_alignment_plugin archive has one aligned and one misaligned .so',
      () {
        final soEntries = extractArchiveEntries(
          fixtureBytes('archives/fixture_alignment_plugin.tar.gz'),
          isSharedLibraryPath,
        );

        final results = checkPackageAlignment(soEntries);

        expect(results, hasLength(2));
        expect(
          results.firstWhere((r) => r.path.contains('arm64-v8a')).aligned,
          isTrue,
        );
        expect(
          results.firstWhere((r) => r.path.contains('armeabi-v7a')).aligned,
          isFalse,
        );
      },
    );

    test('the standalone .so fixtures match their filenames', () {
      final aligned = checkSoAlignment(
        'aligned_arm64-v8a.so',
        fixtureBytes('so_files/aligned_arm64-v8a.so'),
      );
      final misaligned = checkSoAlignment(
        'misaligned_arm64-v8a.so',
        fixtureBytes('so_files/misaligned_arm64-v8a.so'),
      );

      expect(aligned.aligned, isTrue);
      expect(misaligned.aligned, isFalse);
    });
  });

  group('Android build settings from fixtures', () {
    test('url_launcher_android: Kotlin DSL with an unresolved compileSdk', () {
      final gradleFiles = extractArchiveEntries(
        fixtureBytes('archives/url_launcher_android.tar.gz'),
        isAndroidGradleFilePath,
      );

      final settings = extractAndroidBuildSettings(gradleFiles);

      expect(settings, isNotNull);
      expect(settings!.compileSdk, 'flutter.compileSdkVersion');
      expect(settings.agpVersion, '8.13.1');
    });

    test(
      'flutter_barcode_scanner: Groovy build.gradle with a resolved compileSdk',
      () {
        final gradleFiles = extractArchiveEntries(
          fixtureBytes('archives/flutter_barcode_scanner.tar.gz'),
          isAndroidGradleFilePath,
        );

        final settings = extractAndroidBuildSettings(gradleFiles);

        expect(settings, isNotNull);
        expect(settings!.compileSdk, '30');
        expect(settings.agpVersion, '4.1.3');
      },
    );
  });

  group('recorded pub.dev responses', () {
    test('url_launcher_ios info.json carries the federated version', () {
      final info = fixtureJson('pub_dev/url_launcher_ios_info.json');

      expect(info['latest']['version'], '6.4.2');
      expect(info['latest']['pubspec']['implements'], isNull);
      expect(
        info['latest']['pubspec']['flutter']['plugin']['implements'],
        'url_launcher',
      );
    });
  });
}
