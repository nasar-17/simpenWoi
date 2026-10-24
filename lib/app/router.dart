import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

GoRouter createAppRouter(Widget home) {
  return GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'home',
        builder: (BuildContext context, GoRouterState state) => home,
      ),
    ],
  );
}
