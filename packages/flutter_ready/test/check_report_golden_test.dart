// Golden tests of `flutter_ready check`'s report text (SPEC §5), driven by
// the same fixture data `.github/workflows/verify-action.yml` runs the
// real Action against: `fixtures/sample_app/data/`. Paths are relative to
// the package root, which is `dart test`'s working directory (see
// .github/workflows/ci.yml). Regenerate golden files by running with
// UPDATE_GOLDENS=1.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_ready/flutter_ready.dart';
import 'package:readiness_check/readiness_check.dart';
import 'package:test/test.dart';

const _fixtureDataDir = '../../fixtures/sample_app/data';
const _goldensDir = 'test/goldens';

Snapshot _loadSnapshot() =>
    Snapshot.fromJson(jsonDecode(File('$_fixtureDataDir/latest.json').readAsStringSync()) as Map<String, dynamic>);

List<Deadline> _loadDeadlines() {
  final json = jsonDecode(File('$_fixtureDataDir/deadlines.json').readAsStringSync()) as Map<String, dynamic>;
  return [for (final d in json['deadlines'] as List) Deadline.fromJson(d as Map<String, dynamic>)];
}

Map<String, List<Replacement>> _loadReplacements() =>
    parseReplacements(File('$_fixtureDataDir/replacements.json').readAsStringSync());

/// Compares [actual] against the golden file `$_goldensDir/$name`. With
/// `UPDATE_GOLDENS` set, writes [actual] as the new golden instead of
/// comparing, so an intentional report-format change doesn't require
/// hand-editing every golden file.
void _expectGolden(String name, String actual) {
  final file = File('$_goldensDir/$name');
  if (Platform.environment['UPDATE_GOLDENS'] == '1') {
    file.writeAsStringSync('$actual\n');
    return;
  }
  expect(actual, file.readAsStringSync().trimRight(), reason: 'golden: $_goldensDir/$name');
}

void main() {
  final snapshot = _loadSnapshot();
  final deadlines = _loadDeadlines();
  final replacements = _loadReplacements();

  test('blocker: a red plugin prints a BLOCKER line with evidence', () {
    final locked = [const LockedPackage(name: 'fixture_blocked_plugin', version: '1.0.0', isHosted: true)];

    final report = buildCheckReport(lockedPackages: locked, snapshot: snapshot, deadlines: deadlines);

    expect(report.hasBlocker, isTrue);
    _expectGolden('blocker.txt', report.text);
  });

  test('clean: an all-green lockfile has no blockers', () {
    final locked = [const LockedPackage(name: 'fixture_green_plugin', version: '1.0.0', isHosted: true)];

    final report = buildCheckReport(lockedPackages: locked, snapshot: snapshot, deadlines: deadlines);

    expect(report.hasBlocker, isFalse);
    _expectGolden('clean.txt', report.text);
  });

  test('not checked: a package absent from the data is never green', () {
    final locked = [const LockedPackage(name: 'fixture_unknown_plugin', version: '1.0.0', isHosted: true)];

    final report = buildCheckReport(lockedPackages: locked, snapshot: snapshot, deadlines: deadlines);

    expect(report.hasBlocker, isFalse);
    _expectGolden('not_checked.txt', report.text);
  });

  test('mixed: from-data, checked-live and skipped packages in one report', () {
    final locked = [
      const LockedPackage(name: 'fixture_blocked_plugin', version: '1.0.0', isHosted: true),
      const LockedPackage(name: 'some_dart_pkg', version: '1.0.0', isHosted: true),
      const LockedPackage(name: 'some_unknown_plugin', version: '2.0.0', isHosted: true),
      const LockedPackage(name: 'some_ready_plugin', version: '3.0.0', isHosted: true),
      const LockedPackage(name: 'some_broken_plugin', version: '4.0.0', isHosted: true),
    ];
    final liveResults = [
      LiveCheckResult.skipped('some_dart_pkg', '1.0.0'),
      LiveCheckResult.checked(
        'some_unknown_plugin',
        '2.0.0',
        grade: const LiveGrade(
          swiftPm: Status.red,
          swiftPmEvidence: 'No Package.swift in the some_unknown_plugin archive.',
          alignment: Status.green,
          alignmentEvidence: 'No native libraries in archive.',
        ),
        checkedPackage: 'some_unknown_plugin',
        usedFallbackLatest: false,
      ),
      LiveCheckResult.checked(
        'some_ready_plugin',
        '3.0.0',
        grade: const LiveGrade(
          swiftPm: Status.green,
          swiftPmEvidence: 'Package.swift found in the some_ready_plugin archive.',
          alignment: Status.green,
          alignmentEvidence: 'No native libraries in archive.',
        ),
        checkedPackage: 'some_ready_plugin',
        usedFallbackLatest: false,
      ),
      LiveCheckResult.notChecked('some_broken_plugin', '4.0.0', 'HTTP 404 fetching some_broken_plugin'),
    ];

    final report = buildCheckReport(
      lockedPackages: locked,
      snapshot: snapshot,
      deadlines: deadlines,
      liveResults: liveResults,
    );

    expect(report.hasBlocker, isTrue);
    _expectGolden('mixed.txt', report.text);
  });

  test('suggestion: a blocker with a matching replacement prints it', () {
    final locked = [const LockedPackage(name: 'fixture_blocked_plugin', version: '1.0.0', isHosted: true)];

    final report = buildCheckReport(
      lockedPackages: locked,
      snapshot: snapshot,
      deadlines: deadlines,
      replacements: replacements,
    );

    expect(report.hasBlocker, isTrue);
    _expectGolden('suggestion.txt', report.text);
  });
}
