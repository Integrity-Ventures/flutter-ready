import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_ready/readiness_check.dart';
import 'package:snapshot_job/snapshot_job.dart';
import 'package:test/test.dart';

List<int> _buildArchive(Map<String, List<int>> filesByPath) {
  final archive = Archive();
  for (final entry in filesByPath.entries) {
    archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
  }
  return GZipEncoder().encodeBytes(TarEncoder().encodeBytes(archive));
}

/// A minimal ELF64 file with one aligned or misaligned PT_LOAD segment —
/// only what checkSoAlignment reads (mirrors readiness_check's own test).
Uint8List _buildElf({required bool aligned}) {
  const ehsize = 64;
  const phentsize = 56;
  final bytes = Uint8List(ehsize + phentsize);
  final data = ByteData.sublistView(bytes);
  bytes[0] = 0x7f;
  bytes[1] = 0x45;
  bytes[2] = 0x4c;
  bytes[3] = 0x46;
  bytes[4] = 2; // 64-bit
  bytes[5] = 1; // little-endian
  data.setUint64(32, ehsize, Endian.little); // e_phoff
  data.setUint16(54, phentsize, Endian.little); // e_phentsize
  data.setUint16(56, 1, Endian.little); // e_phnum
  data.setUint32(ehsize, 1, Endian.little); // p_type = PT_LOAD
  data.setUint64(ehsize + 48, aligned ? 0x4000 : 0x1000, Endian.little);
  return bytes;
}

const _androidGradle = '''
android {
    compileSdk 35
}
''';

/// A fake pub.dev: [scores] and [infos] key package names; [archives] key
/// package names to pre-built archive bytes served at a deterministic URL.
PubDevClient _fakePubDev({
  Map<String, Map<String, dynamic>> scores = const {},
  Map<String, Map<String, dynamic>> infos = const {},
  Map<String, List<int>> archives = const {},
  List<String> failingPackages = const [],
  List<String>? fetchedArchivePaths,
}) {
  final archiveLog = fetchedArchivePaths ?? <String>[];
  final mock = MockClient((request) async {
    final path = request.url.path;
    final scoreMatch = RegExp(r'^/api/packages/(.+)/score$').firstMatch(path);
    if (scoreMatch != null) {
      final name = scoreMatch.group(1)!;
      if (failingPackages.contains(name)) return http.Response('error', 500);
      return http.Response(
        jsonEncode(scores[name] ?? {'tags': <String>[]}),
        200,
      );
    }
    final infoMatch = RegExp(r'^/api/packages/([^/]+)$').firstMatch(path);
    if (infoMatch != null) {
      final name = infoMatch.group(1)!;
      if (failingPackages.contains(name)) return http.Response('error', 500);
      return http.Response(jsonEncode(infos[name]!), 200);
    }
    final archiveMatch = RegExp(r'^/api/archives/([^/]+)\.tar\.gz$')
        .firstMatch(path);
    if (archiveMatch != null) {
      archiveLog.add(path);
      final name = archiveMatch.group(1)!;
      return http.Response.bytes(archives[name]!, 200);
    }
    return http.Response('not found', 404);
  });
  return PubDevClient(httpClient: mock, baseUri: Uri.parse('https://pub.dev'));
}

Map<String, dynamic> _info({
  required String version,
  String published = '2026-08-01T00:00:00.000Z',
  Map<String, Map<String, dynamic>> platforms = const {},
}) {
  return {
    'latest': {
      'version': version,
      'published': published,
      'pubspec': {
        if (platforms.isNotEmpty)
          'flutter': {
            'plugin': {'platforms': platforms},
          },
      },
      'archive_url': 'https://pub.dev/api/archives/$version.tar.gz',
    },
  };
}

/// Shorthand for a federated platform entry: `{'ios': 'foo_ios'}`.
Map<String, Map<String, dynamic>> _federated(Map<String, String> byPlatform) {
  return {
    for (final entry in byPlatform.entries)
      entry.key: {'default_package': entry.value},
  };
}

