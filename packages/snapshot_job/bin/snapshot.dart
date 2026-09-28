import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:flutter_ready/readiness_check.dart';
import 'package:snapshot_job/snapshot_job.dart';

const _userAgent =
    'flutter_ready-snapshot-job '
    '(+https://github.com/Integrity-Ventures/flutter-ready)';

Future<void> main(List<String> arguments) async {
  final args = _parseArgs(arguments);
  final client = PubDevClient(httpClient: _UserAgentClient(http.Client()));

  final stopwatch = Stopwatch()..start();
  final candidates = await discoverFlutterPlugins(
    client,
    resultsPerQuery: args.resultsPerQuery,
  );
  final plugins = await assembleSnapshot(client, candidates);
  stopwatch.stop();

  final generatedAt = DateTime.now().toUtc();
  final snapshot = buildSnapshotJson(
    generatedAt: generatedAt,
    discovery: DiscoveryInfo(
      method: 'pubdev-search',
      queries: [for (final q in discoveryQueries) q.query],
      resultsPerQuery: args.resultsPerQuery,
    ),
    plugins: plugins,
  );
  final encoded = '${const JsonEncoder.withIndent('  ').convert(snapshot)}\n';

  final snapshotsDir = Directory(args.outDir);
  await snapshotsDir.create(recursive: true);
  final dateStamp = generatedAt.toIso8601String().split('T').first;
  await File(p.join(snapshotsDir.path, '$dateStamp.json'))
      .writeAsString(encoded);
  await File(p.join(p.dirname(p.normalize(snapshotsDir.path)), 'latest.json'))
      .writeAsString(encoded);

  stderr.writeln(
    'Assembled ${plugins.length} plugin(s) from ${candidates.length} '
    'candidate(s) in ${stopwatch.elapsed}.',
  );
}

class _SnapshotArgs {
  const _SnapshotArgs({required this.resultsPerQuery, required this.outDir});

  final int resultsPerQuery;
  final String outDir;
}

_SnapshotArgs _parseArgs(List<String> arguments) {
  final parser = ArgParser()
    ..addOption(
      'top',
      defaultsTo: '100',
      help:
          'Results per pub.dev search query, rounded up to pages of 10 '
          '(the API caps a single query at 100).',
    )
    ..addOption(
      'out',
      defaultsTo: 'data/snapshots/',
      help: 'Directory for the dated snapshot file.',
    );
  final results = parser.parse(arguments);
  return _SnapshotArgs(
    resultsPerQuery: int.parse(results.option('top')!),
    outDir: results.option('out')!,
  );
}

/// Sends a descriptive User-Agent on every pub.dev request, per the
/// architect note for e2-s1.
class _UserAgentClient extends http.BaseClient {
  _UserAgentClient(this._inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['user-agent'] = _userAgent;
    return _inner.send(request);
  }
}
