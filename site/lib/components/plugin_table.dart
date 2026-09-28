import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../constants/theme.dart';
import '../data/board.dart';
import '../data/grading.dart';
import 'hireflutter_cta.dart';
import 'status_chip.dart';

/// One row per plugin, red rows first (SPEC: "reds on top"), downloads
/// descending within each group. Android settings are shown as facts only —
/// there is no colour rule for them yet (SPEC open decision 3).
class PluginTable extends StatelessComponent {
  const PluginTable({required this.rows, super.key});

  final List<BoardRow> rows;

  @override
  Component build(BuildContext context) {
    final anyNeedsAttention = rows.any((r) => r.needsAttention);

    return div([
      div(classes: 'attention-toggle', [
        label([
          input(type: InputType.checkbox, id: 'attention-toggle-input'),
          .text(' Show only plugins that need attention'),
        ]),
      ]),
      div(classes: 'table-scroll', [
        table(classes: 'plugin-table', id: 'plugin-table', [
          thead([
            tr([
              th([.text('#')]),
              th([.text('Plugin')]),
              th([.text('Downloads (30d)')]),
              th([.text('Version')]),
              th([.text('SwiftPM (CocoaPods read-only 2 Dec 2026)')]),
              th([.text('16 KB alignment')]),
              th([.text('Android (facts only)')]),
            ]),
          ]),
          tbody([for (final row in rows) ..._rows(row)]),
        ]),
      ]),
      if (anyNeedsAttention) _toggleScript(),
    ]);
  }

  List<Component> _rows(BoardRow row) {
    final plugin = row.plugin;
    final android = plugin.android;
    final androidFacts = [
      if (android.compileSdk != null) 'compileSdk ${android.compileSdk}',
      if (android.agp != null) 'AGP ${android.agp}',
      if (android.ndk != null) 'NDK ${android.ndk}',
    ];
    final attention = row.needsAttention ? 'true' : 'false';

    return [
      tr(
        attributes: {'data-attention': attention},
        [
          td([.text('${row.downloadRank}')]),
          td([Link(to: '/p/${plugin.name}', child: .text(plugin.name))]),
          td([.text(formatDownloads(plugin.downloadCount30Days))]),
          td([.text(plugin.version)]),
          td(classes: 'evidence-cell', [
            StatusChip(status: swiftPmStatus(plugin), nativeIos: plugin.swiftpm.nativeIos),
            p(classes: 'evidence', [.text(swiftPmEvidence(plugin))]),
          ]),
          td(classes: 'evidence-cell', [
            StatusChip(status: alignmentStatus(plugin)),
            p(classes: 'evidence', [.text(alignmentEvidence(plugin))]),
          ]),
          td([.text(androidFacts.isEmpty ? '—' : androidFacts.join(', '))]),
        ],
      ),
      if (isBlocked(plugin))
        tr(
          attributes: {'data-attention': attention},
          classes: 'cta-row',
          [
            td(attributes: {'colspan': '7'}, [const HireFlutterCta()]),
          ],
        ),
    ];
  }

  /// A plain inline script, not a hydrated `@client` component: without it
  /// (or with JS disabled) every row renders in the static HTML above, so
  /// "without JS, all rows show" holds by construction. With JS, it defaults
  /// the toggle on (SPEC: "on by default when that set isn't empty") and
  /// hides the rows that don't need attention.
  Component _toggleScript() {
    return script(
      content: '''
(function () {
  var checkbox = document.getElementById('attention-toggle-input');
  var rows = document.querySelectorAll('#plugin-table tbody tr');
  function apply() {
    rows.forEach(function (row) {
      var hide = checkbox.checked && row.getAttribute('data-attention') === 'false';
      row.style.display = hide ? 'none' : '';
    });
  }
  checkbox.addEventListener('change', apply);
  checkbox.checked = true;
  apply();
})();
''',
    );
  }

  @css
  static List<StyleRule> get styles => [
    css('.attention-toggle').styles(margin: .only(bottom: 1.em)),
    css('.table-scroll').styles(
      border: Border.all(color: borderSubtle, width: 1.px),
      radius: .all(.circular(12.px)),
      overflow: Overflow.only(x: Overflow.auto),
      backgroundColor: surfaceCard,
    ),
    css('.plugin-table', [
      css('&').styles(width: 100.percent, fontSize: 0.95.rem),
      css('th, td').styles(
        padding: .symmetric(vertical: 0.6.em, horizontal: 0.8.em),
        textAlign: .left,
      ),
      css('thead th').styles(
        border: .only(
          bottom: BorderSide.solid(color: borderSubtle, width: 2.px),
        ),
        color: textMuted,
        fontSize: 0.8.rem,
        textTransform: .upperCase,
      ),
      css('tbody tr', [
        css('&').styles(
          border: .only(
            bottom: BorderSide.solid(color: borderSubtle, width: 1.px),
          ),
        ),
      ]),
      css('.evidence').styles(
        margin: .only(top: 0.2.em),
        color: textMuted,
        fontSize: 0.82.rem,
      ),
    ]),
  ];
}
