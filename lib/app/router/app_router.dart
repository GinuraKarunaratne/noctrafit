import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/bottom_nav_scaffold.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/plans/presentation/plans_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';

/// Global router provider for navigation
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,
    routes: [
      // Stateful shell with bottom navigation for 5 main tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),

          // Branch 1: Plans (Workouts)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plans',
                name: 'plans',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlansScreen(),
                ),
                // TODO: Add child routes for set details and create set
              ),
            ],
          ),

          // Branch 2: Calendar
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                name: 'calendar',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CalendarScreen(),
                ),
              ),
            ],
          ),

          // Branch 3: Insights
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/insights',
                name: 'insights',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: InsightsScreen(),
                ),
              ),
            ],
          ),

          // Branch 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
                // TODO: Add child route for settings
              ),
            ],
          ),
        ],
      ),

      // TODO: Add standalone route for active session screen
      // GoRoute(
      //   path: '/session/:sessionUuid',
      //   name: 'active-session',
      //   builder: (context, state) {
      //     final sessionUuid = state.pathParameters['sessionUuid']!;
      //     return ActiveSessionProgressScreen(sessionUuid: sessionUuid);
      //   },
      // ),
    ],
  );
});
