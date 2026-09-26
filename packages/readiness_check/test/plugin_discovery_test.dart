import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:readiness_check/readiness_check.dart';
import 'package:test/test.dart';

/// Score tags recorded live from pub.dev on 2026-09-27, per the rework
/// instruction: a real Flutter plugin, a pure-Dart Flutter package carrying
/// every platform tag but no `is:plugin` (the false-red case the rework
/// closes), a Flutter plugin with no mobile platform tag, and a plain Dart
/// package.
const _packageTags = {
  'url_launcher': [
    'sdk:flutter',
    'is:plugin',
    'platform:ios',
    'platform:android',
    'platform:web',
  ],
  'shared_preferences': [
    'sdk:flutter',
    'is:plugin',
    'platform:ios',
    'platform:android',
  ],
  'provider': ['sdk:flutter', 'platform:android', 'platform:ios'],
  'flutter_map': ['sdk:flutter', 'platform:android', 'platform:ios'],
  'window_manager': [
    'sdk:flutter',
    'is:plugin',
    'platform:windows',
    'platform:macos',
    'platform:linux',
  ],
  'http': ['sdk:dart'],
};

PubDevClient _fakeClient(List<String> rankedNames, {List<String>? fetched}) {
  final mock = MockClient((request) async {
    if (request.url.path == '/api/package-name-completion-data') {
      return http.Response(jsonEncode({'packages': rankedNames}), 200);
    }
    final match = RegExp(r'^/api/packages/(.+)/score$')
        .firstMatch(request.url.path);
    final name = match!.group(1)!;
    fetched?.add(name);
    final tags = _packageTags[name] ?? const <String>[];
    return http.Response(jsonEncode({'tags': tags}), 200);
  });
  return PubDevClient(httpClient: mock, baseUri: Uri.parse('https://pub.dev'));
}

void main() {
  group('discoverFlutterPlugins', () {
    test('keeps only sdk:flutter + is:plugin packages with an ios or android '
        'tag, dropping pure-Dart Flutter packages like provider', () async {
      final client = _fakeClient([
        'url_launcher',
        'provider',
        'window_manager',
        'http',
      ]);

      final result = await discoverFlutterPlugins(client, topN: 100);

      expect(result.map((c) => c.name), equals(['url_launcher']));
    });

    test('preserves the ranking order of the completion-data list', () async {
      final client = _fakeClient(['shared_preferences', 'url_launcher']);

      final result = await discoverFlutterPlugins(client, topN: 100);

      expect(
        result.map((c) => c.name),
        equals(['shared_preferences', 'url_launcher']),
      );
    });

    test(
      'counts topN after filtering and stops fetching once N are found',
      () async {
        final fetched = <String>[];
        final client = _fakeClient([
          'provider',
          'url_launcher',
          'shared_preferences',
        ], fetched: fetched);

        final result = await discoverFlutterPlugins(client, topN: 1);

        expect(result.map((c) => c.name), equals(['url_launcher']));
        expect(fetched, equals(['provider', 'url_launcher']));
      },
    );

    test('carries the fetched tags on the returned candidate', () async {
      final client = _fakeClient(['url_launcher']);

      final result = await discoverFlutterPlugins(client, topN: 100);

      expect(result.single.hasTag('platform:ios'), isTrue);
      expect(result.single.hasTag('platform:web'), isTrue);
    });
  });
}
