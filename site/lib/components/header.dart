import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../constants/theme.dart';

class Header extends StatelessComponent {
  const Header({super.key});

  @override
  Component build(BuildContext context) {
    return header([
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
        flexDirection: .column,
        alignItems: .center,
        textAlign: .center,
      ),
      css('h1').styles(margin: .zero, color: primaryColor, fontSize: 2.2.rem),
      css('a').styles(textDecoration: TextDecoration(line: .none)),
      css('.tagline').styles(
        maxWidth: 40.rem,
        margin: .only(top: 0.5.em),
        color: const Color('#52514e'),
      ),
    ]),
  ];
}
