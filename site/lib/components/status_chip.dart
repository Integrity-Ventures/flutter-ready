import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/status_colors.dart';
import '../data/grading.dart';

/// A coloured dot plus a text label, never colour alone (dataviz status
/// palette rule): the label always carries the meaning, the dot is a hint.
class StatusChip extends StatelessComponent {
  const StatusChip({required this.status, super.key});

  final Status status;

  @override
  Component build(BuildContext context) {
    return span(classes: 'status-chip', [
      span(
        classes: 'status-chip-dot',
        styles: Styles(backgroundColor: colorForStatus(status)),
        [],
      ),
      .text(labelForStatus(status)),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.status-chip', [
      css('&').styles(display: .inlineFlex, alignItems: .center, gap: .all(0.4.em)),
    ]),
    css('.status-chip-dot').styles(
      display: .inlineBlock,
      width: 8.px,
      height: 8.px,
      radius: .all(.circular(4.px)),
    ),
  ];
}
