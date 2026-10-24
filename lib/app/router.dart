import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/capture/presentation/pages/uncategorized_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/recap/presentation/pages/recap_page.dart';
import '../features/savings_goals/presentation/pages/savings_goals_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import 'app_shell.dart';

GoRouter createAppRouter() {
  return GoRouter(
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return AppShell(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/',
                name: 'home',
                builder: (BuildContext context, GoRouterState state) =>
                    const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/recap',
                name: 'recap',
                builder: (BuildContext context, GoRouterState state) =>
                    const RecapPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/goals',
                name: 'goals',
                builder: (BuildContext context, GoRouterState state) =>
                    const SavingsGoalsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (BuildContext context, GoRouterState state) =>
            const SettingsPage(),
      ),
      GoRoute(
        path: '/uncategorized',
        name: 'uncategorized',
        builder: (BuildContext context, GoRouterState state) =>
            const UncategorizedPage(),
      ),
    ],
  );
}
