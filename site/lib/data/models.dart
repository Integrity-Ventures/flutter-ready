/// Data model for the readiness snapshot contract (schemaVersion 1), shared
/// between this board and the `snapshot_job` package. Kept as a plain,
/// dependency-free parser of the JSON shape documented in
/// `10xs/workflow/instructions/20260927_05_architect-notes-e2-e6.md`.
class SwiftPmInfo {
  const SwiftPmInfo({required this.tag, required this.archive, required this.agrees, required this.checkedPackage});

  factory SwiftPmInfo.fromJson(Map<String, dynamic> json) => SwiftPmInfo(
    tag: json['tag'] as bool?,
    archive: json['archive'] as bool?,
    agrees: json['agrees'] as bool?,
    checkedPackage: json['checkedPackage'] as String?,
  );

  final bool? tag;
  final bool? archive;
  final bool? agrees;
  final String? checkedPackage;
}

class SoFile {
  const SoFile({required this.path, required this.aligned, required this.minAlign});

  factory SoFile.fromJson(Map<String, dynamic> json) =>
      SoFile(path: json['path'] as String, aligned: json['aligned'] as bool, minAlign: json['minAlign'] as int?);

  final String path;
  final bool aligned;
  final int? minAlign;
}

class AlignmentInfo {
  const AlignmentInfo({required this.checkedPackage, required this.soFiles});

  factory AlignmentInfo.fromJson(Map<String, dynamic> json) => AlignmentInfo(
    checkedPackage: json['checkedPackage'] as String?,
    soFiles: [for (final f in (json['soFiles'] as List)) SoFile.fromJson(f as Map<String, dynamic>)],
  );

  final String? checkedPackage;
  final List<SoFile> soFiles;
}

class AndroidInfo {
  const AndroidInfo({required this.checkedPackage, required this.compileSdk, required this.agp, required this.ndk});

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
  });

  factory PluginEntry.fromJson(Map<String, dynamic> json) => PluginEntry(
    name: json['name'] as String,
    version: json['version'] as String,
    published: json['published'] as String?,
    downloadCount30Days: json['downloadCount30Days'] as int?,
    likeCount: json['likeCount'] as int?,
    swiftpm: SwiftPmInfo.fromJson(json['swiftpm'] as Map<String, dynamic>),
    alignment: AlignmentInfo.fromJson(json['alignment'] as Map<String, dynamic>),
    android: AndroidInfo.fromJson(json['android'] as Map<String, dynamic>),
    errors: [for (final e in (json['errors'] as List)) e as String],
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

  String get pubDevUrl => 'https://pub.dev/packages/$name';
}

class Snapshot {
  const Snapshot({required this.schemaVersion, required this.generatedAt, required this.topN, required this.plugins});

  factory Snapshot.fromJson(Map<String, dynamic> json) => Snapshot(
    schemaVersion: json['schemaVersion'] as int,
    generatedAt: json['generatedAt'] as String,
    topN: json['topN'] as int,
    plugins: [for (final p in (json['plugins'] as List)) PluginEntry.fromJson(p as Map<String, dynamic>)],
  );

  final int schemaVersion;
  final String generatedAt;
  final int topN;
  final List<PluginEntry> plugins;
}

/// One dated snapshot, tagged with the UTC date taken from its filename
/// (`data/snapshots/<YYYY-MM-DD>.json`), for building the trend view.
class DatedSnapshot {
  const DatedSnapshot({required this.date, required this.snapshot});

  final String date;
  final Snapshot snapshot;
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
