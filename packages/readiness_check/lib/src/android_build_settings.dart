import 'dart:convert';

/// Android build settings a plugin declares for itself in its own
/// `android/build.gradle` (or `build.gradle.kts`) (SPEC §3.1.2).
///
/// Each field is the raw declared value, quotes stripped, or null when the
/// setting isn't present. A value may be an unresolved expression such as
/// `flutter.compileSdkVersion` rather than a literal — the caller decides
/// what that means. No pass/fail/colour grading is attached here (SPEC open
/// decision 3 is unresolved).
class AndroidBuildSettings {
  const AndroidBuildSettings({
    this.compileSdk,
    this.agpVersion,
    this.ndkVersion,
  });

  final String? compileSdk;
  final String? agpVersion;
  final String? ndkVersion;
}

/// Whether [path] is one of the two Gradle files a plugin's Android build
/// settings can be declared in, at the archive root.
bool isAndroidGradleFilePath(String path) =>
    path == 'android/build.gradle' || path == 'android/build.gradle.kts';

final _compileSdkPattern = RegExp(r'compileSdk(?:Version)?\s*=?\s*([^\n]+)');
final _ndkVersionPattern = RegExp(r'ndkVersion\s*=?\s*([^\n]+)');
final _agpClasspathPattern = RegExp(
  r'''classpath\s*\(?\s*['"]com\.android\.tools\.build:gradle:([^'"]+)['"]''',
);
final _agpPluginsDslPattern = RegExp(
  r'''id\(\s*['"]com\.android\.(?:application|library)['"]\s*\)\s*version\s*['"]([^'"]+)['"]''',
);

/// Reads the Android build settings from whichever of `android/build.gradle`
/// / `android/build.gradle.kts` is present in [androidGradleFileContents]
/// (as produced by `extractArchiveEntries(bytes, isAndroidGradleFilePath)`).
///
/// Returns null when neither file is present.
AndroidBuildSettings? extractAndroidBuildSettings(
  Map<String, List<int>> androidGradleFileContents,
) {
  final content =
      androidGradleFileContents['android/build.gradle'] ??
      androidGradleFileContents['android/build.gradle.kts'];
  if (content == null) return null;

  final text = _stripLineComments(utf8.decode(content));
  return AndroidBuildSettings(
    compileSdk: _firstMatch(_compileSdkPattern, text),
    agpVersion:
        _firstMatch(_agpClasspathPattern, text) ??
        _firstMatch(_agpPluginsDslPattern, text),
    ndkVersion: _firstMatch(_ndkVersionPattern, text),
  );
}

String _stripLineComments(String text) {
  return text
      .split('\n')
      .map((line) {
        final index = line.indexOf('//');
        return index == -1 ? line : line.substring(0, index);
      })
      .join('\n');
}

String? _firstMatch(RegExp pattern, String text) {
  final match = pattern.firstMatch(text);
  if (match == null) return null;
  return _clean(match.group(1)!);
}

String _clean(String raw) {
  var value = raw.trim();
  if (value.startsWith('(') && value.endsWith(')')) {
    value = value.substring(1, value.length - 1).trim();
  }
  value = value.replaceAll(RegExp(r'[,;]+$'), '').trim();
  final isDoubleQuoted = value.startsWith('"') && value.endsWith('"');
  final isSingleQuoted = value.startsWith("'") && value.endsWith("'");
  if ((isDoubleQuoted || isSingleQuoted) && value.length >= 2) {
    value = value.substring(1, value.length - 1);
  }
  return value;
}
