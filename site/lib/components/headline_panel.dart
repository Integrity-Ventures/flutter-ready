import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../data/board.dart';
import '../data/models.dart';
import 'count_tiles.dart';

/// The headline block above the table (SPEC: "showcase the Reds on top"):
/// the blocked count and names, then one tile per [BoardCategory].
class HeadlinePanel extends StatelessComponent {
  const HeadlinePanel({required this.blocked, required this.counts, required this.totalPlugins, super.key});

  final List<PluginEntry> blocked;
  final BoardCounts counts;
  final int totalPlugins;

  @override
  Component build(BuildContext context) {
    return section(classes: 'headline-panel', [
      p(classes: 'headline', [.text(headlineText(blocked: blocked, totalPlugins: totalPlugins))]),
      if (blocked.isNotEmpty)
        p(
          classes: 'blocked-names',
          [
            for (var i = 0; i < blocked.length; i++) ...[
              if (i > 0) .text(', '),
              Link(to: '/p/${blocked[i].name}', child: .text(blocked[i].name)),
            ],
          ],
        ),
      CountTiles(counts: counts),
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
      css('.headline').styles(margin: .zero, fontSize: 1.4.rem, fontWeight: .w700),
      css('.blocked-names').styles(
        margin: .only(top: 0.6.em),
        color: const Color('#52514e'),
        fontSize: 0.9.rem,
      ),
    ]),
  ];
}
