import 'elf_alignment_check.dart';
import 'grading.dart';
import 'ios_resolution.dart';
import 'package_archive.dart';
import 'plugin_discovery.dart';
import 'pub_dev_client.dart';
import 'swiftpm_check.dart';

/// The SwiftPM and 16 KB alignment grade for a plugin the Flutter Ready
/// data doesn't cover (CLI live-check task, 2026-09-27), computed on the
/// spot from its already-downloaded archive alone. Pub.dev's score tags
/// can't be fetched for a historical version, so — unlike [swiftPmStatus] —
/// this never returns [Status.amber].
class LiveGrade {
  const LiveGrade({
    required this.swiftPm,
    required this.swiftPmEvidence,
    required this.alignment,
    required this.alignmentEvidence,
  });

  final Status swiftPm;
  final String swiftPmEvidence;
  final Status alignment;
  final String alignmentEvidence;
}

/// Grades [archiveBytes] — the resolved iOS package's archive, at its exact
/// locked (or, failing that, latest) version — for both checks the nightly
/// snapshot runs: SwiftPM readiness ([resolveNativeIos] plus
/// [checkSwiftPmReadiness]'s archive signal) and `.so` alignment
/// ([checkSoAlignment]).
LiveGrade gradeLivePlugin({
  required PackageInfo? appInfo,
  required IosResolution resolution,
  required PackageInfo? resolvedInfo,
  required List<int> archiveBytes,
}) {
  final entryPaths = listArchiveEntryPaths(archiveBytes);
  final native = resolveNativeIos(appInfo, resolution, resolvedInfo, entryPaths);

  final Status swiftPm;
  final String swiftPmEvidence;
  if (!native.nativeIos) {
    swiftPm = Status.green;
    swiftPmEvidence = native.reason == 'not-ios-plugin'
        ? 'Not affected: not an iOS plugin.'
        : 'Not affected: no native iOS code.';
  } else {
    final ready = checkSwiftPmReadiness(
      PluginCandidate(name: resolution.checkedPackage, tags: const []),
      entryPaths,
    ).archiveSaysReady;
    swiftPm = ready ? Status.green : Status.red;
    swiftPmEvidence = ready
        ? 'Package.swift found in the ${resolution.checkedPackage} archive.'
        : 'No Package.swift in the ${resolution.checkedPackage} archive.';
  }

  final soFiles = <ElfAlignmentResult>[];
  for (final entry in extractArchiveEntries(archiveBytes, isSharedLibraryPath).entries) {
    try {
      soFiles.add(checkSoAlignment(entry.key, entry.value));
    } on NotElfException {
      // Not actually an ELF file despite the .so extension — no alignment
      // evidence for it, and it never blocks on its own.
    }
  }
  final misaligned = soFiles.where((f) => !f.aligned).toList();
  final alignment = misaligned.isEmpty ? Status.green : Status.red;
  final alignmentEvidence = soFiles.isEmpty
      ? 'No native libraries in archive.'
      : misaligned.isEmpty
          ? '${soFiles.length} .so file(s), all 16 KB aligned.'
          : '${misaligned.length} of ${soFiles.length} .so file(s) misaligned, e.g. ${misaligned.first.path}.';

  return LiveGrade(
    swiftPm: swiftPm,
    swiftPmEvidence: swiftPmEvidence,
    alignment: alignment,
    alignmentEvidence: alignmentEvidence,
  );
}
