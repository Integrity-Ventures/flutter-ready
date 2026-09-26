import 'package:readiness_check/readiness_check.dart';

import 'pubspec_lock.dart';

/// The printable `flutter_ready check` report and whether it found a
/// blocker (SPEC §3.3: the CLI "exits non-zero when a blocker is found").
class CheckReport {
  const CheckReport({required this.text, required this.hasBlocker});

  final String text;
  final bool hasBlocker;
}

/// Builds the `check` report from a parsed lockfile and the Flutter Ready
/// data. Pure: no IO, no network, so it can be tested and golden-tested
/// directly (SPEC §5).
CheckReport buildCheckReport({
  required List<LockedPackage> lockedPackages,
  required Snapshot snapshot,
  required List<Deadline> deadlines,
}) {
  final hosted = lockedPackages.where((p) => p.isHosted).toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  final byName = {for (final plugin in snapshot.plugins) plugin.name: plugin};

  final notChecked = <String>[];
  final blockersByDeadline = <Deadline, List<String>>{};

  for (final locked in hosted) {
    final entry = byName[locked.name];
    if (entry == null) {
      notChecked.add("${locked.name} ${locked.version}: not in Flutter Ready's data.");
      continue;
    }
    if (entry.version != locked.version) {
      notChecked.add(
        '${locked.name} ${locked.version}: Flutter Ready last checked ${entry.version}.',
      );
      continue;
    }

    for (final deadline in deadlines) {
      // Android has no colour rule yet (SPEC open decision 3): facts only.
      final status = switch (deadline.check) {
        'swiftpm' => swiftPmStatus(entry),
        'alignment' => alignmentStatus(entry),
        _ => null,
      };
      if (status != Status.red) continue;

      final evidence = deadline.check == 'swiftpm' ? swiftPmEvidence(entry) : alignmentEvidence(entry);
      blockersByDeadline.putIfAbsent(deadline, () => []).add('${locked.name} ${locked.version}: $evidence');
    }
  }

  final blockerCount = blockersByDeadline.values.fold(0, (sum, lines) => sum + lines.length);

  final buffer = StringBuffer()
    ..writeln('Flutter Ready check — ${hosted.length} hosted package(s) in pubspec.lock.')
    ..writeln();

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

  return CheckReport(text: buffer.toString().trimRight(), hasBlocker: blockerCount > 0);
}
