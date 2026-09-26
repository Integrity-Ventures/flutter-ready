import 'package:flutter_ready/flutter_ready.dart';
import 'package:test/test.dart';

void main() {
  test('parses hosted, git and path sources', () {
    const contents = '''
packages:
  url_launcher:
    dependency: "direct main"
    description:
      name: url_launcher
      url: "https://pub.dev"
    source: hosted
    version: "6.3.2"
  my_fork:
    dependency: "direct main"
    description:
      url: "https://github.com/example/my_fork.git"
    source: git
    version: "1.0.0"
  my_local_pkg:
    dependency: "direct main"
    description:
      path: "../my_local_pkg"
      relative: true
    source: path
    version: "0.0.1"
sdks:
  dart: ">=3.13.0 <4.0.0"
''';

    final locked = parsePubspecLock(contents);

    expect(locked, hasLength(3));
    final byName = {for (final p in locked) p.name: p};
    expect(byName['url_launcher']!.isHosted, isTrue);
    expect(byName['url_launcher']!.version, '6.3.2');
    expect(byName['my_fork']!.isHosted, isFalse);
    expect(byName['my_local_pkg']!.isHosted, isFalse);
  });

  test('a lockfile with no packages returns an empty list', () {
    expect(parsePubspecLock('sdks:\n  dart: ">=3.13.0 <4.0.0"\n'), isEmpty);
  });
}
