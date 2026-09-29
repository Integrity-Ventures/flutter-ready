import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown when a pub.dev API call does not return HTTP 200.
class PubDevApiException implements Exception {
  PubDevApiException(this.uri, this.statusCode);

  final Uri uri;
  final int statusCode;

  @override
  String toString() => 'PubDevApiException: $statusCode fetching $uri';
}

/// Thin wrapper around the two pub.dev endpoints the readiness checks need.
///
/// See SPEC.md §3.1.1: package-name-completion-data returns names "ordered by
/// overall ranking"; the score endpoint carries the tags used to identify
/// Flutter plugins and (in later checks) SwiftPM support.
class PubDevClient {
  PubDevClient({http.Client? httpClient, Uri? baseUri})
    : _httpClient = httpClient ?? http.Client(),
      _baseUri = baseUri ?? Uri.parse('https://pub.dev');

  final http.Client _httpClient;
  final Uri _baseUri;

  /// All package names known to pub.dev, ordered by overall ranking.
  Future<List<String>> fetchPackageNames() async {
    final uri = _baseUri.resolve('/api/package-name-completion-data');
    final body = await _getJson(uri);
    return (body['packages'] as List).cast<String>();
  }

  /// One page of `GET /api/search?q=<query>&sort=downloads&page=<page>`
  /// results (SPEC §3.1.1, 2026-09-27): 10 package names per page, and
  /// pub.dev rejects the query past page 10 (100 results per query).
  Future<List<String>> searchPackages(String query, {required int page}) async {
    final uri = _baseUri
        .resolve('/api/search')
        .replace(
          queryParameters: {'q': query, 'sort': 'downloads', 'page': '$page'},
        );
    final body = await _getJson(uri);
    return [
      for (final entry in body['packages'] as List)
        (entry as Map<String, dynamic>)['package'] as String,
    ];
  }

  /// Score tags for a single package, e.g. `sdk:flutter`, `platform:ios`.
  Future<List<String>> fetchPackageTags(String packageName) async {
    final uri = _baseUri.resolve('/api/packages/$packageName/score');
    final body = await _getJson(uri);
    return (body['tags'] as List? ?? const []).cast<String>();
  }

  /// The archive URL for a package's latest published version.
  Future<Uri> fetchLatestArchiveUrl(String packageName) async {
    final uri = _baseUri.resolve('/api/packages/$packageName');
    final body = await _getJson(uri);
    final latest = body['latest'] as Map<String, dynamic>;
    return Uri.parse(latest['archive_url'] as String);
  }

  /// The raw bytes of a package archive (a gzip-compressed tarball).
  Future<List<int>> fetchArchiveBytes(Uri archiveUri) async {
    final response = await _httpClient.get(archiveUri);
    if (response.statusCode != 200) {
      throw PubDevApiException(archiveUri, response.statusCode);
    }
    return response.bodyBytes;
  }

  /// The score facts recorded for a package's latest version (SPEC §3.1.3):
  /// its tags, like count and 30-day download count.
  Future<PackageScore> fetchPackageScore(String packageName) async {
    final uri = _baseUri.resolve('/api/packages/$packageName/score');
    final body = await _getJson(uri);
    return PackageScore(
      tags: (body['tags'] as List? ?? const []).cast<String>(),
      likeCount: body['likeCount'] as int? ?? 0,
      downloadCount30Days: body['downloadCount30Days'] as int? ?? 0,
    );
  }

  /// The latest version's version string, publish date and (per plugin
  /// platform) declared platform entry, from `GET /api/packages/<name>`.
  ///
  /// Federated plugins (SPEC review finding on e1-s2): an app-facing package
  /// like `url_launcher` declares its actual per-platform implementation
  /// package at `pubspec.flutter.plugin.platforms.<platform>.default_package`
  /// — that's the package whose archive carries the platform-specific files
  /// (`Package.swift`, `.so`, Gradle) a plugin's own archive won't have.
  Future<PackageInfo> fetchPackageInfo(String packageName) async {
    final uri = _baseUri.resolve('/api/packages/$packageName');
    final body = await _getJson(uri);
    final latest = body['latest'] as Map<String, dynamic>;
    return _packageInfoFromVersionJson(latest);
  }

  /// One package's exact published version — its pubspec (for plugin
  /// platform declarations) and archive URL — from
  /// `GET /api/packages/<name>/versions/<version>` (CLI live-check task,
  /// 2026-09-27): unlike [fetchPackageInfo], this pins a specific historical
  /// version rather than always reading the latest.
  Future<PackageVersion> fetchPackageVersion(
    String packageName,
    String version,
  ) async {
    final uri = _baseUri.resolve(
      '/api/packages/$packageName/versions/$version',
    );
    final body = await _getJson(uri);
    return PackageVersion(
      info: _packageInfoFromVersionJson(body),
      archiveUrl: Uri.parse(body['archive_url'] as String),
    );
  }

  /// The same shape [fetchPackageVersion] returns, but for a package's
  /// current latest version — used when a federated platform package isn't
  /// itself locked in the app's pubspec.lock.
  Future<PackageVersion> fetchLatestPackageVersion(String packageName) async {
    return PackageVersion(
      info: await fetchPackageInfo(packageName),
      archiveUrl: await fetchLatestArchiveUrl(packageName),
    );
  }

