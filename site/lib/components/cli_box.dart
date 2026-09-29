import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/theme.dart';

/// A quiet card pointing visitors at the flutter_ready CLI, so they can check
/// their own app instead of only reading this board (owner request
/// 2026-09-29: "the pub.dev link isn't on ready.hireflutter.dev" — the
/// package is published at https://pub.dev/packages/flutter_ready, publisher
/// hireflutter.dev). Sits after the count tiles and before the
/// blocked-plugins list, so it never moves the tiles. Reuses existing theme
/// colours: [brandNavy] on [surfaceCard] is ~17.4:1 and [brandBlue] on
/// [surfaceCard] is ~5.2:1, both comfortably past WCAG AA's 4.5:1.
class CliBox extends StatelessComponent {
  const CliBox({super.key});

  @override
  Component build(BuildContext context) {
    return section(classes: 'cli-box', [
      h2([.text('Check your own app')]),
      p([
        .text("Find out which of your app's plugins will block your next release. Run this next to your "),
        code([.text('pubspec.lock')]),
        .text(':'),
      ]),
      div(classes: 'cli-box-code', [
        pre([code([.text('dart pub global activate flutter_ready\nflutter_ready check')])]),
      ]),
      p(classes: 'cli-box-links', [
        a(
          href: 'https://pub.dev/packages/flutter_ready',
          target: .blank,
          attributes: {'rel': 'noopener noreferrer'},
          [.text('flutter_ready on pub.dev')],
        ),
        .text(' · '),
        a(
          href: 'https://github.com/Integrity-Ventures/flutter-ready#github-action',
          target: .blank,
          attributes: {'rel': 'noopener noreferrer'},
          [.text('Use it in CI (GitHub Action)')],
        ),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.cli-box', [
      css('&').styles(
        maxWidth: 34.rem,
        padding: .symmetric(vertical: 1.em, horizontal: 1.2.em),
        margin: .only(top: 1.5.em, left: .auto, right: .auto),
        border: Border.all(color: borderSubtle, width: 1.px),
        radius: .all(.circular(12.px)),
        color: brandNavy,
        textAlign: .left,
        backgroundColor: surfaceCard,
      ),
      css('h2').styles(margin: .zero, fontSize: 1.rem, fontWeight: .w700),
      css('p').styles(margin: .only(top: 0.5.em), fontSize: 0.9.rem),
    ]),
    css('.cli-box-code', [
      css('&').styles(
        padding: .symmetric(vertical: 0.6.em, horizontal: 0.8.em),
        margin: .only(top: 0.6.em),
        border: Border.all(color: borderSubtle, width: 1.px),
        radius: .all(.circular(8.px)),
        overflow: Overflow.only(x: Overflow.auto),
        backgroundColor: surfacePage,
      ),
      css('pre').styles(margin: .zero, whiteSpace: .pre),
      css('code').styles(fontFamily: const .list([FontFamilies.monospace]), fontSize: 0.85.rem),
    ]),
    css('.cli-box-links', [
      css('&').styles(fontSize: 0.85.rem, fontWeight: .w600),
      css('a').styles(color: brandBlue, textDecoration: TextDecoration(line: .none)),
      css('a:hover').styles(textDecoration: TextDecoration(line: .underline)),
    ]),
  ];
}
