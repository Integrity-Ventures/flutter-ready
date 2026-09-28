import 'plugin_discovery.dart';

const _swiftPmTag = 'is:swiftpm-plugin';
const _archiveDirs = ['ios', 'macos', 'darwin'];

/// Whether a plugin is ready for Swift Package Manager, per two independent
/// signals (SPEC §3.1.2): pub.dev's own score tag, and the package's own
/// archive.
class SwiftPmReadiness {
  const SwiftPmReadiness({
    required this.tagSaysReady,
    required this.archiveSaysReady,
  });

  /// The pub.dev score endpoint's `is:swiftpm-plugin` tag.
  final bool tagSaysReady;

  /// Whether the archive contains a `ios/`, `macos/` or `darwin/` `Package.swift`
  /// for this plugin.
  final bool archiveSaysReady;

  /// False when the tag and the archive disagree — Flutter's own tooling
  /// misreports this for some plugins (flutter/flutter#187330).
  bool get agrees => tagSaysReady == archiveSaysReady;
}

/// Checks [candidate] for SwiftPM readiness, using its already-fetched score
/// tags and the entry paths of its own package archive.
SwiftPmReadiness checkSwiftPmReadiness(
  PluginCandidate candidate,
  List<String> archiveEntryPaths,
) {
  final packageSwiftPath = '/${candidate.name}/Package.swift';
  final archiveSaysReady = _archiveDirs.any(
    (dir) => archiveEntryPaths.contains('$dir$packageSwiftPath'),
  );
  return SwiftPmReadiness(
    tagSaysReady: candidate.hasTag(_swiftPmTag),
    archiveSaysReady: archiveSaysReady,
  );
}
