import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../data/grading.dart';
import '../data/models.dart';

/// A single ratio plus its history is a stat tile, not a chart (a 1-2 point
/// series isn't worth a sparkline yet — see the dataviz form heuristic).
/// Grows into a real trend once more nightly snapshots land.
class TrendPanel extends StatelessComponent {
  const TrendPanel({required this.history, super.key});

  /// Dated snapshots, oldest first.
  final List<DatedSnapshot> history;

  @override
  Component build(BuildContext context) {
    if (history.isEmpty) return .empty();
    final latest = history.last;
    final latestShare = swiftPmGreenSharePercent(latest.snapshot.plugins);

    return section(classes: 'trend-panel', [
      h2([.text('Trend')]),
      div(classes: 'stat-tile', [
        p(classes: 'stat-value', [.text(latestShare == null ? '—' : '$latestShare%')]),
        p(classes: 'stat-label', [
          .text(
            'of the ${latest.snapshot.plugins.length} plugins with a known status ship SwiftPM, '
            'as of the ${latest.date} snapshot.',
          ),
        ]),
      ]),
      if (history.length > 1)
        table(classes: 'trend-history', [
          thead([
            tr([
              th([.text('Snapshot date')]),
              th([.text('SwiftPM ready')]),
            ]),
          ]),
          tbody([
            for (final snapshot in history.reversed) _historyRow(snapshot),
          ]),
        ]),
    ]);
  }

  Component _historyRow(DatedSnapshot dated) {
    final share = swiftPmGreenSharePercent(dated.snapshot.plugins);
    return tr([
      td([.text(dated.date)]),
      td([.text(share == null ? '—' : '$share%')]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.trend-panel', [
      css('&').styles(
        maxWidth: 48.rem,
        margin: .symmetric(horizontal: .auto),
        textAlign: .center,
      ),
      css('h2').styles(fontSize: 1.1.rem),
      css('.stat-tile').styles(margin: .symmetric(vertical: 1.em)),
      css('.stat-value').styles(margin: .zero, fontSize: 3.rem, fontWeight: .w700),
      css('.stat-label').styles(margin: .zero, color: const Color('#52514e')),
      css('.trend-history', [
        css('&').styles(
          width: 100.percent,
          margin: .symmetric(horizontal: .auto),
        ),
        css('th, td').styles(
          padding: .symmetric(vertical: 0.3.em),
          textAlign: .center,
        ),
      ]),
    ]),
  ];
}
