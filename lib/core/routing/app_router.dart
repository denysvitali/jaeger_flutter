import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_shell.dart';
import '../../features/services/services_screen.dart';
import '../../features/settings/server_config_screen.dart';
import '../../features/traces/trace_detail_screen.dart';
import '../../features/traces/traces_search_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>(
  (ref) => GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/traces',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/traces',
                builder: (context, state) => const TracesSearchScreen(),
                routes: [
                  GoRoute(
                    path: ':traceId',
                    builder: (context, state) => TraceDetailScreen(
                      traceId: state.pathParameters['traceId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/services',
                builder: (context, state) => const ServicesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const ServerConfigScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  ),
);
