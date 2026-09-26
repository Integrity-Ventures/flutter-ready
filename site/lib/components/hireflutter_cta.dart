import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/status_colors.dart';

/// The call to action a red row or red plugin page carries (SPEC §2, §3.2):
/// "Blocked by this plugin? A HireFlutter developer can migrate or fork it."
class HireFlutterCta extends StatelessComponent {
  const HireFlutterCta({super.key});

  @override
  Component build(BuildContext context) {
    return p(classes: 'hireflutter-cta', [
      .text('Blocked by this plugin? A '),
      a(
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
        padding: .symmetric(vertical: 0.5.em, horizontal: 0.8.em),
        margin: .only(top: 0.4.em),
        border: .all(color: statusRed, width: 1.px),
        radius: .all(.circular(4.px)),
        color: statusRed,
        fontSize: 0.85.rem,
      ),
      css('a').styles(color: statusRed, fontWeight: FontWeight.bold),
    ]),
  ];
}
