// Runs the packaged flutter_ready binary as a subprocess (CLI live-check
// task, 2026-09-27) to prove --offline never attempts a live check: with a
// local data source and no network reachable from this assertion at all
// (offline short-circuits straight to the old "not checked" message,
// per check_command.dart), an unmatched plugin must never read
// "not checked: <live failure>" — only a live check that ran would produce
// that text.
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    '--offline reports an unmatched plugin as "not in Flutter Ready\'s data", never attempting a live check',
    () async {
      final tempDir = Directory.systemTemp.createTempSync('flutter_ready_offline_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final dataDir = Directory(p.join(tempDir.path, 'data'))..createSync();
      File(p.join(dataDir.path, 'latest.json')).writeAsStringSync(
        jsonEncode({
          'schemaVersion': 1,
          'generatedAt': '2026-09-27T00:00:00Z',
          'discovery': {'method': 'pubdev-search', 'queries': <String>[], 'resultsPerQuery': 100},
          'plugins': <Object>[],
        }),
      );
      File(p.join(dataDir.path, 'deadlines.json')).writeAsStringSync(jsonEncode({'deadlines': <Object>[]}));

      final lockfile = File(p.join(tempDir.path, 'pubspec.lock'))
        ..writeAsStringSync('''
packages:
  some_unknown_plugin:
    dependency: "direct main"
    description:
      name: some_unknown_plugin
      sha256: "0000000000000000000000000000000000000000000000000000000000000"
      url: "https://pub.dev"
    source: hosted
    version: "1.0.0"
sdks:
  dart: ">=3.13.0 <4.0.0"
''');

      final result = await Process.run(Platform.resolvedExecutable, [
        'run',
        'bin/flutter_ready.dart',
        'check',
        '--data',
        p.join(dataDir.path, 'latest.json'),
        '--lockfile',
        lockfile.path,
        '--offline',
      ]);

      expect(result.exitCode, 0, reason: 'stdout: ${result.stdout}\nstderr: ${result.stderr}');
      expect(result.stdout, contains("not in Flutter Ready's data"));
      expect(result.stdout, isNot(contains('checked live')));
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
