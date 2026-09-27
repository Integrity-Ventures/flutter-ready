import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:readiness_check/readiness_check.dart';
import 'package:test/test.dart';

Map<String, dynamic> _info({Map<String, String> defaultPackages = const {}}) {
  return {
    'latest': {
      'version': '1.0.0',
      'published': '2026-08-01T00:00:00.000Z',
      'pubspec': {
        if (defaultPackages.isNotEmpty)
          'flutter': {
            'plugin': {
              'platforms': {
                for (final entry in defaultPackages.entries)
                  entry.key: {'default_package': entry.value},
              },
            },
          },
      },
    },
  };
}

/// A fake pub.dev serving `/api/search` from [searchPages] (query -> pages,
/// each a list of package names), `/api/packages/<name>` from [infos], and
/// `/api/packages/<name>/score` tags from [tags].
PubDevClient _fakeClient({
  Map<String, List<List<String>>> searchPages = const {},
  Map<String, Map<String, dynamic>> infos = const {},
  Map<String, List<String>> tags = const {},
  List<String>? fetchedTagsFor,
  List<String>? fetchedInfoFor,
}) {
  final mock = MockClient((request) async {
    if (request.url.path == '/api/search') {
      final query = request.url.queryParameters['q']!;
      final page = int.parse(request.url.queryParameters['page']!);
      final pages = searchPages[query] ?? const [];
      final names = page >= 1 && page <= pages.length
          ? pages[page - 1]
          : const <String>[];
      return http.Response(
        jsonEncode({'packages': [for (final name in names) {'package': name}]}),
        200,
      );
    }
    final scoreMatch = RegExp(
      r'^/api/packages/(.+)/score$',
    ).firstMatch(request.url.path);
    if (scoreMatch != null) {
      final name = scoreMatch.group(1)!;
      fetchedTagsFor?.add(name);
      return http.Response(jsonEncode({'tags': tags[name] ?? const <String>[]}), 200);
    }
    final infoMatch = RegExp(r'^/api/packages/([^/]+)$').firstMatch(request.url.path);
    if (infoMatch != null) {
      final name = infoMatch.group(1)!;
      fetchedInfoFor?.add(name);
      final body = infos[name];
      if (body == null) return http.Response('not found', 404);
      return http.Response(jsonEncode(body), 200);
    }
    return http.Response('not found', 404);
  });
  return PubDevClient(httpClient: mock, baseUri: Uri.parse('https://pub.dev'));
}

const _noSwiftpm = 'is:plugin platform:ios -is:swiftpm-plugin';
const _topDownloads = 'is:plugin';

void main() {
  group('discoverFlutterPlugins', () {
    test(
      'merges both queries, dedupes, and records which query(ies) found each '
      'name, sorted alphabetically',
      () async {
        final client = _fakeClient(
          searchPages: {
            _noSwiftpm: [
              ['a', 'b'],
            ],
            _topDownloads: [
              ['b', 'c'],
            ],
          },
        );

        final result = await discoverFlutterPlugins(client, resultsPerQuery: 10);

        expect(result.map((c) => c.name), equals(['a', 'b', 'c']));
        expect(result[0].sources, equals(['no-swiftpm']));
        expect(result[1].sources, equals(['no-swiftpm', 'top-downloads']));
        expect(result[2].sources, equals(['top-downloads']));
      },
    );

    test(
      'folds a federated platform package into its app-facing plugin via '
      'default_package',
      () async {
        final client = _fakeClient(
          searchPages: {
            _noSwiftpm: [
              ['google_maps_flutter', 'google_maps_flutter_ios'],
            ],
          },
          infos: {
            'google_maps_flutter': _info(
              defaultPackages: {'ios': 'google_maps_flutter_ios'},
            ),
            'google_maps_flutter_ios': _info(),
          },
        );

        final result = await discoverFlutterPlugins(client, resultsPerQuery: 10);

        expect(result.map((c) => c.name), equals(['google_maps_flutter']));
      },
    );

    test(
      'folds via default_package even when the platform package name does '
      'not match the naming-suffix fallback',
      () async {
        final client = _fakeClient(
          searchPages: {
            _noSwiftpm: [
              ['camera', 'camera_avfoundation'],
            ],
          },
          infos: {
            'camera': _info(defaultPackages: {'ios': 'camera_avfoundation'}),
            'camera_avfoundation': _info(),
          },
        );

        final result = await discoverFlutterPlugins(client, resultsPerQuery: 10);

        expect(result.map((c) => c.name), equals(['camera']));
      },
    );

    test(
      'falls back to the platform-suffix naming convention when there is no '
      'default_package to go on',
      () async {
        final client = _fakeClient(
          searchPages: {
            _noSwiftpm: [
              ['path_provider', 'path_provider_foundation'],
            ],
          },
          // Neither package resolves via fetchPackageInfo (both 404), so the
          // default_package check finds nothing — only the naming fallback
          // can fold path_provider_foundation.
        );

        final result = await discoverFlutterPlugins(client, resultsPerQuery: 10);

        expect(result.map((c) => c.name), equals(['path_provider']));
      },
    );

    test(
      'keeps a platform-suffixed name when its base is not itself a '
      'candidate',
      () async {
        final client = _fakeClient(
          searchPages: {
            _noSwiftpm: [
              ['shared_preferences_android'],
            ],
          },
        );

        final result = await discoverFlutterPlugins(client, resultsPerQuery: 10);

        expect(result.map((c) => c.name), equals(['shared_preferences_android']));
      },
    );

    test('resultsPerQuery rounds up to pages of 10 and fetches every page', () async {
      final client = _fakeClient(
        searchPages: {
          _noSwiftpm: [
            ['a'],
            ['b'],
          ],
        },
      );

      final result = await discoverFlutterPlugins(client, resultsPerQuery: 20);

      expect(result.map((c) => c.name), equals(['a', 'b']));
    });

    test('carries each surviving candidate\'s fetched score tags', () async {
      final client = _fakeClient(
        searchPages: {
          _noSwiftpm: [
            ['url_launcher'],
          ],
        },
        tags: {
          'url_launcher': ['sdk:flutter', 'is:plugin', 'is:swiftpm-plugin'],
        },
      );

      final result = await discoverFlutterPlugins(client, resultsPerQuery: 10);

      expect(result.single.hasTag('is:swiftpm-plugin'), isTrue);
    });

    test('never fetches tags for a candidate folded away', () async {
      final fetchedTagsFor = <String>[];
      final client = _fakeClient(
        searchPages: {
          _noSwiftpm: [
            ['path_provider', 'path_provider_foundation'],
          ],
        },
        fetchedTagsFor: fetchedTagsFor,
      );

      await discoverFlutterPlugins(client, resultsPerQuery: 10);

      expect(fetchedTagsFor, equals(['path_provider']));
    });
  });
}
