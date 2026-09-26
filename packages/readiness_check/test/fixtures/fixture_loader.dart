// Loads the recorded fixtures under test/fixtures/ so tests never need to
// call the network (SPEC §5). Paths are relative to the package root, which
// is `dart test`'s working directory (see .github/workflows/ci.yml).
import 'dart:convert';
import 'dart:io';

const _fixturesDir = 'test/fixtures';

/// Raw bytes of a fixture file, e.g. `fixtureBytes('archives/url_launcher_ios.tar.gz')`.
List<int> fixtureBytes(String relativePath) =>
    File('$_fixturesDir/$relativePath').readAsBytesSync();

/// A recorded pub.dev API response, decoded as JSON, e.g.
/// `fixtureJson('pub_dev/url_launcher_score.json')`.
Map<String, dynamic> fixtureJson(String relativePath) =>
    jsonDecode(File('$_fixturesDir/$relativePath').readAsStringSync())
        as Map<String, dynamic>;

/// The `tags` list from a recorded `.../score.json` fixture.
List<String> fixtureTags(String packageName) =>
    (fixtureJson('pub_dev/${packageName}_score.json')['tags'] as List)
        .cast<String>();
