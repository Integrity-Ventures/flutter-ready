import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:flutter_ready/readiness_check.dart'
    show Deadline, PubDevClient, Snapshot;

import 'check_report.dart';
import 'live_check.dart';
import 'pubspec_lock.dart';
import 'replacements.dart';

const defaultDataSource =
    'https://raw.githubusercontent.com/Integrity-Ventures/flutter-ready/main/data/latest.json';

/// Sent on every live-check request to pub.dev (CLI live-check task,
/// 2026-09-27): a descriptive User-Agent so pub.dev can identify the traffic.
const _liveCheckUserAgent =
    'flutter_ready-cli (+https://ready.hireflutter.dev)';

/// How many packages [CheckCommand] live-checks at once (CLI live-check
/// task, 2026-09-27).
const _liveCheckConcurrency = 4;

/// `flutter_ready check` (SPEC §3.3): reads `pubspec.lock`, fetches the
/// Flutter Ready data, and prints a report of which plugins block this
/// season's release.
class CheckCommand extends Command<void> {
  CheckCommand() {
    argParser
      ..addOption(
        'data',
        defaultsTo: defaultDataSource,
        help:
            'Path or URL to the readiness data (latest.json). Deadlines are '
            'read from deadlines.json alongside it.',
      )
      ..addOption(
        'lockfile',
        defaultsTo: 'pubspec.lock',
        help: "Path to the app's pubspec.lock.",
      )
      ..addFlag(
        'offline',
        defaultsTo: false,
        help:
            'Never check a plugin live against pub.dev; a plugin the data '
            "doesn't cover at its locked version prints \"not checked\".",
      );
  }

  @override
  final name = 'check';

  @override
  final description =
      "Reports which of this app's plugins block this season's release.";

  @override
  Future<void> run() async {
    final dataSource = argResults!.option('data')!;
    final lockfilePath = argResults!.option('lockfile')!;
    final offline = argResults!.flag('offline');

    final lockfile = File(lockfilePath);
    if (!lockfile.existsSync()) {
      stderr.writeln('flutter_ready check: no pubspec.lock at $lockfilePath.');
      exitCode = 2;
      return;
    }

    final lockedPackages = parsePubspecLock(await lockfile.readAsString());
    final snapshot = Snapshot.fromJson(
      jsonDecode(await _read(dataSource)) as Map<String, dynamic>,
    );
    final deadlinesJson = jsonDecode(
      await _read(_sibling(dataSource, 'deadlines.json')),
    ) as Map<String, dynamic>;
    final deadlines = [
      for (final d in deadlinesJson['deadlines'] as List)
        Deadline.fromJson(d as Map<String, dynamic>),
    ];
    final replacements = await _readReplacements(dataSource);

    final liveResults = offline
        ? const <LiveCheckResult>[]
        : await _runLiveChecks(lockedPackages, snapshot);

    final report = buildCheckReport(
      lockedPackages: lockedPackages,
      snapshot: snapshot,
      deadlines: deadlines,
      replacements: replacements,
      liveResults: liveResults,
    );
    stdout.writeln(report.text);
    exitCode = report.hasBlocker ? 1 : 0;
  }
}

/// The hosted packages a live check would run for: those that aren't in
/// [snapshot] at their exact locked version (CLI live-check task,
/// 2026-09-27) — matches [buildCheckReport]'s own "otherwise" branch.
List<LockedPackage> _packagesNeedingLiveCheck(
  List<LockedPackage> lockedPackages,
  Snapshot snapshot,
) {
  final byName = {for (final plugin in snapshot.plugins) plugin.name: plugin};
  bool matchesData(LockedPackage locked) =>
      byName[locked.name]?.version == locked.version;
  return lockedPackages.where((p) => p.isHosted && !matchesData(p)).toList();
}

Future<List<LiveCheckResult>> _runLiveChecks(
  List<LockedPackage> lockedPackages,
  Snapshot snapshot,
) async {
  final toCheck = _packagesNeedingLiveCheck(lockedPackages, snapshot);
  if (toCheck.isEmpty) return const [];

  final lockedByName = {
    for (final locked in lockedPackages) locked.name: locked,
  };
  final client = PubDevClient(
    httpClient: _UserAgentHttpClient(http.Client(), _liveCheckUserAgent),
  );
  return runLiveChecks(
    client,
    toCheck,
    lockedByName,
    concurrency: _liveCheckConcurrency,
    onProgress: stderr.writeln,
  );
}

/// Wraps an [http.Client] to send [_liveCheckUserAgent] on every request.
class _UserAgentHttpClient extends http.BaseClient {
  _UserAgentHttpClient(this._inner, this._userAgent);

  final http.Client _inner;
  final String _userAgent;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['User-Agent'] = _userAgent;
    return _inner.send(request);
  }
}

/// `data/replacements.json` (SPEC §3.3, open decision 4), hand-kept and
/// read as a sibling of the data source, same as `deadlines.json`. Missing
/// or unfetchable is not fatal — a data source that predates this file, or
/// hosts it nowhere, still produces a report, just without suggestions.
Future<Map<String, List<Replacement>>> _readReplacements(
  String dataSource,
) async {
  try {
    return parseReplacements(
      await _read(_sibling(dataSource, 'replacements.json')),
    );
  } catch (_) {
    return const {};
  }
}

bool _isUrl(String source) =>
    source.startsWith('http://') || source.startsWith('https://');

Future<String> _read(String source) async {
  if (_isUrl(source)) {
    final response = await http.get(Uri.parse(source));
    if (response.statusCode != 200) {
      throw StateError(
        'Could not fetch $source (HTTP ${response.statusCode}).',
      );
    }
    return response.body;
  }
  return File(source).readAsString();
}

/// The file named [fileName] next to [source], whether [source] is a URL or
/// a local path.
String _sibling(String source, String fileName) {
  if (_isUrl(source)) return Uri.parse(source).resolve(fileName).toString();
  return p.join(p.dirname(source), fileName);
}
