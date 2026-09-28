/// The snapshot contract classes now live in `readiness_check`, shared with
/// the CLI (`flutter_ready`) so the two can't disagree (SPEC §2). Re-exported
/// here so every existing relative import in `site/lib` keeps working.
library;

import 'package:flutter_ready/readiness_check.dart';

export 'package:flutter_ready/readiness_check.dart'
    show AlignmentInfo, AndroidInfo, Deadline, PluginEntry, Snapshot, SoFile, SwiftPmInfo;

/// One dated snapshot, tagged with the UTC date taken from its filename
/// (`data/snapshots/<YYYY-MM-DD>.json`), for building the trend view. Kept
/// here, not in `readiness_check`, since only the board needs trend data.
class DatedSnapshot {
  const DatedSnapshot({required this.date, required this.snapshot});

  final String date;
  final Snapshot snapshot;
}
