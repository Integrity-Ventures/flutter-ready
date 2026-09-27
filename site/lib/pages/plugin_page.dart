import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../components/hireflutter_cta.dart';
import '../components/status_chip.dart';
import '../constants/status_colors.dart';
import '../constants/theme.dart';
import '../data/grading.dart';
import '../data/models.dart';

/// One page per plugin at `/p/<name>`, individually searchable (SPEC §2,
/// §3.2: "so a search like 'is plugin X SwiftPM ready' can find it"). [plugin]
/// comes from the snapshot [App] already loaded to build every plugin route.
class PluginPage extends StatelessComponent {
  const PluginPage({required this.plugin, super.key});

  final PluginEntry plugin;

  @override
  Component build(BuildContext context) {
    final swiftPm = swiftPmStatus(plugin);
    final alignment = alignmentStatus(plugin);

    return section(classes: 'plugin-page', [
      Document.head(meta: {'description': '${swiftPmEvidence(plugin)} ${alignmentEvidence(plugin)}'}),
      Link(to: '/', child: .text('← Back to the board')),
      h1([.text(plugin.name)]),
      p(classes: 'meta', [
        .text('Version ${plugin.version}. '),
        a(
          href: plugin.pubDevUrl,
          target: .blank,
          attributes: {'rel': 'noopener noreferrer'},
          [
            .text('View on pub.dev'),
          ],
        ),
      ]),
      if (isBlocked(plugin)) const HireFlutterCta(),
      if (plugin.errors.isNotEmpty)
        section(classes: 'errors', [
          h2([.text('Could not be fully checked')]),
          ul([
            for (final error in plugin.errors) li([.text(error)]),
          ]),
        ]),
      section(classes: 'evidence-section', [
        h2([StatusChip(status: swiftPm), .text(' SwiftPM (CocoaPods goes read-only 2 December 2026)')]),
        p([.text(swiftPmEvidence(plugin))]),
        ul([
          li([.text('pub.dev is:swiftpm-plugin tag: ${plugin.swiftpm.tag ?? 'unknown'}')]),
          li([.text('Package.swift in archive: ${plugin.swiftpm.archive ?? 'unknown'}')]),
          if (plugin.swiftpm.checkedPackage != null) li([.text('Checked package: ${plugin.swiftpm.checkedPackage}')]),
        ]),
        if (plugin.swiftpm.agrees == false)
          p(classes: 'note', [
            .text(
              'The tag and the archive disagree. Flutter\'s tooling misreports this for some plugins '
              '(flutter/flutter#187330).',
            ),
          ]),
      ]),
      section(classes: 'evidence-section', [
        h2([StatusChip(status: alignment), .text(' 16 KB native library alignment')]),
        p([.text(alignmentEvidence(plugin))]),
        if (plugin.alignment.soFiles.isNotEmpty)
          ul([
            for (final file in plugin.alignment.soFiles)
              li([
                .text(
                  '${file.path}: ${file.aligned ? 'aligned' : 'misaligned'}'
                  '${file.minAlign != null ? ' (0x${file.minAlign!.toRadixString(16)})' : ''}',
                ),
              ]),
          ]),
      ]),
      section(classes: 'evidence-section', [
        h2([.text('Android build settings (facts only)')]),
        p(classes: 'note', [
          .text('What these mean for an app targeting API 36 is unresolved (SPEC open decision 3) — no colour yet.'),
        ]),
        ul([
          li([.text('compileSdk: ${plugin.android.compileSdk ?? 'not found'}')]),
          li([.text('Android Gradle Plugin: ${plugin.android.agp ?? 'not found'}')]),
          li([.text('NDK: ${plugin.android.ndk ?? 'not found'}')]),
        ]),
      ]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.plugin-page', [
      css('&').styles(
        maxWidth: 42.rem,
        padding: .symmetric(vertical: 2.em, horizontal: 1.em),
        margin: .symmetric(horizontal: .auto),
      ),
      css('a').styles(color: brandBlue, fontWeight: .w600),
      css('h1').styles(color: brandNavy),
      css('.meta').styles(color: textMuted),
      css('.evidence-section').styles(margin: .only(top: 1.5.em)),
      css('.note').styles(color: textMuted, fontSize: 0.9.rem),
      css('.errors').styles(color: statusRed),
    ]),
  ];
}