  /// Shared by [fetchPackageInfo] and [fetchPackageVersion]: both endpoints
  /// nest `pubspec`, `version` and `published` the same way, just under a
  /// `latest` key or not.
  PackageInfo _packageInfoFromVersionJson(Map<String, dynamic> versionJson) {
    final pubspec = versionJson['pubspec'] as Map<String, dynamic>;
    final pluginSection =
        (pubspec['flutter'] as Map<String, dynamic>?)?['plugin']
            as Map<String, dynamic>?;
    final platforms = pluginSection?['platforms'] as Map<String, dynamic>?;
    return PackageInfo(
      version: versionJson['version'] as String,
      published: DateTime.parse(versionJson['published'] as String),
      isFlutterPlugin: pluginSection != null,
      platforms: {
        if (platforms != null)
          for (final entry in platforms.entries)
            // A platform can be declared with no settings at all (seen live
            // on pub.dev, e.g. media_kit_video's `web: null`) — skip it
            // rather than throwing on the cast.
            if (entry.value != null)
              entry.key: PluginPlatformInfo.fromJson(
                entry.value as Map<String, dynamic>,
              ),
      },
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      throw PubDevApiException(uri, response.statusCode);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

/// Tags, like count and 30-day download count for a package's latest
/// version, from `GET /api/packages/<name>/score` (SPEC §3.1.3).
class PackageScore {
  const PackageScore({
    required this.tags,
    required this.likeCount,
    required this.downloadCount30Days,
  });

  final List<String> tags;
  final int likeCount;
  final int downloadCount30Days;
}

/// One package's pubspec-derived [PackageInfo] paired with the archive URL
/// for that same version (CLI live-check task, 2026-09-27), from either
/// [PubDevClient.fetchPackageVersion] (an exact locked version) or
/// [PubDevClient.fetchLatestPackageVersion] (a fallback when that version
/// isn't locked).
class PackageVersion {
  const PackageVersion({required this.info, required this.archiveUrl});

  final PackageInfo info;
  final Uri archiveUrl;
}

/// Version, publish date and per-platform plugin declarations for a
/// package's latest version, from `GET /api/packages/<name>`.
class PackageInfo {
  const PackageInfo({
    required this.version,
    required this.published,
    required this.platforms,
    this.isFlutterPlugin = false,
  });

  final String version;
  final DateTime published;

  /// Whether this version's pubspec declares a `flutter.plugin` section at
  /// all (CLI live-check task, 2026-09-27) — false for a pure Dart package,
  /// which can't block a native build and is skipped rather than checked.
  final bool isFlutterPlugin;

  /// Platform name (`ios`, `macos`, `android`, ...) to its declared
  /// `flutter.plugin.platforms` entry, for platforms the pubspec lists.
  final Map<String, PluginPlatformInfo> platforms;

  /// The declared entry for [platform], or null when this package's pubspec
  /// doesn't list it at all.
  PluginPlatformInfo? platformInfo(String platform) => platforms[platform];

  /// The federated default package declared for [platform], or null when
  /// this package declares no `default_package` for it (not federated, or
  /// the platform isn't listed at all).
  String? defaultPackageFor(String platform) =>
      platforms[platform]?.defaultPackage;

  /// Platform name to federated default package, for platforms that declare
  /// one.
  Map<String, String> get platformDefaultPackages => {
    for (final entry in platforms.entries)
      if (entry.value.defaultPackage case final defaultPackage?)
        entry.key: defaultPackage,
  };
}

/// A single platform's entry under a plugin's
/// `pubspec.flutter.plugin.platforms` map.
class PluginPlatformInfo {
  const PluginPlatformInfo({
    this.defaultPackage,
    this.pluginClass,
    this.ffiPlugin = false,
  });

  // Some published pubspecs declare `default_package` (or `pluginClass`) as
  // `true` rather than a package name (seen live on pub.dev, e.g. a web
  // platform entry) — read leniently rather than throwing on a bad cast.
  factory PluginPlatformInfo.fromJson(Map<String, dynamic> json) =>
      PluginPlatformInfo(
        defaultPackage: _stringOrNull(json['default_package']),
        pluginClass: _stringOrNull(json['pluginClass']),
        ffiPlugin: json['ffiPlugin'] as bool? ?? false,
      );

  /// The federated implementation package declared for this platform, if any.
  final String? defaultPackage;

  /// A native plugin class declared directly on this platform (as opposed to
  /// `dartPluginClass`, which is Dart-only).
  final String? pluginClass;

  /// Whether this platform declares a native FFI plugin directly.
  final bool ffiPlugin;

  /// True when this platform entry itself declares a native implementation
  /// — not a federated `default_package` and not a `dartPluginClass`-only
  /// Dart implementation (SPEC e2-s1 iOS-resolution rework).
  bool get declaresNativeImplementation => pluginClass != null || ffiPlugin;
}

String? _stringOrNull(Object? value) => value is String ? value : null;
