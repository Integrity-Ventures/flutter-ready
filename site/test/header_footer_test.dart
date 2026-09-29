import 'dart:convert';

import 'package:jaspr/server.dart';
import 'package:site/components/cli_box.dart';
import 'package:site/components/footer.dart';
import 'package:site/components/header.dart';
import 'package:site/components/headline_panel.dart';
import 'package:site/components/hero.dart';
import 'package:site/data/board.dart';
import 'package:site/data/models.dart';
import 'package:site/pages/plugin_page.dart';
import 'package:test/test.dart';

Future<String> _renderToHtml(Component component) async {
  final response = await renderComponent(component);
  return utf8.decode(response.body);
}

PluginEntry _plugin({required String name}) {
  return PluginEntry(
    name: name,
    version: '1.0.0',
    published: null,
    downloadCount30Days: null,
    likeCount: null,
    swiftpm: const SwiftPmInfo(tag: true, archive: true, agrees: true, checkedPackage: 'plugin_ios'),
    alignment: const AlignmentInfo(checkedPackage: null, soFiles: []),
    android: const AndroidInfo(checkedPackage: null, compileSdk: null, agp: null, ndk: null),
    errors: const [],
  );
}

void main() {
  setUpAll(() {
    Jaspr.initializeApp();
  });

  group('Header (the one-row top bar every page shares)', () {
    test('renders the HireFlutter.dev wordmark linking home and the Powered by 10xs pill', () async {
      final html = await _renderToHtml(const Header());

      expect(html, contains('HireFlutter.dev'));
      expect(html, contains('href="https://hireflutter.dev/"'));
      expect(html, contains('Powered by 10xs'));
    });
  });

  group('Hero (the page title plus one line of explanation)', () {
    test('renders the Flutter Ready title and the given subtitle', () async {
      final html = await _renderToHtml(const Hero(subtitle: 'Is example_plugin ready?'));

      expect(html, contains('Flutter Ready'));
      expect(html, contains('Is example_plugin ready?'));
    });
  });

  group('Footer (the company credit on every page)', () {
    test('renders "Integrity Ventures Private Limited" linking to ivp.life', () async {
      final html = await _renderToHtml(const Footer());

      expect(html, contains('Integrity Ventures Private Limited'));
      expect(html, contains('href="https://ivp.life"'));
    });

    test('renders the open-source and GitHub source line', () async {
      final html = await _renderToHtml(const Footer());

      expect(html, contains('Source on GitHub'));
      expect(html, contains('href="https://github.com/Integrity-Ventures/flutter-ready"'));
    });

    test('links flutter_ready on pub.dev (owner request 2026-09-29)', () async {
      final html = await _renderToHtml(const Footer());

      expect(html, contains('flutter_ready on pub.dev'));
      expect(html, contains('href="https://pub.dev/packages/flutter_ready"'));
    });
  });

  group('CliBox ("Check your own app" box on the board)', () {
    test('renders the install command and both links', () async {
      final html = await _renderToHtml(const CliBox());

      expect(html, contains('Check your own app'));
      expect(html, contains('dart pub global activate flutter_ready'));
      expect(html, contains('flutter_ready check'));
      expect(html, contains('flutter_ready on pub.dev'));
      expect(html, contains('href="https://pub.dev/packages/flutter_ready"'));
      expect(html, contains('Use it in CI (GitHub Action)'));
      expect(
        html,
        contains('href="https://github.com/Integrity-Ventures/flutter-ready#github-action"'),
      );
    });
  });

  group('HeadlinePanel (tiles, CLI box, then the blocked-plugins list)', () {
    test('sits the CliBox right after the tiles and before the blocked list', () async {
      const counts = BoardCounts(blocked: 1, unclear: 0, ready: 0, notAffected: 0, notChecked: 0);
      final html = await _renderToHtml(HeadlinePanel(blocked: [_plugin(name: 'flutter_tts')], counts: counts));

      expect(html, contains('Check your own app'));
      expect(html, contains('Blocked plugins'));
      expect(html.indexOf('count-tiles'), lessThan(html.indexOf('Check your own app')));
      expect(html.indexOf('Check your own app'), lessThan(html.indexOf('Blocked plugins')));
    });

    test('still renders the CliBox when there are no blocked plugins', () async {
      const counts = BoardCounts(blocked: 0, unclear: 0, ready: 1, notAffected: 0, notChecked: 0);
      final html = await _renderToHtml(HeadlinePanel(blocked: const [], counts: counts));

      expect(html, contains('Check your own app'));
      expect(html, isNot(contains('Blocked plugins')));
    });
  });

  group('PluginPage (the CLI nudge under the pub.dev link)', () {
    test('links the flutter_ready CLI on pub.dev', () async {
      final html = await _renderToHtml(PluginPage(plugin: _plugin(name: 'path_provider')));

      expect(html, contains('Check all of your app\'s plugins at once with the'));
      expect(html, contains('flutter_ready CLI'));
      expect(html, contains('href="https://pub.dev/packages/flutter_ready"'));
    });
  });
}
