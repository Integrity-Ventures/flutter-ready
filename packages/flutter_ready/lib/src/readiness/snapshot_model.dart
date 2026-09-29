/// Data model for the readiness snapshot contract (schemaVersion 1), shared
/// between the board (`site`) and the CLI (`flutter_ready`), so the two
/// can't disagree (SPEC §2). Kept as a plain, dependency-free parser of the
/// JSON shape documented in
/// `10xs/workflow/instructions/20260927_05_architect-notes-e2-e6.md`.
class SwiftPmInfo {
  const SwiftPmInfo({
    required this.tag,
    required this.archive,
    required this.agrees,
    required this.checkedPackage,
    this.nativeIos,
    this.reason,
  });

  factory SwiftPmInfo.fromJson(Map<String, dynamic> json) => SwiftPmInfo(
    tag: json['tag'] as bool?,
    archive: json['archive'] as bool?,
    agrees: json['agrees'] as bool?,
    checkedPackage: json['checkedPackage'] as String?,
    nativeIos: json['nativeIos'] as bool?,
    reason: json['reason'] as String?,
  );

  final bool? tag;
  final bool? archive;
  final bool? agrees;
  final String? checkedPackage;

  /// Null for snapshots taken before this field existed (additive,
  /// `schemaVersion` stays 1) — grading treats that the same as `true`.
  /// False means the resolved package ships no native iOS code at all.
  final bool? nativeIos;

  /// Set only when [nativeIos] is false: `not-ios-plugin` (the app-facing
  /// pubspec declares no `ios`/`macos` platform at all) or
  /// `no-native-ios-code` (the platform is declared but is Dart-only). Null
  /// for snapshots taken before this field existed, or when [nativeIos]
  /// isn't false.
  final String? reason;
}

class SoFile {
  const SoFile({
    required this.path,
    required this.aligned,
    required this.minAlign,
  });

  factory SoFile.fromJson(Map<String, dynamic> json) => SoFile(
    path: json['path'] as String,
    aligned: json['aligned'] as bool,
    minAlign: json['minAlign'] as int?,
  );

  final String path;
  final bool aligned;
  final int? minAlign;
}

class AlignmentInfo {
  const AlignmentInfo({required this.checkedPackage, required this.soFiles});

  factory AlignmentInfo.fromJson(Map<String, dynamic> json) => AlignmentInfo(
    checkedPackage: json['checkedPackage'] as String?,
    soFiles: [
      for (final f in (json['soFiles'] as List))
        SoFile.fromJson(f as Map<String, dynamic>),
    ],
  );

  final String? checkedPackage;
  final List<SoFile> soFiles;
}

class AndroidInfo {
  const AndroidInfo({
    required this.checkedPackage,
    required this.compileSdk,
    required this.agp,
    required this.ndk,
  });

  factory AndroidInfo.fromJson(Map<String, dynamic> json) => AndroidInfo(
    checkedPackage: json['checkedPackage'] as String?,
    // Recorded verbatim from Gradle files: either a resolved int or raw source text (SPEC open decision 3).
    compileSdk: json['compileSdk'],
    agp: json['agp'] as String?,
    ndk: json['ndk'] as String?,
  );

  final String? checkedPackage;
  final Object? compileSdk;
  final String? agp;
  final String? ndk;
}

class PluginEntry {
  const PluginEntry({
    required this.name,
    required this.version,
    required this.published,
    required this.downloadCount30Days,
    required this.likeCount,
    required this.swiftpm,
    required this.alignment,
    required this.android,
    required this.errors,
    this.search = const [],
  });

