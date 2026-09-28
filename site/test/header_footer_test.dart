import 'dart:convert';

import 'package:jaspr/server.dart';
import 'package:site/components/footer.dart';
import 'package:site/components/header.dart';
import 'package:site/components/hero.dart';
import 'package:test/test.dart';

Future<String> _renderToHtml(Component component) async {
  final response = await renderComponent(component);
  return utf8.decode(response.body);
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
  });
}
