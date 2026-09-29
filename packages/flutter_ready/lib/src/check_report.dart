import 'package:flutter_ready/readiness_check.dart';

import 'live_check.dart';
import 'pubspec_lock.dart';
import 'replacements.dart';

/// The printable `flutter_ready check` report and whether it found a
/// blocker (SPEC §3.3: the CLI "exits non-zero when a blocker is found").
class CheckReport {
  const CheckReport({required this.text, required this.hasBlocker});

  final String text;
  final bool hasBlocker;
}

/// Builds the `check` report from a parsed lockfile, the Flutter Ready data,
/// and (CLI live-check task, 2026-09-27) the live-check results for any
/// hosted package the data doesn't cover at the locked version. Pure: no IO,
/// no network itself — [liveResults] is computed beforehand by
/// [runLiveChecks] — so it can be tested and golden-tested directly (SPEC
/// §5). A package absent from [liveResults] (e.g. `--offline`, or a live
/// check that was never attempted) falls back to the old "not checked"
/// message.
CheckReport buildCheckReport({
  required List<LockedPackage> lockedPackages,
  required Snapshot snapshot,
  required List<Deadline> deadlines,
  Map<String, List<Replacement>> replacements = const {},
  List<LiveCheckResult> liveResults = const [],
}) {
  final hosted = lockedPackages.where((p) => p.isHosted).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  final byName = {for (final plugin in snapshot.plugins) plugin.name: plugin};
  final liveByName = {for (final result in liveResults) result.name: result};
  final dataDate = snapshot.generatedAt.split('T').first;

  final notChecked = <String>[];
  final blockersByDeadline = <Deadline, List<String>>{};
  var skippedCount = 0;

  for (final locked in hosted) {
    final entry = byName[locked.name];
    if (entry != null && entry.version == locked.version) {
      _addDeadlineBlockers(
        deadlines: deadlines,
        blockersByDeadline: blockersByDeadline,
        locked: locked,
        replacements: replacements,
        statusFor: (check) =>
            check == 'swiftpm' ? swiftPmStatus(entry) : alignmentStatus(entry),
        evidenceFor: (check) => check == 'swiftpm'
            ? swiftPmEvidence(entry)
            : alignmentEvidence(entry),
        originLabel: 'from Flutter Ready data ($dataDate)',
      );
      continue;
    }

    final live = liveByName[locked.name];
    if (live == null) {
      notChecked.add(
        entry == null
            ? "${locked.name} ${locked.version}: not in Flutter Ready's data."
            : '${locked.name} ${locked.version}: Flutter Ready last checked ${entry.version}.',
      );
      continue;
    }
    if (!live.isPlugin) {
      skippedCount++;
      continue;
    }
    if (live.notCheckedReason != null) {
      notChecked.add(
        '${locked.name} ${locked.version}: not checked: ${live.notCheckedReason}',
      );
      continue;
    }

    final grade = live.grade!;
    final fallbackNote = live.usedFallbackLatest
        ? " ${live.checkedPackage} isn't locked in pubspec.lock; used its latest published version instead."
        : '';
    _addDeadlineBlockers(
      deadlines: deadlines,
      blockersByDeadline: blockersByDeadline,
      locked: locked,
      replacements: replacements,
      statusFor: (check) =>
          check == 'swiftpm' ? grade.swiftPm : grade.alignment,
      evidenceFor: (check) =>
          '${check == 'swiftpm' ? grade.swiftPmEvidence : grade.alignmentEvidence}$fallbackNote',
      originLabel: 'checked live',
    );
  }

  final blockerCount = blockersByDeadline.values.fold(
    0,
    (sum, lines) => sum + lines.length,
  );

  final buffer = StringBuffer()
    ..writeln(
      'Flutter Ready check — ${hosted.length} hosted package(s) in pubspec.lock.',
    );
  if (skippedCount > 0) {
    buffer.writeln(
      'Skipped $skippedCount pure Dart package(s) (not Flutter plugins).',
    );
  }
  buffer.writeln();

  if (blockerCount == 0) {
    buffer.writeln('No blockers found.');
  } else {
    for (final deadline in deadlines) {
      final lines = blockersByDeadline[deadline];
      if (lines == null || lines.isEmpty) continue;
      final dated = deadline.date != null ? ' (${deadline.date})' : '';
      buffer.writeln('${deadline.title}$dated:');
      for (final line in lines) {
        buffer.writeln('  BLOCKER: $line');
      }
      buffer.writeln();
    }
  }

  if (notChecked.isNotEmpty) {
    buffer.writeln('Not checked:');
    for (final line in notChecked) {
      buffer.writeln('  $line');
    }
  }

  return CheckReport(
    text: buffer.toString().trimRight(),
    hasBlocker: blockerCount > 0,
  );
}

/// Appends a BLOCKER line, labelled with [originLabel], to
/// [blockersByDeadline] for every [deadlines] entry [statusFor] grades red.
/// Shared between the from-data path (evidence from a [PluginEntry]) and the
/// checked-live path (evidence from a [LiveGrade]) — only how the status and
/// evidence are read differs between them.
void _addDeadlineBlockers({
  required List<Deadline> deadlines,
  required Map<Deadline, List<String>> blockersByDeadline,
  required LockedPackage locked,
  required Map<String, List<Replacement>> replacements,
  required Status Function(String check) statusFor,
  required String Function(String check) evidenceFor,
  required String originLabel,
}) {
  for (final deadline in deadlines) {
    // Android has no colour rule yet (SPEC open decision 3): facts only.
    if (deadline.check != 'swiftpm' && deadline.check != 'alignment') continue;
    if (statusFor(deadline.check) != Status.red) continue;

    final evidence = '${evidenceFor(deadline.check)} — $originLabel';
    blockersByDeadline
        .putIfAbsent(deadline, () => [])
        .add(_blockerLine(locked, evidence, replacements[locked.name]));
  }
}

/// A blocker line, with a hand-curated suggestion appended per entry in
/// [suggestions], if any (SPEC §3.3, open decision 4: never generated).
String _blockerLine(
  LockedPackage locked,
  String evidence,
  List<Replacement>? suggestions,
) {
  final buffer = StringBuffer('${locked.name} ${locked.version}: $evidence');
  for (final suggestion in suggestions ?? const []) {
    buffer.write('\n    Suggested replacement: ${suggestion.replacement}');
    if (suggestion.note.isNotEmpty) buffer.write(' — ${suggestion.note}');
  }
  return buffer.toString();
}
