import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:readiness_check/readiness_check.dart';
import 'package:test/test.dart';

PubDevClient _fakeClient(Map<String, Map<String, dynamic>> responsesByPath) {
  final mock = MockClient((request) async {
    final body = responsesByPath[request.url.path];
    if (body == null) return http.Response('not found', 404);
    return http.Response(jsonEncode(body), 200);
  });
  return PubDevClient(httpClient: mock, baseUri: Uri.parse('https://pub.dev'));
}

void main() {
  group('fetchPackageScore', () {
    test('reads tags, likeCount and downloadCount30Days', () async {
      final client = _fakeClient({
        '/api/packages/url_launcher/score': {
          'tags': ['sdk:flutter', 'is:plugin'],
          'likeCount': 8176,
          'downloadCount30Days': 6804090,
        },
      });

      final score = await client.fetchPackageScore('url_launcher');

      expect(score.tags, ['sdk:flutter', 'is:plugin']);
      expect(score.likeCount, 8176);
      expect(score.downloadCount30Days, 6804090);
    });

    test('defaults missing counts to zero', () async {
      final client = _fakeClient({
        '/api/packages/new_plugin/score': {'tags': <String>[]},
      });

      final score = await client.fetchPackageScore('new_plugin');

      expect(score.likeCount, 0);
      expect(score.downloadCount30Days, 0);
    });
  });

  group('searchPackages', () {
    test('reads package names in order and passes through sort/page', () async {
      Uri? requested;
      final mock = MockClient((request) async {
        requested = request.url;
        return http.Response(
          jsonEncode({
            'packages': [
              {'package': 'google_maps_flutter'},
              {'package': 'open_filex'},
            ],
          }),
          200,
        );
      });
      final client = PubDevClient(
        httpClient: mock,
        baseUri: Uri.parse('https://pub.dev'),
      );

      final names = await client.searchPackages(
        'is:plugin platform:ios -is:swiftpm-plugin',
        page: 3,
      );

      expect(names, ['google_maps_flutter', 'open_filex']);
      expect(requested!.path, '/api/search');
      expect(
        requested!.queryParameters['q'],
        'is:plugin platform:ios -is:swiftpm-plugin',
      );
      expect(requested!.queryParameters['sort'], 'downloads');
      expect(requested!.queryParameters['page'], '3');
    });

    test('returns an empty list for a page past the results', () async {
      final client = _fakeClient({
        '/api/search': {'packages': <Map<String, dynamic>>[]},
      });

      final names = await client.searchPackages('is:plugin', page: 11);

      expect(names, isEmpty);
    });
  });

  group('fetchPackageInfo', () {
    test(
      'reads version and published date for a non-federated package',
      () async {
        final client = _fakeClient({
          '/api/packages/some_plugin': {
            'latest': {
              'version': '1.2.3',
              'published': '2026-08-28T04:11:13.706203Z',
              'pubspec': {'name': 'some_plugin'},
            },
          },
        });

        final info = await client.fetchPackageInfo('some_plugin');

        expect(info.version, '1.2.3');
        expect(info.published, DateTime.parse('2026-08-28T04:11:13.706203Z'));
        expect(info.defaultPackageFor('ios'), isNull);
        expect(info.platformDefaultPackages, isEmpty);
      },
    );

    test('reads federated default packages per platform', () async {
      final client = _fakeClient({
        '/api/packages/url_launcher': {
          'latest': {
            'version': '6.3.2',
            'published': '2025-07-10T19:46:46.051934Z',
            'pubspec': {
              'name': 'url_launcher',
              'flutter': {
                'plugin': {
                  'platforms': {
                    'android': {'default_package': 'url_launcher_android'},
                    'ios': {'default_package': 'url_launcher_ios'},
                    'web': {'default_package': 'url_launcher_web'},
                  },
                },
              },
            },
          },
        },
      });

      final info = await client.fetchPackageInfo('url_launcher');

      expect(info.defaultPackageFor('ios'), 'url_launcher_ios');
      expect(info.defaultPackageFor('android'), 'url_launcher_android');
      expect(info.defaultPackageFor('macos'), isNull);
    });

    test(
      'treats a package with no flutter.plugin section as unfederated',
      () async {
        final client = _fakeClient({
          '/api/packages/http': {
            'latest': {
              'version': '1.2.0',
              'published': '2026-01-01T00:00:00.000000Z',
              'pubspec': {'name': 'http'},
            },
          },
        });

        final info = await client.fetchPackageInfo('http');

        expect(info.platformDefaultPackages, isEmpty);
      },
    );

    test(
      'reads pluginClass/ffiPlugin and tolerates a non-string default_package '
      '(seen live on pub.dev, e.g. a web platform entry)',
      () async {
        final client = _fakeClient({
          '/api/packages/flutter_soloud': {
            'latest': {
              'version': '3.5.1',
              'published': '2026-05-01T00:00:00.000000Z',
              'pubspec': {
                'name': 'flutter_soloud',
                'flutter': {
                  'plugin': {
                    'platforms': {
                      'ios': {
                        'pluginClass': 'FlutterSoloudPlugin',
                        'ffiPlugin': true,
                      },
                      'web': {'default_package': true},
                    },
                  },
                },
              },
            },
          },
        });

        final info = await client.fetchPackageInfo('flutter_soloud');

        final ios = info.platformInfo('ios')!;
        expect(ios.pluginClass, 'FlutterSoloudPlugin');
        expect(ios.ffiPlugin, isTrue);
        expect(ios.declaresNativeImplementation, isTrue);
        expect(info.platformInfo('web')!.defaultPackage, isNull);
        expect(info.defaultPackageFor('web'), isNull);
      },
    );

    test(
      'skips a platform declared with no settings at all (seen live on '
      'pub.dev, e.g. media_kit_video\'s web: null)',
      () async {
        final client = _fakeClient({
          '/api/packages/media_kit_video': {
            'latest': {
              'version': '2.0.1',
              'published': '2026-05-01T00:00:00.000000Z',
              'pubspec': {
                'name': 'media_kit_video',
                'flutter': {
                  'plugin': {
                    'platforms': {
                      'ios': {'pluginClass': 'MediaKitVideoPlugin'},
                      'android': {'pluginClass': 'MediaKitVideoPlugin'},
                      'web': null,
                    },
                  },
                },
              },
            },
          },
        });

        final info = await client.fetchPackageInfo('media_kit_video');

        expect(info.isFlutterPlugin, isTrue);
        expect(info.platformInfo('ios')?.pluginClass, 'MediaKitVideoPlugin');
        expect(
          info.platformInfo('android')?.pluginClass,
          'MediaKitVideoPlugin',
        );
        expect(info.platformInfo('web'), isNull);
      },
    );
  });

  group('fetchPackageVersion', () {
    test('reads the pubspec and archive URL for an exact version', () async {
      final client = _fakeClient({
        '/api/packages/some_plugin/versions/1.2.3': {
          'version': '1.2.3',
          'published': '2026-08-28T04:11:13.706203Z',
          'archive_url': 'https://pub.dev/api/archives/some_plugin-1.2.3.tar.gz',
          'pubspec': {
            'name': 'some_plugin',
            'flutter': {
              'plugin': {
                'platforms': {
                  'ios': {'pluginClass': 'SomePlugin'},
                },
              },
            },
          },
        },
      });

      final version = await client.fetchPackageVersion('some_plugin', '1.2.3');

      expect(version.info.version, '1.2.3');
      expect(version.info.isFlutterPlugin, isTrue);
      expect(version.info.platformInfo('ios')?.pluginClass, 'SomePlugin');
      expect(version.archiveUrl, Uri.parse('https://pub.dev/api/archives/some_plugin-1.2.3.tar.gz'));
    });

    test('treats a package with no flutter.plugin section as not a plugin', () async {
      final client = _fakeClient({
        '/api/packages/some_dart_pkg/versions/2.0.0': {
          'version': '2.0.0',
          'published': '2026-08-28T04:11:13.706203Z',
          'archive_url': 'https://pub.dev/api/archives/some_dart_pkg-2.0.0.tar.gz',
          'pubspec': {'name': 'some_dart_pkg'},
        },
      });

      final version = await client.fetchPackageVersion('some_dart_pkg', '2.0.0');

      expect(version.info.isFlutterPlugin, isFalse);
    });

    test('a version pub.dev has never published throws PubDevApiException', () async {
      final client = _fakeClient({});

      expect(
        () => client.fetchPackageVersion('some_plugin', '99.99.99'),
        throwsA(isA<PubDevApiException>()),
      );
    });
  });

  group('fetchLatestPackageVersion', () {
    test('combines fetchPackageInfo and fetchLatestArchiveUrl', () async {
      final client = _fakeClient({
        '/api/packages/some_plugin': {
          'latest': {
            'version': '1.3.0',
            'published': '2026-08-28T04:11:13.706203Z',
            'archive_url': 'https://pub.dev/api/archives/some_plugin-1.3.0.tar.gz',
            'pubspec': {'name': 'some_plugin'},
          },
        },
      });

      final version = await client.fetchLatestPackageVersion('some_plugin');

      expect(version.info.version, '1.3.0');
      expect(version.archiveUrl, Uri.parse('https://pub.dev/api/archives/some_plugin-1.3.0.tar.gz'));
    });
  });
}
