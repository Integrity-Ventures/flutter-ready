/// The entrypoint for the **server** environment.
///
/// The [main] method will only be executed on the server during pre-rendering.
/// To run code on the client, check the `main.client.dart` file.
library;

import 'package:jaspr/dom.dart';
// Server-specific Jaspr import.
import 'package:jaspr/server.dart';

// Imports the [App] component.
import 'app.dart';
import 'constants/theme.dart';

// This file is generated automatically by Jaspr, do not remove or edit.
import 'main.server.options.dart';

void main() {
  // Initializes the server environment with the generated default options.
  Jaspr.initializeApp(
    options: defaultServerOptions,
  );

  // Starts the app.
  //
  // [Document] renders the root document structure (<html>, <head> and <body>)
  // with the provided parameters and components.
  runApp(
    Document(
      title: 'Flutter Ready',
      meta: {
        'description':
            'Is your Flutter plugin ready for CocoaPods going read-only and Play\'s API 36 and '
            '16 KB alignment rules?',
      },
      styles: [
        // Special import rule to include to another css file. One web font
        // family (SPEC: first load must not get heavier than that), Inter,
        // matching the new HireFlutter site.
        css.import('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap'),
        // Each style rule takes a valid css selector and a set of styles.
        // Styles are defined using type-safe css bindings and can be freely chained and nested.
        css('html, body').styles(
          width: 100.percent,
          minHeight: 100.vh,
          padding: .zero,
          margin: .zero,
          color: brandNavy,
          fontFamily: const .list([FontFamily(fontFamilyName), FontFamilies.sansSerif]),
          backgroundColor: surfacePage,
        ),
        css('h1').styles(
          margin: .unset,
          fontSize: 2.rem,
        ),
      ],
      body: App(),
    ),
  );
}
