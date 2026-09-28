import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/theme.dart';

/// A quiet footer on every page: the owner's company credit and an
/// open-source/data note (owner request 2026-09-28: "I want my company
/// name in the footer"). Small, muted, centred text — [textMuted] on the
/// page background is ~7:1, comfortably past WCAG AA's 4.5:1 for small
/// text, so no new colour is needed here.
class Footer extends StatelessComponent {
  const Footer({super.key});

  @override
  Component build(BuildContext context) {
    return footer(classes: 'site-footer', [
      p([
        .text('© 2026 '),
        a(href: 'https://ivp.life', [.text('Integrity Ventures Private Limited')]),
      ]),
      p([
        .text('Open source (MIT) · '),
        a(href: 'https://github.com/Integrity-Ventures/flutter-ready', [.text('Source on GitHub')]),
        .text(' · Data from pub.dev, updated nightly'),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.site-footer', [
      css('&').styles(
        padding: .symmetric(vertical: 1.5.em, horizontal: 1.em),
        border: .only(
          top: BorderSide.solid(color: borderSubtle, width: 1.px),
        ),
        color: textMuted,
        textAlign: .center,
        fontSize: 0.85.rem,
      ),
      css('p').styles(margin: .only(top: 0.35.em)),
      css('a').styles(color: textMuted, fontWeight: .w600),
    ]),
  ];
}
