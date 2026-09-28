// Tests runLiveChecks (CLI live-check task, 2026-09-27) against a MockClient
// fed with the e6-s1 fixtures from test/fixtures/ (recorded pub.dev
// responses and archives) — never the real network. The
// "latest" object those fixtures record is the same shape
// GET /api/packages/<name>/versions/<version> returns, just wrapped.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_ready/flutter_ready.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_ready/readiness_check.dart';
import 'package:test/test.dart';

const _fixturesDir = 'test/fixtures';

Map<String, dynamic> _fixtureJson(String relativePath) =>
    jsonDecode(File('$_fixturesDir/$relativePath').readAsStringSync()) as Map<String, dynamic>;

List<int> _fixtureBytes(String relativePath) => File('$_fixturesDir/$relativePath').readAsBytesSync();

/// The recorded `pub_dev/<package>_info.json` fixture's `latest` object —
/// the same shape a version-specific pub.dev response has.
Map<String, dynamic> _versionResponse(String packageName) =>
    Map<String, dynamic>.from(_fixtureJson('pub_dev/${packageName}_info.json')['latest'] as Map);

/// A [PubDevClient] backed by [responsesByPath] (JSON bodies or raw bytes),
/// recording every request path it sees in [requestedPaths].
PubDevClient _mockClient(Map<String, Object> responsesByPath, {List<String>? requestedPaths}) {
  final mock = MockClient((request) async {
    requestedPaths?.add(request.url.path);
    final body = responsesByPath[request.url.path];
    if (body == null) return http.Response('not found', 404);
    if (body is List<int>) return http.Response.bytes(body, 200);
    return http.Response(jsonEncode(body), 200);
  });
  return PubDevClient(httpClient: mock, baseUri: Uri.parse('https://pub.dev'));
}

