import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../constants/status_colors.dart';
import '../data/board.dart';
import '../data/grading.dart';

/// A pill with a coloured background plus a text label, never colour alone
/// (dataviz status palette rule): the label always carries the meaning, the
/// tint is a hint. Colours come from `status_colors.dart`'s [Status] pair;
/// the label comes from [categoryForStatus] — the same rule the board tiles
/// use — so a green "not affected" result never says "Ready" here while
/// counting as "Not affected" on the tiles. [nativeIos] is only meaningful
/// for the SwiftPM check; leave it null for a check with no "not affected"
/// case (alignment), where a green status always reads "Ready".
class StatusChip extends StatelessComponent {
  const StatusChip({required this.status, this.nativeIos, super.key});

  final Status status;
  final bool? nativeIos;

  @override
  Component build(BuildContext context) {
    final category = categoryForStatus(status, nativeIos: nativeIos);
    return span(
      classes: 'status-chip',
      styles: Styles(color: colorForStatus(status), backgroundColor: bgColorForStatus(status)),
      [.text(labelForCategory(category))],
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
