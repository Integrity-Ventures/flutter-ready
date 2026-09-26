/// Reads the shared `data/` directory (one level up from this package,
/// per the architect's shared layout) at pre-render time. Server-only:
/// must never be imported by `main.client.dart`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'models.dart';

String get _dataDirPath => p.join(Directory.current.path, '..', 'data');

Future<Snapshot> loadLatestSnapshot() async {
  final file = File(p.join(_dataDirPath, 'latest.json'));
  return Snapshot.fromJson(jsonDecode(await file.readAsString()) as Map<String, dynamic>);
}

/// All dated snapshots under `data/snapshots/`, oldest first, for the trend view.
Future<List<DatedSnapshot>> loadAllSnapshots() async {
  final dir = Directory(p.join(_dataDirPath, 'snapshots'));
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  return [
    for (final file in files)
      DatedSnapshot(
        date: p.basenameWithoutExtension(file.path),
        snapshot: Snapshot.fromJson(jsonDecode(await file.readAsString()) as Map<String, dynamic>),
      ),
  ];
}

Future<List<Deadline>> loadDeadlines() async {
  final file = File(p.join(_dataDirPath, 'deadlines.json'));
  final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  return [for (final d in (json['deadlines'] as List)) Deadline.fromJson(d as Map<String, dynamic>)];
}
