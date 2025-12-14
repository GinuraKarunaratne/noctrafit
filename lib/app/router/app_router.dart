import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/bottom_nav_scaffold.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/plans/presentation/plans_screen.dart';
import '../../features/plans/presentation/set_details_screen.dart';
import '../../features/plans/presentation/create_set_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/session/presentation/active_session_progress_screen.dart';
import '../providers/auth_provider.dart';

/// Global router provider for navigation
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isOnAuthScreen = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (!isAuthenticated && !isOnAuthScreen) {
        return '/login';
      }

      if (isAuthenticated && isOnAuthScreen) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Auth routes (outside shell)
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // Session route (outside shell, full screen)
      GoRoute(
        path: '/session/:sessionUuid',
        name: 'active-session',
        builder: (context, state) {
          final sessionUuid = state.pathParameters['sessionUuid']!;
          return ActiveSessionProgressScreen(sessionUuid: sessionUuid);
        },
      ),
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
                routes: [
                  GoRoute(
                    path: 'details/:setUuid',
                    name: 'set-details',
                    builder: (context, state) {
                      final setUuid = state.pathParameters['setUuid']!;
                      return SetDetailsScreen(workoutSetUuid: setUuid);
                    },
                  ),
                  GoRoute(
                    path: 'create',
                    name: 'create-set',
                    builder: (context, state) => const CreateSetScreen(),
                  ),
                ],
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
                routes: [
                  GoRoute(
                    path: 'settings',
                    name: 'settings',
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