void main() {
  test('an unfederated plugin with no Package.swift is a live blocker', () async {
    final locked = LockedPackage(name: 'flutter_barcode_scanner', version: '2.0.0', isHosted: true);
    final client = _mockClient({
      '/api/packages/flutter_barcode_scanner/versions/2.0.0': _versionResponse('flutter_barcode_scanner'),
      '/api/archives/flutter_barcode_scanner-2.0.0.tar.gz': _fixtureBytes('archives/flutter_barcode_scanner.tar.gz'),
    });

    final results = await runLiveChecks(client, [locked], {locked.name: locked});

    expect(results, hasLength(1));
    final result = results.single;
    expect(result.isPlugin, isTrue);
    expect(result.notCheckedReason, isNull);
    expect(result.checkedPackage, 'flutter_barcode_scanner');
    expect(result.grade!.swiftPm, Status.red);
  });

  test('an unfederated plugin with Package.swift is ready', () async {
    final locked = LockedPackage(name: 'url_launcher_ios', version: '6.4.2', isHosted: true);
    final client = _mockClient({
      '/api/packages/url_launcher_ios/versions/6.4.2': _versionResponse('url_launcher_ios'),
      '/api/archives/url_launcher_ios-6.4.2.tar.gz': _fixtureBytes('archives/url_launcher_ios.tar.gz'),
    });

    final results = await runLiveChecks(client, [locked], {locked.name: locked});

    expect(results.single.grade!.swiftPm, Status.green);
  });

  test('a pure Dart package is skipped without ever fetching its archive', () async {
    final locked = LockedPackage(name: 'some_dart_pkg', version: '1.0.0', isHosted: true);
    final requestedPaths = <String>[];
    final client = _mockClient({
      '/api/packages/some_dart_pkg/versions/1.0.0': {
        'version': '1.0.0',
        'published': '2026-01-01T00:00:00Z',
        'archive_url': 'https://pub.dev/api/archives/some_dart_pkg-1.0.0.tar.gz',
        'pubspec': {'name': 'some_dart_pkg'},
      },
    }, requestedPaths: requestedPaths);

    final results = await runLiveChecks(client, [locked], {locked.name: locked});

    expect(results.single.isPlugin, isFalse);
    expect(results.single.grade, isNull);
    expect(requestedPaths, isNot(contains('/api/archives/some_dart_pkg-1.0.0.tar.gz')));
  });

  test('a federated plugin is checked at its locked _ios version, not latest', () async {
    final appLocked = LockedPackage(name: 'url_launcher', version: '6.3.2', isHosted: true);
    final iosLocked = LockedPackage(name: 'url_launcher_ios', version: '6.4.1', isHosted: true);
    final lockedIosResponse = Map<String, dynamic>.from(_versionResponse('url_launcher_ios'))
      ..['version'] = '6.4.1'
      ..['archive_url'] = 'https://pub.dev/api/archives/url_launcher_ios-6.4.1.tar.gz';
    final requestedPaths = <String>[];
    final client = _mockClient({
      '/api/packages/url_launcher/versions/6.3.2': _versionResponse('url_launcher'),
      '/api/packages/url_launcher_ios/versions/6.4.1': lockedIosResponse,
      // The fixture's own recorded (unlocked) "latest" archive — a live
      // check that ignored the locked version and fell back to the latest
      // would fetch this one instead, and this test would still pass
      // unless we assert requestedPaths never touches it.
      '/api/archives/url_launcher_ios-6.4.1.tar.gz': _fixtureBytes('archives/url_launcher_ios.tar.gz'),
    }, requestedPaths: requestedPaths);

    final results = await runLiveChecks(client, [appLocked], {
      appLocked.name: appLocked,
      iosLocked.name: iosLocked,
    });

    expect(results.single.grade!.swiftPm, Status.green);
    expect(results.single.checkedPackage, 'url_launcher_ios');
    expect(results.single.usedFallbackLatest, isFalse);
    expect(requestedPaths, contains('/api/packages/url_launcher_ios/versions/6.4.1'));
    expect(requestedPaths, isNot(contains('/api/packages/url_launcher_ios/versions/6.4.2')));
    expect(requestedPaths, isNot(contains('/api/packages/url_launcher_ios')));
  });

  test('a federated plugin whose platform package is not locked falls back to latest', () async {
    final appLocked = LockedPackage(name: 'url_launcher', version: '6.3.2', isHosted: true);
    final client = _mockClient({
      '/api/packages/url_launcher/versions/6.3.2': _versionResponse('url_launcher'),
      '/api/packages/url_launcher_ios': _fixtureJson('pub_dev/url_launcher_ios_info.json'),
      '/api/archives/url_launcher_ios-6.4.2.tar.gz': _fixtureBytes('archives/url_launcher_ios.tar.gz'),
    });

    final results = await runLiveChecks(client, [appLocked], {appLocked.name: appLocked});

    expect(results.single.usedFallbackLatest, isTrue);
    expect(results.single.grade!.swiftPm, Status.green);
  });

  test('a corrupt archive is "not checked", with no crash', () async {
    final locked = LockedPackage(name: 'some_corrupt_plugin', version: '1.0.0', isHosted: true);
    final client = _mockClient({
      '/api/packages/some_corrupt_plugin/versions/1.0.0': {
        'version': '1.0.0',
        'published': '2026-01-01T00:00:00Z',
        'archive_url': 'https://pub.dev/api/archives/some_corrupt_plugin-1.0.0.tar.gz',
        'pubspec': {
          'name': 'some_corrupt_plugin',
          'flutter': {
            'plugin': {
              'platforms': {
                'ios': {'pluginClass': 'SomeCorruptPlugin'},
              },
            },
          },
        },
      },
      '/api/archives/some_corrupt_plugin-1.0.0.tar.gz': utf8.encode('not actually a tar.gz'),
    });

    final results = await runLiveChecks(client, [locked], {locked.name: locked});

    expect(results.single.grade, isNull);
    expect(results.single.notCheckedReason, isNotNull);
  });

  test('a 404 (plugin not published at the locked version) is "not checked"', () async {
    final locked = LockedPackage(name: 'never_published_at_this_version', version: '9.9.9', isHosted: true);
    final client = _mockClient(const {});

    final results = await runLiveChecks(client, [locked], {locked.name: locked});

    expect(results.single.notCheckedReason, contains('404'));
  });
}
