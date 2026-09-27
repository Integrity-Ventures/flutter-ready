import 'package:site/data/board.dart';
import 'package:site/data/models.dart';
import 'package:test/test.dart';

PluginEntry _plugin({
  required String name,
  bool? tag,
  bool? archive,
  bool? nativeIos,
  int? downloadCount30Days,
  List<String> errors = const [],
}) {
  return PluginEntry(
    name: name,
    version: '1.0.0',
    published: null,
    downloadCount30Days: downloadCount30Days,
    likeCount: null,
    swiftpm: SwiftPmInfo(
      tag: tag,
      archive: archive,
      agrees: tag == archive,
      checkedPackage: '${name}_ios',
      nativeIos: nativeIos,
    ),
    alignment: const AlignmentInfo(checkedPackage: null, soFiles: []),
    android: const AndroidInfo(checkedPackage: null, compileSdk: null, agp: null, ndk: null),
    errors: errors,
  );
}

void main() {
  group('boardCategoryOf', () {
    test('blocked, unclear, ready and not affected are never merged', () {
      expect(boardCategoryOf(_plugin(name: 'a', tag: false, archive: false)), BoardCategory.blocked);
      expect(boardCategoryOf(_plugin(name: 'b', tag: true, archive: false)), BoardCategory.unclear);
      expect(boardCategoryOf(_plugin(name: 'c', tag: true, archive: true)), BoardCategory.ready);
      expect(
        boardCategoryOf(_plugin(name: 'd', tag: false, archive: false, nativeIos: false)),
        BoardCategory.notAffected,
      );
      expect(
        boardCategoryOf(_plugin(name: 'e', tag: true, archive: true, errors: const ['boom'])),
        BoardCategory.notChecked,
      );
    });
  });

  group('BoardCounts.from', () {
    test('counts every category separately, never merging ready and not affected', () {
      final counts = BoardCounts.from([
        _plugin(name: 'blocked-1', tag: false, archive: false),
        _plugin(name: 'unclear-1', tag: true, archive: false),
        _plugin(name: 'ready-1', tag: true, archive: true),
        _plugin(name: 'not-affected-1', tag: false, archive: false, nativeIos: false),
        _plugin(name: 'not-checked-1', tag: true, archive: true, errors: const ['boom']),
      ]);

      expect(counts.blocked, 1);
      expect(counts.unclear, 1);
      expect(counts.ready, 1);
      expect(counts.notAffected, 1);
      expect(counts.notChecked, 1);
      expect(counts.total, 5);
    });
  });

  group('buildBoardRows', () {
    test('sorts red before amber, before grey (not checked), before green', () {
      final rows = buildBoardRows([
        _plugin(name: 'green', tag: true, archive: true, downloadCount30Days: 100),
        _plugin(name: 'grey', tag: true, archive: true, errors: const ['boom'], downloadCount30Days: 100),
        _plugin(name: 'amber', tag: true, archive: false, downloadCount30Days: 100),
        _plugin(name: 'red', tag: false, archive: false, downloadCount30Days: 100),
      ]);

      expect(rows.map((r) => r.plugin.name).toList(), ['red', 'amber', 'grey', 'green']);
    });

    test('sorts by downloads descending within a category', () {
      final rows = buildBoardRows([
        _plugin(name: 'red-small', tag: false, archive: false, downloadCount30Days: 10),
        _plugin(name: 'red-big', tag: false, archive: false, downloadCount30Days: 1000),
        _plugin(name: 'red-medium', tag: false, archive: false, downloadCount30Days: 500),
      ]);

      expect(rows.map((r) => r.plugin.name).toList(), ['red-big', 'red-medium', 'red-small']);
    });

    test('download rank is independent of the category-grouped table order', () {
      final rows = buildBoardRows([
        _plugin(name: 'green-top', tag: true, archive: true, downloadCount30Days: 1000),
        _plugin(name: 'red-bottom', tag: false, archive: false, downloadCount30Days: 10),
      ]);

      final red = rows.firstWhere((r) => r.plugin.name == 'red-bottom');
      expect(red.downloadRank, 2);
    });

    test(
      'stays correct and fast at 1000 plugins (SPEC: "the page must still build and stay usable with N = 1000")',
      () {
        final plugins = [
          for (var i = 0; i < 1000; i++)
            _plugin(
              name: 'plugin_$i',
              tag: i % 4 == 0,
              archive: i % 4 == 0 || i % 4 == 1,
              nativeIos: i % 10 == 0 ? false : null,
              downloadCount30Days: 1000000 - i,
            ),
        ];

        final stopwatch = Stopwatch()..start();
        final rows = buildBoardRows(plugins);
        stopwatch.stop();

        expect(rows, hasLength(1000));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));

        // Every red row must sort before every amber row, before every grey
        // row, before every green row — with 1000 mixed-category plugins this
        // would fail immediately if a boundary were off by one.
        final ranks = rows
            .map(
              (r) => switch (r.category) {
                BoardCategory.blocked => 0,
                BoardCategory.unclear => 1,
                BoardCategory.notChecked => 2,
                BoardCategory.ready || BoardCategory.notAffected => 3,
              },
            )
            .toList();
        for (var i = 1; i < ranks.length; i++) {
          expect(ranks[i], greaterThanOrEqualTo(ranks[i - 1]));
        }
      },
    );
  });

  group('headlineText', () {
    test('names the blocked count when there are blocked plugins', () {
      final blocked = [_plugin(name: 'flutter_tts', tag: false, archive: false, downloadCount30Days: 100)];
      expect(
        headlineText(blocked: blocked, totalPlugins: 146),
        '1 of the 146 most-downloaded iOS plugins checked here '
        'still block iOS apps before CocoaPods goes read-only on 2 Dec 2026.',
      );
    });

    test('says so plainly when there are none', () {
      expect(
        headlineText(blocked: const [], totalPlugins: 146),
        'No plugin among the 146 most-downloaded iOS plugins checked here blocks iOS apps today.',
      );
    });
  });

  group('formatDownloads', () {
    test('groups digits by thousands', () {
      expect(formatDownloads(1197182), '1,197,182');
      expect(formatDownloads(959251), '959,251');
      expect(formatDownloads(100), '100');
    });

    test('shows an em dash for an unknown download count', () {
      expect(formatDownloads(null), '—');
    });
  });
}
