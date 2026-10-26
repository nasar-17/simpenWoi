import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/assistant/presentation/pages/assistant_input_page.dart';
import '../features/capture/presentation/pages/uncategorized_page.dart';
import '../features/categories/presentation/pages/categories_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/recap/presentation/pages/recap_page.dart';
import '../features/savings_goals/presentation/pages/savings_goals_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/wallets/presentation/pages/wallets_page.dart';
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
                path: '/input',
                name: 'input',
                builder: (BuildContext context, GoRouterState state) =>
                    const AssistantInputPage(),
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
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (BuildContext context, GoRouterState state) =>
                    const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/uncategorized',
        name: 'uncategorized',
        builder: (BuildContext context, GoRouterState state) =>
            const UncategorizedPage(),
      ),
      GoRoute(
        path: '/settings/categories',
        name: 'categories',
        builder: (BuildContext context, GoRouterState state) =>
            const CategoriesPage(),
      ),
      GoRoute(
        path: '/settings/wallets',
        name: 'wallets',
        builder: (BuildContext context, GoRouterState state) =>
            const WalletsPage(),
      ),
      GoRoute(
        path: '/settings/golden-set-debug',
        name: 'golden-set-debug',
        builder: (BuildContext context, GoRouterState state) =>
            const GoldenSetDebugPage(),
      ),
    ],
  );
}
