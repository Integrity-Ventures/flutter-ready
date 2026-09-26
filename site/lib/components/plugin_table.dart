import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../data/grading.dart';
import '../data/models.dart';
import 'hireflutter_cta.dart';
import 'status_chip.dart';

/// One row per plugin, red/amber/green for SwiftPM and 16 KB alignment, with
/// the evidence behind each colour (SPEC §3.2). Android settings are shown
/// as facts only — there is no colour rule for them yet (SPEC open decision 3).
class PluginTable extends StatelessComponent {
  const PluginTable({required this.plugins, super.key});

  final List<PluginEntry> plugins;

  @override
  Component build(BuildContext context) {
    return table(classes: 'plugin-table', [
      thead([
        tr([
          th([.text('Plugin')]),
          th([.text('Version')]),
          th([.text('SwiftPM (CocoaPods read-only 2 Dec 2026)')]),
          th([.text('16 KB alignment')]),
          th([.text('Android (facts only)')]),
        ]),
      ]),
      tbody([for (final plugin in plugins) ..._rows(plugin)]),
    ]);
  }

  List<Component> _rows(PluginEntry plugin) {
    final android = plugin.android;
    final androidFacts = [
      if (android.compileSdk != null) 'compileSdk ${android.compileSdk}',
      if (android.agp != null) 'AGP ${android.agp}',
      if (android.ndk != null) 'NDK ${android.ndk}',
    ];

    return [
      tr([
        td([Link(to: '/p/${plugin.name}', child: .text(plugin.name))]),
        td([.text(plugin.version)]),
        td(classes: 'evidence-cell', [
          StatusChip(status: swiftPmStatus(plugin)),
          p(classes: 'evidence', [.text(swiftPmEvidence(plugin))]),
        ]),
        td(classes: 'evidence-cell', [
          StatusChip(status: alignmentStatus(plugin)),
          p(classes: 'evidence', [.text(alignmentEvidence(plugin))]),
        ]),
        td([.text(androidFacts.isEmpty ? '—' : androidFacts.join(', '))]),
      ]),
      if (isBlocked(plugin))
        tr(classes: 'cta-row', [
          td(attributes: {'colspan': '5'}, [const HireFlutterCta()]),
        ]),
    ];
  }

  @css
  static List<StyleRule> get styles => [
    css('.plugin-table', [
      css('&').styles(width: 100.percent, fontSize: 0.95.rem),
      css('th, td').styles(
        padding: .symmetric(vertical: 0.6.em, horizontal: 0.8.em),
        textAlign: .left,
      ),
      css('thead th').styles(
        border: .only(
          bottom: BorderSide.solid(color: const Color('#dcdbd4'), width: 2.px),
        ),
        color: const Color('#52514e'),
        fontSize: 0.8.rem,
        textTransform: .upperCase,
      ),
      css('tbody tr', [
        css('&').styles(
          border: .only(
            bottom: BorderSide.solid(color: const Color('#eeede8'), width: 1.px),
          ),
        ),
      ]),
      css('.evidence').styles(
        margin: .only(top: 0.2.em),
        color: const Color('#898781'),
        fontSize: 0.82.rem,
      ),
    ]),
  ];
}
