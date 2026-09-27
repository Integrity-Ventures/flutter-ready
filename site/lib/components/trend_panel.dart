import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../data/board.dart';
import '../data/models.dart';

/// Counts per snapshot date (SPEC: replace the percentage trend — comparing
/// 2026-09-26's 88% with 2026-09-27's 100% looked like plugins improved
/// overnight, when the jump was really the grading fixes landing that day).
/// A count table is honest about that: it can't be misread as plugins
/// changing when the grading rules did.
class TrendPanel extends StatelessComponent {
  const TrendPanel({required this.history, super.key});

  /// Dated snapshots, oldest first.
  final List<DatedSnapshot> history;

  @override
  Component build(BuildContext context) {
    if (history.isEmpty) return .empty();

    return section(classes: 'trend-panel', [
      h2([.text('Trend')]),
      table(classes: 'trend-history', [
        thead([
          tr([
            th([.text('Snapshot date')]),
            th([.text('Blocked')]),
            th([.text('Unclear')]),
            th([.text('Ready')]),
            th([.text('Not affected')]),
          ]),
        ]),
        tbody([for (final snapshot in history.reversed) _historyRow(snapshot)]),
      ]),
      p(classes: 'trend-note', [
        .text(
          'Counts use the grading rules of 2026-09-27; earlier snapshots were removed.',
        ),
      ]),
    ]);
  }

  Component _historyRow(DatedSnapshot dated) {
    final counts = BoardCounts.from(dated.snapshot.plugins);
    return tr([
      td([.text(dated.date)]),
      td([.text('${counts.blocked}')]),
      td([.text('${counts.unclear}')]),
      td([.text('${counts.ready}')]),
      td([.text('${counts.notAffected}')]),
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
      css('.trend-note').styles(
        margin: .only(top: 0.6.em),
        color: const Color('#898781'),
        fontSize: 0.82.rem,
      ),
    ]),
  ];
}
