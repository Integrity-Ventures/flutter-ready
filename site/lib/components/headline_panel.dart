import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/theme.dart';
import '../data/board.dart';
import '../data/models.dart';
import 'blocked_list.dart';
import 'count_tiles.dart';

/// The headline block above the table (SPEC: "showcase the Reds on top"):
/// the headline sentence, one tile per [BoardCategory], then the blocked
/// names (SPEC: the first screen shows name+question, headline, tiles —
/// nothing else — so the blocked-names list moves below the tiles).
class HeadlinePanel extends StatelessComponent {
  const HeadlinePanel({required this.blocked, required this.counts, required this.totalPlugins, super.key});

  final List<PluginEntry> blocked;
  final BoardCounts counts;
  final int totalPlugins;

  @override
  Component build(BuildContext context) {
    return section(classes: 'headline-panel', [
      p(classes: 'headline', [.text(headlineText(blocked: blocked, totalPlugins: totalPlugins))]),
      CountTiles(counts: counts),
      if (blocked.isNotEmpty) BlockedList(blocked: blocked),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.headline-panel', [
      css('&').styles(
        maxWidth: 56.rem,
        margin: .symmetric(horizontal: .auto),
        textAlign: .center,
      ),
      css('.headline').styles(margin: .zero, color: brandNavy, fontSize: 1.4.rem, fontWeight: .w700),
    ]),
  ];
}
