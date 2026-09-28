import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../constants/theme.dart';

class Header extends StatelessComponent {
  const Header({super.key});

  @override
  Component build(BuildContext context) {
    return header([
      div(classes: 'brand-bar', [
        a(href: 'https://hireflutter.dev/', classes: 'brand-wordmark', [.text('HireFlutter.dev')]),
        span(classes: 'powered-pill', [.text('Powered by 10xs')]),
      ]),
      Link(to: '/', child: h1([.text('Flutter Ready')])),
      p(classes: 'tagline', [
        .text('Is the plugin you depend on ready for CocoaPods going read-only and Play’s API 36?'),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('header', [
      css('&').styles(
        display: .flex,
        padding: .symmetric(vertical: 1.5.em, horizontal: 1.em),
        border: .only(
          bottom: BorderSide.solid(color: borderSubtle, width: 1.px),
        ),
        flexDirection: .column,
        alignItems: .center,
        color: brandNavy,
        textAlign: .center,
        backgroundColor: surfaceCard,
      ),
      css('.brand-bar').styles(
        display: .flex,
        margin: .only(bottom: 1.em),
        justifyContent: .center,
        alignItems: .center,
        gap: .all(0.6.em),
      ),
      css('.brand-wordmark').styles(
        color: brandNavy,
        fontSize: 1.25.rem,
        fontWeight: .w800,
        textDecoration: TextDecoration(line: .none),
        letterSpacing: (-0.02).em,
      ),
      css('.powered-pill').styles(
        display: .none,
        padding: .symmetric(vertical: 0.25.em, horizontal: 0.8.em),
        radius: .all(.circular(999.px)),
        color: brandBlueDark,
        fontSize: 0.75.rem,
        fontWeight: .w600,
        backgroundColor: pillBackground,
      ),
      css.media(MediaQuery.screen(minWidth: 640.px), [
        css('.powered-pill').styles(display: .inlineFlex, alignItems: .center),
      ]),
      css('h1').styles(margin: .zero, color: brandNavy, fontSize: 2.2.rem, fontWeight: .w800),
      css('a').styles(textDecoration: TextDecoration(line: .none)),
      css('.tagline').styles(
        maxWidth: 46.rem,
        margin: .only(top: 0.5.em),
        color: textMuted,
        raw: {'text-wrap': 'balance'},
      ),
    ]),
  ];
}