void main() {
  group('assembleSnapshot: federated plugin', () {
    test(
      'checks the federated ios/android packages, tag stays app-facing',
      () async {
        final fetchedPaths = <String>[];
        final client = _fakePubDev(
          scores: {
            'url_launcher': {
              'tags': ['is:plugin', 'is:swiftpm-plugin'],
              'likeCount': 10,
              'downloadCount30Days': 1000,
            },
          },
          infos: {
            'url_launcher': _info(
              version: 'app-6.3.2',
              platforms: _federated({
                'ios': 'url_launcher_ios',
                'android': 'url_launcher_android',
              }),
            ),
            'url_launcher_ios': _info(
              version: 'ios-6.2.4',
              platforms: {
                'ios': {'pluginClass': 'FLTURLLauncherPlugin'},
              },
            ),
            'url_launcher_android': _info(version: 'android-6.3.0'),
          },
          archives: {
            'ios-6.2.4': _buildArchive({
              'ios/url_launcher_ios/Package.swift': utf8.encode('// spm'),
            }),
            'android-6.3.0': _buildArchive({
              'android/src/main/jniLibs/arm64-v8a/libx.so': _buildElf(
                aligned: true,
              ),
              'android/build.gradle': utf8.encode(_androidGradle),
            }),
          },
          fetchedArchivePaths: fetchedPaths,
        );

        final result = await assembleSnapshot(client, [
          PluginCandidate(
            name: 'url_launcher',
            tags: ['is:plugin', 'is:swiftpm-plugin'],
          ),
        ]);

        final snapshot = result.single;
        expect(snapshot.version, 'app-6.3.2');
        expect(snapshot.likeCount, 10);
        expect(snapshot.downloadCount30Days, 1000);
        expect(snapshot.swiftpm!.checkedPackage, 'url_launcher_ios');
        expect(snapshot.swiftpm!.readiness.tagSaysReady, isTrue);
        expect(snapshot.swiftpm!.readiness.archiveSaysReady, isTrue);
        expect(snapshot.swiftpm!.nativeIos, isTrue);
        expect(snapshot.alignment!.checkedPackage, 'url_launcher_android');
        expect(snapshot.alignment!.soFiles.single.aligned, isTrue);
        expect(snapshot.android!.checkedPackage, 'url_launcher_android');
        expect(snapshot.android!.settings!.compileSdk, '35');
        expect(snapshot.errors, isEmpty);
        // Two distinct federated archives, each fetched exactly once.
        expect(fetchedPaths.toSet().length, 2);
        expect(fetchedPaths, hasLength(2));
      },
    );
  });

  group('assembleSnapshot: non-federated plugin', () {
    test(
      'checks the plugin\'s own archive once for both ios and android',
      () async {
        final fetchedPaths = <String>[];
        final client = _fakePubDev(
          scores: {
            'some_plugin': {
              'tags': ['is:plugin'],
            },
          },
          infos: {
            'some_plugin': _info(
              version: '1.0.0',
              platforms: {
                'ios': {'pluginClass': 'SomePlugin'},
              },
            ),
          },
          archives: {
            '1.0.0': _buildArchive({
              'ios/some_plugin/Package.swift': utf8.encode('// spm'),
              'android/src/main/jniLibs/arm64-v8a/libx.so': _buildElf(
                aligned: false,
              ),
            }),
          },
          fetchedArchivePaths: fetchedPaths,
        );

        final result = await assembleSnapshot(client, [
          PluginCandidate(name: 'some_plugin', tags: ['is:plugin']),
        ]);

        final snapshot = result.single;
        expect(snapshot.swiftpm!.checkedPackage, 'some_plugin');
        expect(snapshot.swiftpm!.nativeIos, isTrue);
        expect(snapshot.alignment!.checkedPackage, 'some_plugin');
        expect(snapshot.alignment!.soFiles.single.aligned, isFalse);
        expect(snapshot.android!.settings, isNull);
        // Same archive backs both checks — fetched only once.
        expect(fetchedPaths, hasLength(1));
      },
    );
  });

  group('assembleSnapshot: iOS resolution rework (e2-s1)', () {
    test('path_provider shape: a dartPluginClass-only federated package is not '
        'native iOS', () async {
      final client = _fakePubDev(
        scores: {
          'path_provider': {
            'tags': ['is:plugin'],
          },
        },
        infos: {
          'path_provider': _info(
            version: 'app-2.1.2',
            platforms: _federated({'ios': 'path_provider_foundation'}),
          ),
          'path_provider_foundation': _info(
            version: 'foundation-2.6.0',
            platforms: {
              'ios': {'dartPluginClass': 'PathProviderFoundation'},
            },
          ),
        },
        archives: {
          'app-2.1.2': _buildArchive({'pubspec.yaml': utf8.encode('name: x')}),
          'foundation-2.6.0': _buildArchive({
            'lib/path_provider_foundation.dart': utf8.encode('// dart-only'),
          }),
        },
      );

      final result = await assembleSnapshot(client, [
        PluginCandidate(name: 'path_provider', tags: ['is:plugin']),
      ]);

      final snapshot = result.single;
      expect(snapshot.swiftpm!.checkedPackage, 'path_provider_foundation');
      expect(snapshot.swiftpm!.nativeIos, isFalse);
      expect(snapshot.swiftpm!.reason, 'no-native-ios-code');
    });

    test(
      'flutter_keyboard_visibility shape: an inline iOS pluginClass is never '
      'resolved via the macOS default_package',
      () async {
        final client = _fakePubDev(
          scores: {
            'flutter_keyboard_visibility': {
              'tags': ['is:swiftpm-plugin'],
            },
          },
          infos: {
            'flutter_keyboard_visibility': _info(
              version: '6.0.0',
              platforms: {
                'ios': {'pluginClass': 'FlutterKeyboardVisibilityPlugin'},
                'macos': {
                  'default_package': 'flutter_keyboard_visibility_macos',
                },
              },
            ),
          },
          archives: {
            '6.0.0': _buildArchive({
              'ios/flutter_keyboard_visibility/Package.swift': utf8.encode(
                '// spm',
              ),
            }),
          },
        );

        final result = await assembleSnapshot(client, [
          PluginCandidate(
            name: 'flutter_keyboard_visibility',
            tags: ['is:swiftpm-plugin'],
          ),
        ]);

        final snapshot = result.single;
        expect(snapshot.swiftpm!.checkedPackage, 'flutter_keyboard_visibility');
        expect(snapshot.swiftpm!.readiness.archiveSaysReady, isTrue);
        expect(snapshot.swiftpm!.readiness.agrees, isTrue);
        expect(snapshot.swiftpm!.nativeIos, isTrue);
      },
    );
  });

  group('assembleSnapshot: Android-only plugins are not iOS plugins (e2-s1 '
      'rework 2)', () {
    test(
      'in_app_update shape: an Android-only pubspec with a stray ios/ '
      'podspec grades not-ios-plugin, without consulting the podspec',
      () async {
        final client = _fakePubDev(
          scores: {
            'in_app_update': {
              'tags': ['is:plugin', 'platform:android'],
            },
          },
          infos: {
            'in_app_update': _info(
              version: '5.0.0',
              platforms: {
                'android': {'pluginClass': 'InAppUpdatePlugin'},
              },
            ),
          },
          archives: {
            '5.0.0': _buildArchive({
              // Leftover from `flutter create --template=plugin`: never
              // installed, since the pubspec declares no ios/macos platform.
              'ios/in_app_update.podspec': utf8.encode('// stray'),
            }),
          },
        );

        final result = await assembleSnapshot(client, [
          PluginCandidate(
            name: 'in_app_update',
            tags: ['is:plugin', 'platform:android'],
          ),
        ]);

        final snapshot = result.single;
        expect(snapshot.swiftpm!.checkedPackage, 'in_app_update');
        expect(snapshot.swiftpm!.nativeIos, isFalse);
        expect(snapshot.swiftpm!.reason, 'not-ios-plugin');
      },
    );
  });

  group('assembleSnapshot: per-plugin failure isolation', () {
    test(
      'a plugin whose package info fetch fails still yields a snapshot',
      () async {
        final client = _fakePubDev(
          scores: {
            'broken_plugin': {
              'tags': ['is:plugin'],
            },
          },
          infos: const {},
          failingPackages: ['broken_plugin'],
        );

        final result = await assembleSnapshot(client, [
          PluginCandidate(name: 'broken_plugin', tags: ['is:plugin']),
        ]);

        final snapshot = result.single;
        expect(snapshot.name, 'broken_plugin');
        expect(snapshot.version, isNull);
        expect(snapshot.swiftpm, isNull);
        expect(snapshot.alignment, isNull);
        expect(snapshot.android, isNull);
        expect(snapshot.errors, isNotEmpty);
      },
    );

    test(
      'one plugin failing does not affect another plugin in the same run',
      () async {
        final client = _fakePubDev(
          scores: {
            'good_plugin': {
              'tags': ['is:plugin'],
              'likeCount': 5,
            },
          },
          infos: {'good_plugin': _info(version: '2.0.0')},
          archives: {
            '2.0.0': _buildArchive({'pubspec.yaml': utf8.encode('name: x')}),
          },
          failingPackages: ['broken_plugin'],
        );

        final result = await assembleSnapshot(client, [
          PluginCandidate(name: 'broken_plugin', tags: ['is:plugin']),
          PluginCandidate(name: 'good_plugin', tags: ['is:plugin']),
        ]);

        expect(result[0].errors, isNotEmpty);
        expect(result[1].name, 'good_plugin');
        expect(result[1].version, '2.0.0');
        expect(result[1].errors, isEmpty);
      },
    );
  });

  group('assembleSnapshot: corrupt archive isolation', () {
    test(
      'a corrupt .tar.gz is recorded as an error, not an aborted run, and '
      'never blocks another plugin in the same run',
      () async {
        final client = _fakePubDev(
          scores: {
            'corrupt_plugin': {
              'tags': ['is:plugin'],
            },
            'good_plugin': {
              'tags': ['is:plugin'],
              'likeCount': 5,
            },
          },
          infos: {
            'corrupt_plugin': _info(version: '1.0.0'),
            'good_plugin': _info(version: '2.0.0'),
          },
          archives: {
            // Looks like a gzip header but decodes to nothing usable —
            // the FormatException a real truncated download raises.
            '1.0.0': [0x1f, 0x8b, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            '2.0.0': _buildArchive({'pubspec.yaml': utf8.encode('name: x')}),
          },
        );

        final result = await assembleSnapshot(client, [
          PluginCandidate(name: 'corrupt_plugin', tags: ['is:plugin']),
          PluginCandidate(name: 'good_plugin', tags: ['is:plugin']),
        ]);

        final corrupt = result[0];
        expect(corrupt.name, 'corrupt_plugin');
        expect(corrupt.swiftpm, isNull);
        expect(corrupt.alignment, isNull);
        expect(corrupt.android, isNull);
        expect(corrupt.errors, isNotEmpty);
        expect(corrupt.errors.any((e) => e.contains('archive decode')), isTrue);

        final good = result[1];
        expect(good.name, 'good_plugin');
        expect(good.version, '2.0.0');
        expect(good.errors, isEmpty);
      },
    );
  });

  group('buildSnapshotJson', () {
    const discovery = DiscoveryInfo(
      method: 'pubdev-search',
      queries: ['is:plugin platform:ios -is:swiftpm-plugin', 'is:plugin'],
      resultsPerQuery: 100,
    );

    test('matches the schemaVersion 1 contract shape', () {
      final generatedAt = DateTime.utc(2026, 9, 27, 2);
      final json = buildSnapshotJson(
        generatedAt: generatedAt,
        discovery: discovery,
        plugins: [
          PluginSnapshot(
            name: 'url_launcher',
            version: '6.3.2',
            published: generatedAt,
            downloadCount30Days: 10,
            likeCount: 5,
            swiftpm: null,
            alignment: null,
            android: null,
            errors: const [],
            search: const ['top-downloads'],
          ),
        ],
      );

      expect(json['schemaVersion'], 1);
      expect(json['generatedAt'], generatedAt.toIso8601String());
      expect(json['discovery'], discovery.toJson());
      final plugin = (json['plugins'] as List).single as Map<String, dynamic>;
      expect(plugin['name'], 'url_launcher');
      expect(plugin['swiftpm'], isNull);
      expect(plugin['errors'], isEmpty);
      expect(plugin['search'], ['top-downloads']);
    });

    test('sorts plugins by downloads, descending', () {
      final generatedAt = DateTime.utc(2026, 9, 27, 2);
      PluginSnapshot plugin(String name, int? downloads) => PluginSnapshot(
        name: name,
        version: '1.0.0',
        published: generatedAt,
        downloadCount30Days: downloads,
        likeCount: 0,
        swiftpm: null,
        alignment: null,
        android: null,
        errors: const [],
      );

      final json = buildSnapshotJson(
        generatedAt: generatedAt,
        discovery: discovery,
        plugins: [
          plugin('low', 10),
          plugin('unknown', null),
          plugin('high', 1000),
        ],
      );

      final names = [
        for (final p in json['plugins'] as List)
          (p as Map<String, dynamic>)['name'],
      ];
      expect(names, ['high', 'low', 'unknown']);
    });
  });
}
