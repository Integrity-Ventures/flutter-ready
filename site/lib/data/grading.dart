import 'models.dart';

/// Colour rules are an architect decision, recorded in
/// `10xs/workflow/instructions/20260927_05_architect-notes-e2-e6.md`
/// (section "e3-s1: Board rendering"). Android has no colour rule
/// (SPEC open decision 3): it is shown as facts only.
enum Status { green, amber, red, notChecked }

Status swiftPmStatus(PluginEntry plugin) {
  if (plugin.errors.isNotEmpty) return Status.notChecked;
  final tag = plugin.swiftpm.tag;
  final archive = plugin.swiftpm.archive;
  if (tag == null || archive == null) return Status.notChecked;
  if (tag && archive) return Status.green;
  if (tag != archive) return Status.amber;
  return Status.red;
}

Status alignmentStatus(PluginEntry plugin) {
  if (plugin.errors.isNotEmpty) return Status.notChecked;
  if (plugin.alignment.soFiles.isEmpty) return Status.green;
  final misaligned = plugin.alignment.soFiles.where((f) => !f.aligned);
  return misaligned.isEmpty ? Status.green : Status.red;
}

/// A one-line summary of the evidence behind [swiftPmStatus] (SPEC §3.2: "shows
/// the evidence behind its colour").
String swiftPmEvidence(PluginEntry plugin) {
  if (plugin.errors.isNotEmpty) return 'Could not be checked.';
  final tag = plugin.swiftpm.tag;
  final archive = plugin.swiftpm.archive;
  final checkedPackage = plugin.swiftpm.checkedPackage ?? plugin.name;
  if (tag == null || archive == null) return 'Could not be checked.';
  if (tag == archive) {
    return archive
        ? 'Package.swift found in the $checkedPackage archive.'
        : 'No Package.swift in the $checkedPackage archive.';
  }
  return 'pub.dev tag ($tag) disagrees with the $checkedPackage archive ($archive).';
}

/// A one-line summary of the evidence behind [alignmentStatus].
String alignmentEvidence(PluginEntry plugin) {
  if (plugin.errors.isNotEmpty) return 'Could not be checked.';
  final soFiles = plugin.alignment.soFiles;
  if (soFiles.isEmpty) return 'No native libraries in archive.';
  final misaligned = soFiles.where((f) => !f.aligned).toList();
  if (misaligned.isEmpty) return '${soFiles.length} .so file(s), all 16 KB aligned.';
  final first = misaligned.first;
  final align = first.minAlign != null ? '0x${first.minAlign!.toRadixString(16)}' : 'unknown';
  return '${misaligned.length} of ${soFiles.length} .so file(s) misaligned, e.g. ${first.path} ($align).';
}

/// Whether [plugin] carries the HireFlutter call to action: any red status
/// blocks a release, whether from SwiftPM or 16 KB alignment (SPEC §2, §3.2).
bool isBlocked(PluginEntry plugin) => swiftPmStatus(plugin) == Status.red || alignmentStatus(plugin) == Status.red;

/// Share of plugins with a known SwiftPM status (green/amber/red — excludes
/// "not checked") that are fully SwiftPM-ready, as a whole percent. Used for
/// the trend view (SPEC §3.2: "trend over time ... share of top plugins that
/// ship SwiftPM"). Returns `null` when no plugin in [plugins] has a known status.
int? swiftPmGreenSharePercent(List<PluginEntry> plugins) {
  final known = plugins.where((p) => swiftPmStatus(p) != Status.notChecked).toList();
  if (known.isEmpty) return null;
  final green = known.where((p) => swiftPmStatus(p) == Status.green);
  return (green.length / known.length * 100).round();
}