  /// `swiftpm`/`alignment`/`android` are null in the JSON for a plugin whose
  /// checks couldn't run (SPEC §3.1.2-3: "never omitted" but null on
  /// failure) — parsed here as an all-null sentinel rather than a missing
  /// key, since [errors] (checked first by every grading function) is
  /// always non-empty whenever they're null.
  factory PluginEntry.fromJson(Map<String, dynamic> json) => PluginEntry(
    name: json['name'] as String,
    // Null in the JSON when the package-info fetch failed (recorded in
    // errors) — every caller displays this directly, so fall back to a
    // placeholder rather than widening the type to String?.
    version: json['version'] as String? ?? 'unknown',
    published: json['published'] as String?,
    downloadCount30Days: json['downloadCount30Days'] as int?,
    likeCount: json['likeCount'] as int?,
    swiftpm: json['swiftpm'] == null
        ? const SwiftPmInfo(
            tag: null,
            archive: null,
            agrees: null,
            checkedPackage: null,
          )
        : SwiftPmInfo.fromJson(json['swiftpm'] as Map<String, dynamic>),
    alignment: json['alignment'] == null
        ? const AlignmentInfo(checkedPackage: null, soFiles: [])
        : AlignmentInfo.fromJson(json['alignment'] as Map<String, dynamic>),
    android: json['android'] == null
        ? const AndroidInfo(
            checkedPackage: null,
            compileSdk: null,
            agp: null,
            ndk: null,
          )
        : AndroidInfo.fromJson(json['android'] as Map<String, dynamic>),
    errors: [for (final e in (json['errors'] as List)) e as String],
    // Null for snapshots taken before this field existed (additive,
    // schemaVersion stays 1).
    search: [
      for (final s in (json['search'] as List? ?? const [])) s as String,
    ],
  );

  final String name;
  final String version;
  final String? published;
  final int? downloadCount30Days;
  final int? likeCount;
  final SwiftPmInfo swiftpm;
  final AlignmentInfo alignment;
  final AndroidInfo android;
  final List<String> errors;

  /// Which pub.dev search(es) surfaced this plugin (SPEC §3.1.1), e.g.
  /// `["no-swiftpm", "top-downloads"]`. Empty for snapshots taken before
  /// this field existed.
  final List<String> search;

  String get pubDevUrl => 'https://pub.dev/packages/$name';
}

/// How discovery built the candidate set for this snapshot (SPEC §3.1.1,
/// 2026-09-27 owner-approved rework): pub.dev searches, sorted by downloads.
class DiscoveryInfo {
  const DiscoveryInfo({
    required this.method,
    required this.queries,
    required this.resultsPerQuery,
  });

  factory DiscoveryInfo.fromJson(Map<String, dynamic> json) => DiscoveryInfo(
    method: json['method'] as String,
    queries: [for (final q in (json['queries'] as List)) q as String],
    resultsPerQuery: json['resultsPerQuery'] as int,
  );

  final String method;
  final List<String> queries;
  final int resultsPerQuery;

  Map<String, dynamic> toJson() => {
    'method': method,
    'queries': queries,
    'resultsPerQuery': resultsPerQuery,
  };
}

class Snapshot {
  const Snapshot({
    required this.schemaVersion,
    required this.generatedAt,
    required this.discovery,
    required this.plugins,
  });

  factory Snapshot.fromJson(Map<String, dynamic> json) => Snapshot(
    schemaVersion: json['schemaVersion'] as int,
    generatedAt: json['generatedAt'] as String,
    discovery: DiscoveryInfo.fromJson(
      json['discovery'] as Map<String, dynamic>,
    ),
    plugins: [
      for (final p in (json['plugins'] as List))
        PluginEntry.fromJson(p as Map<String, dynamic>),
    ],
  );

  final int schemaVersion;
  final String generatedAt;
  final DiscoveryInfo discovery;
  final List<PluginEntry> plugins;
}

class Deadline {
  const Deadline({
    required this.id,
    required this.title,
    required this.date,
    required this.extendedDate,
    required this.source,
    required this.check,
  });

  factory Deadline.fromJson(Map<String, dynamic> json) => Deadline(
    id: json['id'] as String,
    title: json['title'] as String,
    date: json['date'] as String?,
    extendedDate: json['extendedDate'] as String?,
    source: json['source'] as String,
    check: json['check'] as String,
  );

  final String id;
  final String title;
  final String? date;
  final String? extendedDate;
  final String source;
  final String check;
}
