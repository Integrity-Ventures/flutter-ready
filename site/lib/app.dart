import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'components/header.dart';
import 'data/data_source.dart';
import 'pages/index_page.dart';
import 'pages/plugin_page.dart';

/// The root of the site: a fixed header plus a multi-page [Router] between
/// the index board and one page per plugin (`/p/<name>`), so each plugin is
/// individually searchable (SPEC §2, §3.2).
///
/// Static-site generation does not support path parameters
/// (`jaspr_router`'s `RouteRegistryImpl.registerRoutes` asserts
/// `route.pathParams.isEmpty`), so every plugin gets its own literal [Route]
/// built from the snapshot, rather than a single `/p/:name` route.
class App extends AsyncStatelessComponent {
  const App({super.key});

  @override
  Future<Component> build(BuildContext context) async {
    final snapshot = await loadLatestSnapshot();

    if (kGenerateMode) {
      for (final plugin in snapshot.plugins) {
        await ServerApp.requestRouteGeneration('/p/${plugin.name}');
      }
    }

    return div(classes: 'main', [
      const Header(),
      Router(
        routes: [
          Route(
            path: '/',
            title: 'Flutter Ready',
            builder: (context, state) => IndexPage(snapshot: snapshot),
          ),
          for (final plugin in snapshot.plugins)
            Route(
              path: '/p/${plugin.name}',
              title: '${plugin.name} — Flutter Ready',
              builder: (context, state) => PluginPage(plugin: plugin),
            ),
        ],
      ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.main').styles(display: .flex, minHeight: 100.vh, flexDirection: .column),
  ];
}
