import 'package:yaml/yaml.dart';

/// One resolved dependency from a `pubspec.lock`'s `packages:` map.
class LockedPackage {
  const LockedPackage({required this.name, required this.version, required this.isHosted});

  final String name;
  final String version;

  /// Whether this package's `source` is `hosted` (pub.dev). Git, path and
  /// SDK dependencies aren't in the Flutter Ready data and are skipped.
  final bool isHosted;
}

/// Parses a `pubspec.lock`'s `packages:` map (SPEC §3.3).
List<LockedPackage> parsePubspecLock(String contents) {
  final doc = loadYaml(contents);
  final packages = doc is YamlMap ? doc['packages'] : null;
  if (packages is! YamlMap) return const [];

  return [
    for (final entry in packages.entries)
      LockedPackage(
        name: entry.key as String,
        version: (entry.value as YamlMap)['version'] as String,
        isHosted: (entry.value as YamlMap)['source'] == 'hosted',
      ),
  ];
}
