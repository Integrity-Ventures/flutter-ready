import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../constants/status_colors.dart';
import '../constants/theme.dart';
import '../data/models.dart';

/// The blocked plugin names, below the tiles (SPEC: this used to run as one
/// wall-of-links paragraph above the tiles, pushing them below the fold —
/// moved here and turned into a scannable, wrapped list of pill links, each
/// still to `/p/<name>/`).
class BlockedList extends StatelessComponent {
  const BlockedList({required this.blocked, super.key});

  final List<PluginEntry> blocked;

  @override
  Component build(BuildContext context) {
    return section(classes: 'blocked-list', [
      h2([.text('Blocked plugins')]),
      ul(
        classes: 'blocked-list-items',
        [for (final plugin in blocked) li([Link(to: '/p/${plugin.name}', child: .text(plugin.name))])],
      ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.blocked-list', [
      css('&').styles(
        maxWidth: 56.rem,
        margin: .only(top: 2.em, left: .auto, right: .auto),
        textAlign: .center,
      ),
      css('h2').styles(color: textMuted, fontSize: 0.85.rem, textTransform: .upperCase),
    ]),
    css('.blocked-list-items', [
      css('&').styles(
        display: .flex,
        padding: .zero,
        margin: .only(top: 0.6.em),
        flexWrap: .wrap,
        justifyContent: .center,
        gap: .all(0.5.em),
        listStyle: ListStyle.none,
      ),
      css('a').styles(
        display: .inlineBlock,
        padding: .symmetric(vertical: 0.3.em, horizontal: 0.7.em),
        radius: .all(.circular(999.px)),
        color: statusRed,
        textDecoration: TextDecoration(line: .none),
        fontSize: 0.85.rem,
        backgroundColor: statusRedBg,
      ),
      css('a:hover').styles(textDecoration: TextDecoration(line: .underline)),
    ]),
  ];
}
