import 'package:flutter_ready/flutter_ready.dart';
import 'package:readiness_check/readiness_check.dart';
import 'package:test/test.dart';

PluginEntry _plugin(
  String name,
  String version, {
  bool? swiftpmTag,
  bool? swiftpmArchive,
  List<SoFile> soFiles = const [],
}) {
  return PluginEntry(
    name: name,
    version: version,
    published: null,
    downloadCount30Days: null,
    likeCount: null,
    swiftpm: SwiftPmInfo(
      tag: swiftpmTag,
      archive: swiftpmArchive,
      agrees: swiftpmTag == swiftpmArchive,
      checkedPackage: name,
    ),
    alignment: AlignmentInfo(checkedPackage: name, soFiles: soFiles),
    android: const AndroidInfo(checkedPackage: null, compileSdk: null, agp: null, ndk: null),
    errors: const [],
  );
}

const _deadlines = [
  Deadline(
    id: 'cocoapods-readonly',
    title: 'CocoaPods registry goes read-only',
    date: '2026-12-02',
    extendedDate: null,
    source: 'Flutter blog',
    check: 'swiftpm',
  ),
  Deadline(
    id: 'play-16kb-alignment',
    title: 'Native .so libraries must be 16 KB page-aligned',
    date: null,
    extendedDate: null,
    source: 'Play requirement',
    check: 'alignment',
  ),
  Deadline(
    id: 'play-target-api-36',
    title: 'Google Play requires apps to target API 36',
    date: '2026-08-31',
    extendedDate: null,
    source: 'Play Console help',
    check: 'android',
  ),
];

void main() {
  test('a plugin at the checked version with a red SwiftPM status is a blocker', () {
    final snapshot = Snapshot(
      schemaVersion: 1,
      generatedAt: '2026-09-26T00:00:00Z',
      topN: 1,
      plugins: [_plugin('no_spm_plugin', '1.0.0', swiftpmTag: false, swiftpmArchive: false)],
    );
    final locked = [const LockedPackage(name: 'no_spm_plugin', version: '1.0.0', isHosted: true)];

    final report = buildCheckReport(lockedPackages: locked, snapshot: snapshot, deadlines: _deadlines);

    expect(report.hasBlocker, isTrue);
    expect(report.text, contains('CocoaPods registry goes read-only'));
    expect(report.text, contains('BLOCKER: no_spm_plugin 1.0.0'));
  });

  test('a misaligned .so is a blocker under the alignment deadline', () {
    final snapshot = Snapshot(
      schemaVersion: 1,
      generatedAt: '2026-09-26T00:00:00Z',
      topN: 1,
      plugins: [
        _plugin(
          'unaligned_plugin',
          '2.0.0',
          swiftpmTag: true,
          swiftpmArchive: true,
          soFiles: const [SoFile(path: 'lib/x.so', aligned: false, minAlign: 4096)],
        ),
      ],
    );
    final locked = [const LockedPackage(name: 'unaligned_plugin', version: '2.0.0', isHosted: true)];

    final report = buildCheckReport(lockedPackages: locked, snapshot: snapshot, deadlines: _deadlines);

    expect(report.hasBlocker, isTrue);
    expect(report.text, contains('16 KB page-aligned'));
    expect(report.text, contains('BLOCKER: unaligned_plugin 2.0.0'));
  });

  test('a version mismatch is reported as not checked, never green', () {
    final snapshot = Snapshot(
      schemaVersion: 1,
      generatedAt: '2026-09-26T00:00:00Z',
      topN: 1,
      plugins: [_plugin('some_plugin', '1.0.0', swiftpmTag: true, swiftpmArchive: true)],
    );
    final locked = [const LockedPackage(name: 'some_plugin', version: '2.0.0', isHosted: true)];

    final report = buildCheckReport(lockedPackages: locked, snapshot: snapshot, deadlines: _deadlines);

    expect(report.hasBlocker, isFalse);
    expect(report.text, contains('Not checked'));
    expect(report.text, contains('some_plugin 2.0.0'));
  });

  test('a plugin missing from the data is reported as not checked', () {
    final snapshot = const Snapshot(schemaVersion: 1, generatedAt: '2026-09-26T00:00:00Z', topN: 0, plugins: []);
    final locked = [const LockedPackage(name: 'unknown_plugin', version: '1.0.0', isHosted: true)];

    final report = buildCheckReport(lockedPackages: locked, snapshot: snapshot, deadlines: _deadlines);

    expect(report.hasBlocker, isFalse);
    expect(report.text, contains("not in Flutter Ready's data"));
  });

  test('a clean run has no blockers and exits clean', () {
    final snapshot = Snapshot(
      schemaVersion: 1,
      generatedAt: '2026-09-26T00:00:00Z',
      topN: 1,
      plugins: [_plugin('ready_plugin', '1.0.0', swiftpmTag: true, swiftpmArchive: true)],
    );
    final locked = [const LockedPackage(name: 'ready_plugin', version: '1.0.0', isHosted: true)];

    final report = buildCheckReport(lockedPackages: locked, snapshot: snapshot, deadlines: _deadlines);

    expect(report.hasBlocker, isFalse);
    expect(report.text, contains('No blockers found.'));
  });

  test('a blocker with a matching replacements entry prints the suggestion', () {
    final snapshot = Snapshot(
      schemaVersion: 1,
      generatedAt: '2026-09-26T00:00:00Z',
      topN: 1,
      plugins: [_plugin('no_spm_plugin', '1.0.0', swiftpmTag: false, swiftpmArchive: false)],
    );
    final locked = [const LockedPackage(name: 'no_spm_plugin', version: '1.0.0', isHosted: true)];
    const replacements = {
      'no_spm_plugin': [Replacement(replacement: 'no_spm_plugin_plus', note: 'SwiftPM-ready fork')],
    };

    final report = buildCheckReport(
      lockedPackages: locked,
      snapshot: snapshot,
      deadlines: _deadlines,
      replacements: replacements,
    );

    expect(report.text, contains('Suggested replacement: no_spm_plugin_plus — SwiftPM-ready fork'));
  });

  test('a blocker with no matching replacements entry is unchanged', () {
    final snapshot = Snapshot(
      schemaVersion: 1,
      generatedAt: '2026-09-26T00:00:00Z',
      topN: 1,
      plugins: [_plugin('no_spm_plugin', '1.0.0', swiftpmTag: false, swiftpmArchive: false)],
    );
    final locked = [const LockedPackage(name: 'no_spm_plugin', version: '1.0.0', isHosted: true)];

    final withReplacements = buildCheckReport(
      lockedPackages: locked,
      snapshot: snapshot,
      deadlines: _deadlines,
      replacements: const {},
    );
    final withoutReplacements = buildCheckReport(lockedPackages: locked, snapshot: snapshot, deadlines: _deadlines);

    expect(withReplacements.text, withoutReplacements.text);
    expect(withReplacements.text, isNot(contains('Suggested replacement')));
  });

  test('git and path dependencies are ignored', () {
    final snapshot = const Snapshot(schemaVersion: 1, generatedAt: '2026-09-26T00:00:00Z', topN: 0, plugins: []);
    final locked = [const LockedPackage(name: 'my_fork', version: '1.0.0', isHosted: false)];

    final report = buildCheckReport(lockedPackages: locked, snapshot: snapshot, deadlines: _deadlines);

    expect(report.hasBlocker, isFalse);
    expect(report.text, contains('0 hosted package(s)'));
  });
}
