import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/theme.dart';
import '../data/models.dart';

/// The deadlines this board covers, read from `data/deadlines.json` (SPEC §1,
/// open decision 6: deadlines are listed as data so a new season's deadlines
/// can be added without code changes).
class DeadlinesPanel extends StatelessComponent {
  const DeadlinesPanel({required this.deadlines, super.key});

  final List<Deadline> deadlines;

  @override
  Component build(BuildContext context) {
    return section(classes: 'deadlines-panel', [
      h2([.text('The deadlines')]),
      ul([for (final deadline in deadlines) _item(deadline)]),
    ]);
  }

  Component _item(Deadline deadline) {
    final when = switch ((deadline.date, deadline.extendedDate)) {
      (null, _) => 'date not settled',
      (final date, null) => date,
      (final date, final extended) => '$date, extended to $extended',
    };
    return li([
      .text('${deadline.title} — $when. '),
      span(classes: 'source', [.text('Source: ${deadline.source}')]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.deadlines-panel', [
      css('&').styles(
        maxWidth: 48.rem,
        margin: .symmetric(horizontal: .auto),
      ),
      css('h2').styles(fontSize: 1.1.rem),
      css('li').styles(margin: .only(bottom: 0.5.em)),
      css('.source').styles(color: textMuted, fontSize: 0.85.rem),
    ]),
  ];
}
