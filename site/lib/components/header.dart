import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/theme.dart';

/// The slim, page-independent top bar: the HireFlutter.dev wordmark and the
/// "Powered by 10xs" pill, in one ~56px row on every page. The page title
/// and its one-line explanation are NOT here — they differ per page (the
/// board's data headline vs. a plugin's question), so they live in [Hero]
/// inside each page instead (the "calmer header" rework, SPEC-adjacent
/// owner request 2026-09-28: "the header seems too cluttered").
class Header extends StatelessComponent {
  const Header({super.key});

  @override
  Component build(BuildContext context) {
    return header(classes: 'top-bar', [
      a(href: 'https://hireflutter.dev/', classes: 'brand-wordmark', [.text('HireFlutter.dev')]),
      span(classes: 'powered-pill', [.text('Powered by 10xs')]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.top-bar', [
      css('&').styles(
        display: .flex,
        padding: .symmetric(vertical: 0.85.em, horizontal: 1.em),
        border: .only(
          bottom: BorderSide.solid(color: borderSubtle, width: 1.px),
        ),
        justifyContent: .spaceBetween,
        alignItems: .center,
        backgroundColor: surfaceCard,
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
    ]),
  ];
}
