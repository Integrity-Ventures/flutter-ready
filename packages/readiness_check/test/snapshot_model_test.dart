import 'package:readiness_check/readiness_check.dart';
import 'package:test/test.dart';

void main() {
  group('PluginEntry.fromJson', () {
    test(
      'parses swiftpm/alignment/android as an all-null sentinel, rather than '
      'crashing, for a plugin whose checks failed (SPEC §3.1.2-3: those '
      'fields are null, never omitted, when a per-plugin failure is '
      'recorded in errors)',
      () {
        final entry = PluginEntry.fromJson({
          'name': 'broken_plugin',
          'version': '1.0.0',
          'published': null,
          'downloadCount30Days': null,
          'likeCount': null,
          'swiftpm': null,
          'alignment': null,
          'android': null,
          'errors': ['package info: some fetch failure'],
        });

        expect(entry.swiftpm.tag, isNull);
        expect(entry.swiftpm.archive, isNull);
        expect(entry.alignment.soFiles, isEmpty);
        expect(entry.android.compileSdk, isNull);
        expect(entry.errors, isNotEmpty);
        expect(entry.search, isEmpty);
      },
    );

    test('falls back to a placeholder version when it is null', () {
      final entry = PluginEntry.fromJson({
        'name': 'broken_plugin',
        'version': null,
        'published': null,
        'downloadCount30Days': null,
        'likeCount': null,
        'swiftpm': null,
        'alignment': null,
        'android': null,
        'errors': ['package info: some fetch failure'],
      });

      expect(entry.version, 'unknown');
    });

    test('parses a fully populated plugin', () {
      final entry = PluginEntry.fromJson({
        'name': 'url_launcher',
        'version': '6.3.2',
        'published': '2026-01-01T00:00:00Z',
        'downloadCount30Days': 1000,
        'likeCount': 10,
        'swiftpm': {
          'tag': true,
          'archive': true,
          'agrees': true,
          'checkedPackage': 'url_launcher_ios',
        },
        'alignment': {'checkedPackage': 'url_launcher_android', 'soFiles': []},
        'android': {
          'checkedPackage': 'url_launcher_android',
          'compileSdk': '35',
          'agp': null,
          'ndk': null,
        },
        'errors': [],
        'search': ['top-downloads'],
      });

      expect(entry.swiftpm.tag, isTrue);
      expect(entry.android.compileSdk, '35');
      expect(entry.search, ['top-downloads']);
    });
  });
}
