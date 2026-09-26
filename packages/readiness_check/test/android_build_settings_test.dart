import 'dart:convert';

import 'package:readiness_check/readiness_check.dart';
import 'package:test/test.dart';

Map<String, List<int>> _gradleContents(String path, String text) {
  return {path: utf8.encode(text)};
}

void main() {
  group('isAndroidGradleFilePath', () {
    test('matches the Groovy and Kotlin DSL gradle files', () {
      expect(isAndroidGradleFilePath('android/build.gradle'), isTrue);
      expect(isAndroidGradleFilePath('android/build.gradle.kts'), isTrue);
    });

    test('does not match other paths', () {
      expect(
        isAndroidGradleFilePath('android/src/main/AndroidManifest.xml'),
        isFalse,
      );
      expect(isAndroidGradleFilePath('build.gradle'), isFalse);
    });
  });

  group('extractAndroidBuildSettings', () {
    test(
      'Groovy build.gradle: call-form compileSdk/ndkVersion, AGP via classpath',
      () {
        const gradle = '''
        buildscript {
            dependencies {
                classpath 'com.android.tools.build:gradle:7.3.0'
            }
        }
        android {
            compileSdkVersion 34
            defaultConfig {
                ndkVersion "25.1.8937393"
            }
        }
      ''';

        final settings = extractAndroidBuildSettings(
          _gradleContents('android/build.gradle', gradle),
        );

        expect(settings, isNotNull);
        expect(settings!.compileSdk, '34');
        expect(settings.ndkVersion, '25.1.8937393');
        expect(settings.agpVersion, '7.3.0');
      },
    );

    test('Kotlin DSL build.gradle.kts: assignment-form compileSdk/ndkVersion, AGP via plugins DSL', () {
      const gradle = '''
        plugins {
            id("com.android.library") version "8.1.0"
        }
        android {
            compileSdk = 34
            ndkVersion = "25.1.8937393"
        }
      ''';

      final settings = extractAndroidBuildSettings(
        _gradleContents('android/build.gradle.kts', gradle),
      );

      expect(settings, isNotNull);
      expect(settings!.compileSdk, '34');
      expect(settings.ndkVersion, '25.1.8937393');
      expect(settings.agpVersion, '8.1.0');
    });

    test('an unresolved expression is recorded verbatim, not dropped', () {
      const gradle = '''
        android {
            compileSdk = flutter.compileSdkVersion
            ndkVersion = flutter.ndkVersion
        }
      ''';

      final settings = extractAndroidBuildSettings(
        _gradleContents('android/build.gradle.kts', gradle),
      );

      expect(settings, isNotNull);
      expect(settings!.compileSdk, 'flutter.compileSdkVersion');
      expect(settings.ndkVersion, 'flutter.ndkVersion');
    });

    test('a commented-out setting is not matched', () {
      const gradle = '''
        android {
            // compileSdk 34
            compileSdk 35
        }
      ''';

      final settings = extractAndroidBuildSettings(
        _gradleContents('android/build.gradle', gradle),
      );

      expect(settings, isNotNull);
      expect(settings!.compileSdk, '35');
    });

    test('AGP absent is null while other fields are still populated', () {
      const gradle = '''
        android {
            compileSdkVersion 34
            defaultConfig {
                ndkVersion "25.1.8937393"
            }
        }
      ''';

      final settings = extractAndroidBuildSettings(
        _gradleContents('android/build.gradle', gradle),
      );

      expect(settings, isNotNull);
      expect(settings!.agpVersion, isNull);
      expect(settings.compileSdk, '34');
      expect(settings.ndkVersion, '25.1.8937393');
    });

    test('neither gradle file present returns null', () {
      final settings = extractAndroidBuildSettings({
        'lib/some_plugin.dart': utf8.encode('// not a gradle file'),
      });

      expect(settings, isNull);
    });
  });
}
