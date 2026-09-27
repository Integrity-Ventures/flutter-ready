import 'package:readiness_check/readiness_check.dart';

/// The top-level snapshot document (architect snapshot contract,
/// `schemaVersion` 1): one dated JSON file per nightly run.
Map<String, dynamic> buildSnapshotJson({
  required DateTime generatedAt,
  required int topN,
  required List<PluginSnapshot> plugins,
}) {
  return {
    'schemaVersion': 1,
    'generatedAt': generatedAt.toIso8601String(),
    'topN': topN,
    'plugins': [for (final plugin in plugins) plugin.toJson()],
  };
}

/// One plugin's readiness facts for a single snapshot (SPEC §3.1.2-3).
///
/// A field is null when its check couldn't run for this plugin — the
/// reason is recorded in [errors] — never omitted, so every plugin document
/// has the same shape.
class PluginSnapshot {
  const PluginSnapshot({
    required this.name,
    required this.version,
    required this.published,
    required this.downloadCount30Days,
    required this.likeCount,
    required this.swiftpm,
    required this.alignment,
    required this.android,
    required this.errors,
  });

  final String name;
  final String? version;
  final DateTime? published;
  final int? downloadCount30Days;
  final int? likeCount;
  final SwiftPmSnapshot? swiftpm;
  final AlignmentSnapshot? alignment;
  final AndroidSnapshot? android;

  /// One message per failed check. A failure here never aborts the run.
  final List<String> errors;

  Map<String, dynamic> toJson() => {
    'name': name,
    'version': version,
    'published': published?.toIso8601String(),
    'downloadCount30Days': downloadCount30Days,
    'likeCount': likeCount,
    'swiftpm': swiftpm?.toJson(),
    'alignment': alignment?.toJson(),
    'android': android?.toJson(),
    'errors': errors,
  };
}

/// SwiftPM readiness (SPEC §3.1.2), checked against [checkedPackage]'s
/// archive — the federated platform package when the plugin is federated,
/// otherwise the plugin's own package.
class SwiftPmSnapshot {
  const SwiftPmSnapshot({
    required this.checkedPackage,
    required this.readiness,
    required this.nativeIos,
  });

  final String checkedPackage;
  final SwiftPmReadiness readiness;

  /// Whether [checkedPackage] ships native iOS code at all (SPEC e2-s1
  /// rework) — false means it's nothing but a Dart-only implementation, so
  /// the CocoaPods deadline can't block it regardless of [readiness].
  final bool nativeIos;

  Map<String, dynamic> toJson() => {
    'tag': readiness.tagSaysReady,
    'archive': readiness.archiveSaysReady,
    'agrees': readiness.agrees,
    'checkedPackage': checkedPackage,
    'nativeIos': nativeIos,
  };
}

/// 16 KB native-library alignment (SPEC §3.1.2), checked against
/// [checkedPackage]'s archive. An empty [soFiles] means the archive has no
/// `.so` files, not that the check failed.
class AlignmentSnapshot {
  const AlignmentSnapshot({
    required this.checkedPackage,
    required this.soFiles,
  });

  final String checkedPackage;
  final List<ElfAlignmentResult> soFiles;

  Map<String, dynamic> toJson() => {
    'checkedPackage': checkedPackage,
    'soFiles': [
      for (final soFile in soFiles)
        {
          'path': soFile.path,
          'aligned': soFile.aligned,
          'minAlign': soFile.minLoadSegmentAlignment,
        },
    ],
  };
}

/// Android build settings (SPEC §3.1.2), checked against [checkedPackage]'s
/// archive. Facts only, per SPEC open decision 3 — no colour is attached.
class AndroidSnapshot {
  const AndroidSnapshot({required this.checkedPackage, required this.settings});

  final String checkedPackage;

  /// Null when [checkedPackage]'s archive has neither Gradle file.
  final AndroidBuildSettings? settings;

  Map<String, dynamic> toJson() => {
    'checkedPackage': checkedPackage,
    'compileSdk': settings?.compileSdk,
    'agp': settings?.agpVersion,
    'ndk': settings?.ndkVersion,
  };
}
