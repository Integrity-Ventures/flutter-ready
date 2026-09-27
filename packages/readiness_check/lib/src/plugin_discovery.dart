import 'concurrency_pool.dart';
import 'pub_dev_client.dart';

/// A pub.dev package kept after discovery (SPEC §3.1.1), carrying the score
/// tags already fetched so downstream checks (SwiftPM, alignment, Gradle
/// facts) don't need to re-fetch them.
class PluginCandidate {
  const PluginCandidate({
    required this.name,
    required this.tags,
    this.sources = const [],
  });

  final String name;
  final List<String> tags;

  /// Which [discoveryQueries] surfaced this plugin, by label, sorted
  /// alphabetically (`["no-swiftpm", "top-downloads"]`) — empty for
  /// candidates built outside discovery (fixtures, tests).
  final List<String> sources;

  bool hasTag(String tag) => tags.contains(tag);
}

/// One pub.dev search this discovery runs, sorted by downloads.
class DiscoveryQuery {
  const DiscoveryQuery({required this.label, required this.query});

  final String label;
  final String query;
}

/// The two searches discovery merges (SPEC §3.1.1, 2026-09-27 owner-approved
/// rework): the likely reds first — plugins with no `is:swiftpm-plugin` tag —
/// then the most-downloaded plugins overall for context.
const discoveryQueries = [
  DiscoveryQuery(
    label: 'no-swiftpm',
    query: 'is:plugin platform:ios -is:swiftpm-plugin',
  ),
  DiscoveryQuery(label: 'top-downloads', query: 'is:plugin'),
];

/// Results per search page; pub.dev's `/api/search` returns 10 and rejects
/// requests past page 10 (measured 2026-09-27 — see the discovery
/// instruction).
const _resultsPerPage = 10;

/// Federated platform-package suffixes folded into their app-facing plugin
/// when the naming convention alone reveals the relationship (SPEC §3.1.1),
/// e.g. `google_maps_flutter_ios` -> `google_maps_flutter`.
const _platformSuffixes = [
  'ios',
  'android',
  'foundation',
  'macos',
  'windows',
  'linux',
  'web',
  'darwin',
];

/// Discovers Flutter plugin candidates from pub.dev search, reds first (SPEC
/// §3.1.1, 2026-09-27): [discoveryQueries], sorted by downloads,
/// [resultsPerQuery] results each (rounded up to pages of 10 — pub.dev caps
/// a single query at 100 results). Merges and dedupes both queries, then
/// folds federated platform packages into their app-facing plugin so a
/// plugin's downloads/status aren't split across rows.
Future<List<PluginCandidate>> discoverFlutterPlugins(
  PubDevClient client, {
  int resultsPerQuery = 100,
  int concurrency = 4,
}) async {
  final pagesPerQuery = (resultsPerQuery / _resultsPerPage).ceil();
  final order = <String>[];
  final sourcesByName = <String, Set<String>>{};
  for (final discoveryQuery in discoveryQueries) {
    final names = await _fetchQueryNames(
      client,
      discoveryQuery.query,
      pagesPerQuery,
      concurrency,
    );
    for (final name in names) {
      final labels = sourcesByName.putIfAbsent(name, () => <String>{});
      final isNew = labels.isEmpty;
      labels.add(discoveryQuery.label);
      if (isNew) order.add(name);
    }
  }

  final survivors = await _foldFederatedPackages(client, order, concurrency);

  return mapWithConcurrency(survivors, concurrency, (name) async {
    final tags = await _safeTags(client, name);
    final sources = sourcesByName[name]!.toList()..sort();
    return PluginCandidate(name: name, tags: tags, sources: sources);
  });
}

Future<List<String>> _fetchQueryNames(
  PubDevClient client,
  String query,
  int pages,
  int concurrency,
) async {
  final pageNumbers = List<int>.generate(pages, (index) => index + 1);
  final pageResults = await mapWithConcurrency(
    pageNumbers,
    concurrency,
    (page) => client.searchPackages(query, page: page),
  );
  return [for (final names in pageResults) ...names];
}

/// Drops a raw candidate when another candidate declares it as a
/// `default_package` for some platform, or when its own name is a
/// recognised platform suffix on another candidate's name (SPEC §3.1.1) —
/// either way it's a federated platform package, not its own plugin row.
Future<List<String>> _foldFederatedPackages(
  PubDevClient client,
  List<String> rawNames,
  int concurrency,
) async {
  final nameSet = rawNames.toSet();
  final infos = await mapWithConcurrency(
    rawNames,
    concurrency,
    (name) => _safeInfo(client, name),
  );
  final declaredDefaultPackages = <String>{
    for (final info in infos)
      if (info != null) ...info.platformDefaultPackages.values,
  };

  return [
    for (final name in rawNames)
      if (!declaredDefaultPackages.contains(name) &&
          _appFacingNameFor(name, nameSet) == null)
        name,
  ];
}

String? _appFacingNameFor(String name, Set<String> candidateNames) {
  for (final suffix in _platformSuffixes) {
    final marker = '_$suffix';
    if (!name.endsWith(marker)) continue;
    final base = name.substring(0, name.length - marker.length);
    if (base.isNotEmpty && candidateNames.contains(base)) return base;
  }
  return null;
}

Future<PackageInfo?> _safeInfo(PubDevClient client, String name) async {
  try {
    return await client.fetchPackageInfo(name);
  } catch (_) {
    return null;
  }
}

Future<List<String>> _safeTags(PubDevClient client, String name) async {
  try {
    return await client.fetchPackageTags(name);
  } catch (_) {
    return const [];
  }
}
