import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import '../components/deadlines_panel.dart';
import '../components/headline_panel.dart';
import '../components/plugin_table.dart';
import '../components/trend_panel.dart';
import '../data/board.dart';
import '../data/data_source.dart';
import '../data/models.dart';

/// The board: the reds-on-top headline, count tiles, one row per plugin,
/// plus the deadlines and trend (SPEC §3.2, and the "reds on top, honest
/// counts" rework). [snapshot] is loaded once by [App], which also needs it
/// to register every plugin's static route.
class IndexPage extends AsyncStatelessComponent {
  const IndexPage({required this.snapshot, super.key});

  final Snapshot snapshot;

  @override
  Future<Component> build(BuildContext context) async {
    final deadlines = await loadDeadlines();
    final history = await loadAllSnapshots();

    final rows = buildBoardRows(snapshot.plugins);
    final counts = BoardCounts.from(snapshot.plugins);
    final blocked = [for (final row in rows.where((r) => r.category == BoardCategory.blocked)) row.plugin];

    return div(classes: 'index-page', [
      HeadlinePanel(blocked: blocked, counts: counts, totalPlugins: snapshot.plugins.length),
      DeadlinesPanel(deadlines: deadlines),
      TrendPanel(history: history),
      section(classes: 'board', [
        h2([.text('${snapshot.plugins.length} plugins')]),
        PluginTable(rows: rows),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.index-page', [
      css('&').styles(
        display: .flex,
        padding: .symmetric(vertical: 2.em, horizontal: 1.em),
        flexDirection: .column,
        gap: .all(2.em),
      ),
      css('.board').styles(
        width: 100.percent,
        maxWidth: 72.rem,
        margin: .symmetric(horizontal: .auto),
      ),
      css('.board h2').styles(fontSize: 1.1.rem),
    ]),
  ];
}
