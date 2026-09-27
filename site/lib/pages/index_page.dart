import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import '../components/deadlines_panel.dart';
import '../components/plugin_table.dart';
import '../components/trend_panel.dart';
import '../data/data_source.dart';
import '../data/models.dart';

/// The board: one row per plugin, plus the deadlines and the SwiftPM trend
/// (SPEC §3.2). [snapshot] is loaded once by [App], which also needs it to
/// register every plugin's static route.
class IndexPage extends AsyncStatelessComponent {
  const IndexPage({required this.snapshot, super.key});

  final Snapshot snapshot;

  @override
  Future<Component> build(BuildContext context) async {
    final deadlines = await loadDeadlines();
    final history = await loadAllSnapshots();

    return div(classes: 'index-page', [
      DeadlinesPanel(deadlines: deadlines),
      TrendPanel(history: history),
      section(classes: 'board', [
        h2([.text('${snapshot.plugins.length} plugins')]),
        PluginTable(plugins: snapshot.plugins),
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
