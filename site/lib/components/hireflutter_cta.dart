import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/status_colors.dart';
import '../constants/theme.dart';

/// The call to action a red row or red plugin page carries (SPEC §2, §3.2):
/// "Blocked by this plugin? A HireFlutter developer can migrate or fork it."
/// The link itself renders as a button, not a bare underlined link.
class HireFlutterCta extends StatelessComponent {
  const HireFlutterCta({super.key});

  @override
  Component build(BuildContext context) {
    return p(classes: 'hireflutter-cta', [
      .text('Blocked by this plugin? A '),
      a(
        classes: 'hireflutter-cta-button',
        href: 'https://hireflutter.dev',
        target: .blank,
        attributes: {'rel': 'noopener noreferrer'},
        [.text('HireFlutter developer')],
      ),
      .text(' can migrate or fork it.'),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.hireflutter-cta', [
      css('&').styles(
        padding: .symmetric(vertical: 0.6.em, horizontal: 0.9.em),
        margin: .only(top: 0.4.em),
        radius: .all(.circular(8.px)),
        color: statusRed,
        fontSize: 0.85.rem,
        backgroundColor: statusRedBg,
      ),
      // Nested (rather than a top-level `.hireflutter-cta-button` rule) so
      // this wins specificity over any page-level `a` color/underline reset.
      css('.hireflutter-cta-button', [
        css('&').styles(
          display: .inlineBlock,
          padding: .symmetric(vertical: 0.15.em, horizontal: 0.6.em),
          margin: .only(left: 0.15.em),
          radius: .all(.circular(999.px)),
          color: surfaceCard,
          fontWeight: .w600,
          textDecoration: TextDecoration(line: .none),
          backgroundColor: brandBlue,
        ),
        css('&:hover').styles(backgroundColor: brandBlueDark),
      ]),
    ]),
  ];
}
