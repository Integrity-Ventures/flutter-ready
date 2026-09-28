import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../constants/theme.dart';

/// The page hero: the "Flutter Ready" title (linking home) plus ONE line of
/// explanation. Every page gets exactly one of these, right below the slim
/// [Header] bar — no separate white band and no second, near-duplicate
/// sentence (the "one hero, not two" rework, owner request 2026-09-28). The
/// [subtitle] is page-specific: the board's data headline on `/`, a
/// per-plugin question on `/p/<name>`.
class Hero extends StatelessComponent {
  const Hero({required this.subtitle, super.key});

  final String subtitle;

  @override
  Component build(BuildContext context) {
    return div(classes: 'hero', [
      Link(to: '/', child: h1([.text('Flutter Ready')])),
      p(classes: 'hero-subtitle', [.text(subtitle)]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.hero', [
      css('&').styles(
        maxWidth: 46.rem,
        padding: .symmetric(vertical: 1.5.em, horizontal: 1.em),
        margin: .symmetric(horizontal: .auto),
        textAlign: .center,
      ),
      css('h1').styles(margin: .zero, color: brandNavy, fontSize: 1.8.rem, fontWeight: .w800),
      css('a').styles(textDecoration: TextDecoration(line: .none)),
      css('.hero-subtitle').styles(
        margin: .only(top: 0.5.em),
        color: textMuted,
        raw: {'text-wrap': 'balance'},
      ),
      css.media(MediaQuery.screen(maxWidth: 480.px), [
        css('h1').styles(fontSize: 1.5.rem),
      ]),
    ]),
  ];
}
