import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/status_colors.dart';
import '../data/grading.dart';

/// A pill with a coloured background plus a text label, never colour alone
/// (dataviz status palette rule): the label always carries the meaning, the
/// tint is a hint. Foreground/background pairs come from `status_colors.dart`
/// and are chosen to clear WCAG AA together.
class StatusChip extends StatelessComponent {
  const StatusChip({required this.status, super.key});

  final Status status;

  @override
  Component build(BuildContext context) {
    return span(
      classes: 'status-chip',
      styles: Styles(color: colorForStatus(status), backgroundColor: bgColorForStatus(status)),
      [.text(labelForStatus(status))],
    );
  }

  @css
  static List<StyleRule> get styles => [
    css('.status-chip').styles(
      display: .inlineBlock,
      padding: .symmetric(vertical: 0.2.em, horizontal: 0.7.em),
      radius: .all(.circular(999.px)),
      fontSize: 0.8.rem,
      fontWeight: .w600,
    ),
  ];
}
