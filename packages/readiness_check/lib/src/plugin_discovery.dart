import 'pub_dev_client.dart';

/// A pub.dev package kept after the SPEC §3.1.1 Flutter-plugin filter,
/// carrying the score tags already fetched so downstream checks (SwiftPM,
/// alignment, Android facts) don't need to re-fetch them.
class PluginCandidate {
  const PluginCandidate({required this.name, required this.tags});

  final String name;
  final List<String> tags;

  bool hasTag(String tag) => tags.contains(tag);
}

const _flutterSdkTag = 'sdk:flutter';
const _pluginTag = 'is:plugin';
const _iosPlatformTag = 'platform:ios';
const _androidPlatformTag = 'platform:android';

bool _isFlutterPlugin(List<String> tags) =>
    tags.contains(_flutterSdkTag) &&
    tags.contains(_pluginTag) &&
    (tags.contains(_iosPlatformTag) || tags.contains(_androidPlatformTag));

/// Discovers the top-[topN] real Flutter plugins per SPEC §3.1.1: tagged
/// `sdk:flutter` and `is:plugin`, plus at least one of `platform:ios` /
/// `platform:android`.
///
/// Walks pub.dev's ranked package list in order, fetching tags one name at a
/// time, and stops once [topN] plugins have been kept (or the ranked list
/// runs out first) — so [topN] counts plugins *after* the filter, not raw
/// names before it.
Future<List<PluginCandidate>> discoverFlutterPlugins(
  PubDevClient client, {
  int topN = 100,
}) async {
  final rankedNames = await client.fetchPackageNames();
  final candidates = <PluginCandidate>[];
  for (final name in rankedNames) {
    if (candidates.length >= topN) break;
    final tags = await client.fetchPackageTags(name);
    if (_isFlutterPlugin(tags)) {
      candidates.add(PluginCandidate(name: name, tags: tags));
    }
  }
  return candidates;
}
