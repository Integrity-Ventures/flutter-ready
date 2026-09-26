import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:readiness_check/readiness_check.dart';
import 'package:test/test.dart';

/// Score tags recorded live from pub.dev on 2026-09-26, per the microtask
/// instruction: a real Flutter plugin, a Flutter plugin with no mobile
/// platform tag, and a plain Dart package.
const _packageTags = {
  'url_launcher': [
    'sdk:flutter',
    'platform:ios',
    'platform:android',
    'platform:web',
  ],
  'flutter_map': ['sdk:flutter', 'platform:android', 'platform:ios'],
  'window_manager': [
    'sdk:flutter',
    'platform:windows',
    'platform:macos',
    'platform:linux',
  ],
  'http': ['sdk:dart'],
};

PubDevClient _fakeClient(List<String> rankedNames) {
  final mock = MockClient((request) async {
    if (request.url.path == '/api/package-name-completion-data') {
      return http.Response(jsonEncode({'packages': rankedNames}), 200);
    }
    final match = RegExp(r'^/api/packages/(.+)/score$')
        .firstMatch(request.url.path);
    final tags = _packageTags[match!.group(1)] ?? const <String>[];
    return http.Response(jsonEncode({'tags': tags}), 200);
  });
  return PubDevClient(httpClient: mock, baseUri: Uri.parse('https://pub.dev'));
}

void main() {
  group('discoverFlutterPlugins', () {
    test(
      'keeps only sdk:flutter packages with an ios or android tag',
      () async {
        final client = _fakeClient(['url_launcher', 'window_manager', 'http']);

        final result = await discoverFlutterPlugins(client, topN: 100);

        expect(result.map((c) => c.name), equals(['url_launcher']));
      },
    );

    test('preserves the ranking order of the completion-data list', () async {
      final client = _fakeClient(['flutter_map', 'url_launcher']);

      final result = await discoverFlutterPlugins(client, topN: 100);

      expect(
        result.map((c) => c.name),
        equals(['flutter_map', 'url_launcher']),
      );
    });

    test('applies topN to the raw list before filtering', () async {
      final client = _fakeClient(['window_manager', 'url_launcher']);

      final result = await discoverFlutterPlugins(client, topN: 1);

      expect(result, isEmpty);
    });

    test('carries the fetched tags on the returned candidate', () async {
      final client = _fakeClient(['url_launcher']);

      final result = await discoverFlutterPlugins(client, topN: 100);

      expect(result.single.hasTag('platform:ios'), isTrue);
      expect(result.single.hasTag('platform:web'), isTrue);
    });
  });
}
