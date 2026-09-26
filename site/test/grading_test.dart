import 'package:site/data/grading.dart';
import 'package:site/data/models.dart';
import 'package:test/test.dart';

PluginEntry _plugin({
  bool? tag,
  bool? archive,
  List<SoFile> soFiles = const [],
  List<String> errors = const [],
}) {
  return PluginEntry(
    name: 'example',
    version: '1.0.0',
    published: null,
    downloadCount30Days: null,
    likeCount: null,
    swiftpm: SwiftPmInfo(tag: tag, archive: archive, agrees: tag == archive, checkedPackage: 'example_ios'),
    alignment: AlignmentInfo(checkedPackage: 'example_android', soFiles: soFiles),
    android: const AndroidInfo(checkedPackage: null, compileSdk: null, agp: null, ndk: null),
    errors: errors,
  );
}

void main() {
  group('swiftPmStatus', () {
    test('green when tag and archive both ready', () {
      expect(swiftPmStatus(_plugin(tag: true, archive: true)), Status.green);
    });

    test('red when both not ready', () {
      expect(swiftPmStatus(_plugin(tag: false, archive: false)), Status.red);
    });

    test('amber when tag and archive disagree', () {
      expect(swiftPmStatus(_plugin(tag: true, archive: false)), Status.amber);
      expect(swiftPmStatus(_plugin(tag: false, archive: true)), Status.amber);
    });

    test('not checked when a signal is missing or the plugin has errors', () {
      expect(swiftPmStatus(_plugin(tag: null, archive: true)), Status.notChecked);
      expect(swiftPmStatus(_plugin(tag: true, archive: true, errors: const ['boom'])), Status.notChecked);
    });
  });

  group('alignmentStatus', () {
    test('green when there are no .so files', () {
      expect(alignmentStatus(_plugin()), Status.green);
    });

    test('green when every .so file is aligned', () {
      final soFiles = [const SoFile(path: 'a.so', aligned: true, minAlign: 0x4000)];
      expect(alignmentStatus(_plugin(soFiles: soFiles)), Status.green);
    });

    test('red when any .so file is misaligned', () {
      final soFiles = [
        const SoFile(path: 'a.so', aligned: true, minAlign: 0x4000),
        const SoFile(path: 'b.so', aligned: false, minAlign: 0x1000),
      ];
      expect(alignmentStatus(_plugin(soFiles: soFiles)), Status.red);
    });

    test('not checked when the plugin has errors', () {
      expect(alignmentStatus(_plugin(errors: const ['boom'])), Status.notChecked);
    });
  });

  group('isBlocked', () {
    test('true when SwiftPM is red', () {
      expect(isBlocked(_plugin(tag: false, archive: false)), isTrue);
    });

    test('true when alignment is red', () {
      final soFiles = [const SoFile(path: 'a.so', aligned: false, minAlign: 0x1000)];
      expect(isBlocked(_plugin(tag: true, archive: true, soFiles: soFiles)), isTrue);
    });

    test('false when neither check is red', () {
      expect(isBlocked(_plugin(tag: true, archive: true)), isFalse);
    });

    test('false when a check is amber, not red', () {
      expect(isBlocked(_plugin(tag: true, archive: false)), isFalse);
    });
  });

  group('swiftPmGreenSharePercent', () {
    test('null when no plugin has a known status', () {
      expect(
        swiftPmGreenSharePercent([
          _plugin(errors: const ['boom']),
        ]),
        isNull,
      );
    });

    test('counts only plugins with a known status', () {
      final plugins = [
        _plugin(tag: true, archive: true), // green
        _plugin(tag: false, archive: false), // red
        _plugin(errors: const ['boom']), // excluded
      ];
      expect(swiftPmGreenSharePercent(plugins), 50);
    });
  });
}
