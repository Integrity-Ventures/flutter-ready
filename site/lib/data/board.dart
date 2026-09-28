/// Board-specific presentation logic, built on top of `readiness_check`'s
/// shared grading (`grading.dart`, re-exported here) rather than
/// reimplementing red/amber/green rules (SPEC §2).
///
/// [Status.green] from the shared grading conflates two different things —
/// "ships SwiftPM" and "not affected by the deadline at all" — which is
/// exactly what made the live board show a misleading 100%-ready headline
/// (owner: "It shows 100%. What is the use of this?"). [BoardCategory]
/// splits that back apart; everything below (tiles, table order, headline,
/// the attention filter) is built from it, never from [Status] directly.
library;

import 'grading.dart';
import 'models.dart';

enum BoardCategory { blocked, unclear, ready, notAffected, notChecked }

/// The one place a raw grading [Status] becomes a [BoardCategory] — the
/// tiles (via [boardCategoryOf]) and the status chips both call this, so a
/// chip's label can never drift from the tile that counts it. [nativeIos]
/// only applies to checks with a "not affected" case (SwiftPM); pass null
/// for checks that don't have one (alignment), and a green status is always
/// [BoardCategory.ready] there.
BoardCategory categoryForStatus(Status status, {bool? nativeIos}) {
  return switch (status) {
    Status.red => BoardCategory.blocked,
    Status.amber => BoardCategory.unclear,
    Status.notChecked => BoardCategory.notChecked,
    Status.green => nativeIos == false ? BoardCategory.notAffected : BoardCategory.ready,
  };
}

BoardCategory boardCategoryOf(PluginEntry plugin) =>
    categoryForStatus(swiftPmStatus(plugin), nativeIos: plugin.swiftpm.nativeIos);

/// Table order (SPEC: "reds on top"): red, amber, grey, green — [ready] and
/// [notAffected] share the last slot since both are shown as one
/// unmerged-in-the-tiles-but-not-blocking group in the table.
int _tableRank(BoardCategory category) => switch (category) {
  BoardCategory.blocked => 0,
  BoardCategory.unclear => 1,
  BoardCategory.notChecked => 2,
  BoardCategory.ready => 3,
  BoardCategory.notAffected => 3,
};

/// True for the categories the "needs attention" filter keeps: red, amber,
/// grey. Ready and not-affected plugins are the "all clear" rows it hides.
bool categoryNeedsAttention(BoardCategory category) => _tableRank(category) < 3;

/// One row of the board table: a plugin plus the two facts the board derives
/// for it — its category and its rank by 30-day downloads among every
/// plugin on this snapshot (independent of table sort order, so a red row
/// far down the table still shows how heavily it's used).
class BoardRow {
  const BoardRow({
    required this.plugin,
    required this.downloadRank,
    required this.category,
  });

  final PluginEntry plugin;
  final int downloadRank;
  final BoardCategory category;

  bool get needsAttention => categoryNeedsAttention(category);
}

/// Builds one [BoardRow] per plugin, sorted red/amber/grey/green, downloads
/// descending within each group (SPEC: "reds on top, honest counts").
List<BoardRow> buildBoardRows(List<PluginEntry> plugins) {
  final byDownloads = [...plugins]..sort((a, b) => (b.downloadCount30Days ?? 0).compareTo(a.downloadCount30Days ?? 0));
  final downloadRank = {for (var i = 0; i < byDownloads.length; i++) byDownloads[i].name: i + 1};

  final rows = [
    for (final plugin in plugins)
      BoardRow(
        plugin: plugin,
        downloadRank: downloadRank[plugin.name]!,
        category: boardCategoryOf(plugin),
      ),
  ];

  rows.sort((a, b) {
    final rankCompare = _tableRank(a.category).compareTo(_tableRank(b.category));
    if (rankCompare != 0) return rankCompare;
    return (b.plugin.downloadCount30Days ?? 0).compareTo(a.plugin.downloadCount30Days ?? 0);
  });

  return rows;
}

/// Honest, never-merged counts for the board's tiles (SPEC: one tile per
/// [BoardCategory], "tiles never merge categories").
class BoardCounts {
  const BoardCounts({
    required this.blocked,
    required this.unclear,
    required this.ready,
    required this.notAffected,
    required this.notChecked,
  });

  factory BoardCounts.from(List<PluginEntry> plugins) {
    var blocked = 0, unclear = 0, ready = 0, notAffected = 0, notChecked = 0;
    for (final plugin in plugins) {
      switch (boardCategoryOf(plugin)) {
        case BoardCategory.blocked:
          blocked++;
        case BoardCategory.unclear:
          unclear++;
        case BoardCategory.ready:
          ready++;
        case BoardCategory.notAffected:
          notAffected++;
        case BoardCategory.notChecked:
          notChecked++;
      }
    }
    return BoardCounts(
      blocked: blocked,
      unclear: unclear,
      ready: ready,
      notAffected: notAffected,
      notChecked: notChecked,
    );
  }

  final int blocked;
  final int unclear;
  final int ready;
  final int notAffected;
  final int notChecked;

  int get total => blocked + unclear + ready + notAffected + notChecked;
}

/// The board's headline (SPEC: word it from `discovery`, not a "top N" rank
/// — the candidate set comes from two pub.dev searches, not a single
/// ranked list, see `data/latest.json`'s `discovery` field).
String headlineText({required List<PluginEntry> blocked, required int totalPlugins}) {
  if (blocked.isEmpty) {
    return 'No plugin among the $totalPlugins most-downloaded iOS plugins checked here '
        'blocks iOS apps today.';
  }
  return '${blocked.length} of the $totalPlugins most-downloaded iOS plugins checked here '
      'still block iOS apps before CocoaPods goes read-only on 2 Dec 2026.';
}

/// `1,197,182`-style grouping; downloads are always shown alongside rank
/// (SPEC: "showing downloads").
String formatDownloads(int? downloads) {
  if (downloads == null) return '—';
  final digits = downloads.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
