import 'package:readiness_check/readiness_check.dart';
import 'package:test/test.dart';

void main() {
  group('checkSwiftPmReadiness', () {
    test('tag and archive agree: both say ready', () {
      final candidate = PluginCandidate(
        name: 'url_launcher_ios',
        tags: ['sdk:flutter', 'platform:ios', 'is:swiftpm-plugin'],
      );

      final result = checkSwiftPmReadiness(candidate, [
        'ios/url_launcher_ios/Package.swift',
        'ios/url_launcher_ios/Classes/UrlLauncherPlugin.m',
      ]);

      expect(result.tagSaysReady, isTrue);
      expect(result.archiveSaysReady, isTrue);
      expect(result.agrees, isTrue);
    });

    test('tag and archive agree: neither says ready', () {
      final candidate = PluginCandidate(
        name: 'flutter_map',
        tags: ['sdk:flutter', 'platform:android'],
      );

      final result = checkSwiftPmReadiness(candidate, ['lib/flutter_map.dart']);

      expect(result.tagSaysReady, isFalse);
      expect(result.archiveSaysReady, isFalse);
      expect(result.agrees, isTrue);
    });

    test(
      'disagreement: tag says ready but no Package.swift in the archive',
      () {
        final candidate = PluginCandidate(
          name: 'some_plugin',
          tags: ['sdk:flutter', 'platform:ios', 'is:swiftpm-plugin'],
        );

        final result = checkSwiftPmReadiness(candidate, [
          'ios/some_plugin/some_plugin.podspec',
        ]);

        expect(result.tagSaysReady, isTrue);
        expect(result.archiveSaysReady, isFalse);
        expect(result.agrees, isFalse);
      },
    );

    test('disagreement: archive has Package.swift but the tag is absent', () {
      final candidate = PluginCandidate(
        name: 'some_plugin',
        tags: ['sdk:flutter', 'platform:macos'],
      );

      final result = checkSwiftPmReadiness(candidate, [
        'macos/some_plugin/Package.swift',
      ]);

      expect(result.tagSaysReady, isFalse);
      expect(result.archiveSaysReady, isTrue);
      expect(result.agrees, isFalse);
    });

    test('matches a darwin/ Package.swift as well as ios/ and macos/', () {
      final candidate = PluginCandidate(
        name: 'some_plugin',
        tags: ['sdk:flutter', 'platform:ios', 'is:swiftpm-plugin'],
      );

      final result = checkSwiftPmReadiness(candidate, [
        'darwin/some_plugin/Package.swift',
      ]);

      expect(result.archiveSaysReady, isTrue);
      expect(result.agrees, isTrue);
    });

    test('does not match another plugin\'s Package.swift', () {
      final candidate = PluginCandidate(
        name: 'some_plugin',
        tags: ['sdk:flutter', 'platform:ios'],
      );

      final result = checkSwiftPmReadiness(candidate, [
        'ios/some_other_plugin/Package.swift',
      ]);

      expect(result.archiveSaysReady, isFalse);
    });
  });
}
