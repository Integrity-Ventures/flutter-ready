import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/status_colors.dart';
import '../data/board.dart';

/// One tile per [BoardCategory], never merged (SPEC: "It shows 100%. What is
/// the use of this?" — that headline merged "ships SwiftPM" with "not
/// affected"). "Not checked" only appears when there were any errors.
class CountTiles extends StatelessComponent {
  const CountTiles({required this.counts, super.key});

  final BoardCounts counts;

  @override
  Component build(BuildContext context) {
    final tiles = [
      (BoardCategory.blocked, counts.blocked),
      (BoardCategory.unclear, counts.unclear),
      (BoardCategory.ready, counts.ready),
      (BoardCategory.notAffected, counts.notAffected),
      if (counts.notChecked > 0) (BoardCategory.notChecked, counts.notChecked),
    ];

    return section(classes: 'count-tiles', [for (final (category, count) in tiles) _tile(category, count)]);
  }

  Component _tile(BoardCategory category, int count) {
    return div(
      classes: 'count-tile',
      styles: Styles(
        border: Border.all(color: colorForCategory(category), width: 2.px),
      ),
      [
        p(classes: 'count-value', styles: Styles(color: colorForCategory(category)), [.text('$count')]),
        p(classes: 'count-label', [.text(labelForCategory(category))]),
      ],
    );
  }

  @css
  static List<StyleRule> get styles => [
    css('.count-tiles', [
      css('&').styles(
        display: .flex,
        margin: .only(top: 1.5.em),
        flexWrap: .wrap,
        justifyContent: .center,
        gap: .all(1.em),
      ),
    ]),
    css('.count-tile', [
      css('&').styles(
        minWidth: 8.rem,
        padding: .symmetric(vertical: 0.8.em, horizontal: 1.2.em),
        radius: .all(.circular(8.px)),
        textAlign: .center,
      ),
    ]),
    css('.count-value').styles(margin: .zero, fontSize: 2.2.rem, fontWeight: .w700),
    css('.count-label').styles(margin: .zero, color: const Color('#52514e'), fontSize: 0.85.rem),
  ];
}
