// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/server.dart';
import 'package:site/components/blocked_list.dart' as _blocked_list;
import 'package:site/components/count_tiles.dart' as _count_tiles;
import 'package:site/components/deadlines_panel.dart' as _deadlines_panel;
import 'package:site/components/header.dart' as _header;
import 'package:site/components/headline_panel.dart' as _headline_panel;
import 'package:site/components/hireflutter_cta.dart' as _hireflutter_cta;
import 'package:site/components/plugin_table.dart' as _plugin_table;
import 'package:site/components/status_chip.dart' as _status_chip;
import 'package:site/components/trend_panel.dart' as _trend_panel;
import 'package:site/pages/index_page.dart' as _index_page;
import 'package:site/pages/plugin_page.dart' as _plugin_page;
import 'package:site/app.dart' as _app;

/// Default [ServerOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.server.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultServerOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ServerOptions get defaultServerOptions => ServerOptions(
  clientId: 'main.client.dart.js',
  styles: () => [
    ..._app.App.styles,
    ..._blocked_list.BlockedList.styles,
    ..._count_tiles.CountTiles.styles,
    ..._deadlines_panel.DeadlinesPanel.styles,
    ..._header.Header.styles,
    ..._headline_panel.HeadlinePanel.styles,
    ..._hireflutter_cta.HireFlutterCta.styles,
    ..._plugin_table.PluginTable.styles,
    ..._status_chip.StatusChip.styles,
    ..._trend_panel.TrendPanel.styles,
    ..._index_page.IndexPage.styles,
    ..._plugin_page.PluginPage.styles,
  ],
);
