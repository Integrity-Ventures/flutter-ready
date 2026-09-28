import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../data/board.dart';
import '../data/models.dart';
import 'blocked_list.dart';
import 'count_tiles.dart';

/// The headline block above the table (SPEC: "showcase the Reds on top"):
/// one tile per board category, then the blocked names (SPEC: the first
/// screen shows name+question, headline, tiles — nothing else — so the
/// blocked-names list moves below the tiles). The headline sentence itself
/// now lives in the page hero (the "one hero, not two" rework), so this
/// panel only holds what follows it.
class HeadlinePanel extends StatelessComponent {
  const HeadlinePanel({required this.blocked, required this.counts, super.key});

  final List<PluginEntry> blocked;
  final BoardCounts counts;

  @override
  Component build(BuildContext context) {
    return section(classes: 'headline-panel', [
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
    ]),
  ];
}
