import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/presentation/permission_setup_screen.dart';
import '../../features/authentication/auth_screen.dart';
import '../../features/authentication/providers/auth_provider.dart';
import '../../features/home/presentation/dashboard_screen.dart';
import '../../features/companion/presentation/companion_screen.dart';
import '../../features/study/presentation/study_screen.dart';
import '../../features/planner/presentation/planner_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/memory/presentation/memory_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/profile/presentation/privacy_screen.dart';
import '../../features/profile/presentation/activity_log_screen.dart';
import '../../features/profile/presentation/diagnostics_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import 'scaffold_with_nav_bar.dart';

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }
}

final _authListenableProvider = Provider<_AuthListenable>((ref) => _AuthListenable(ref));

final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = ref.watch(_authListenableProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState == AuthState.authenticated;
      final location = state.matchedLocation;
      final isPublicRoute = location == '/splash' || location == '/onboarding' || location == '/auth';

      // If initial state, wait for splash check
      if (authState == AuthState.initial) {
        return null;
      }

      if (!isAuth && !isPublicRoute) {
        return '/auth';
      }

      if (isAuth && (location == '/auth' || location == '/onboarding')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const PermissionSetupScreen(),
      ),
      GoRoute(
        path: '/memory',
        builder: (context, state) => const MemoryScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const CompanionScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/activity-log',
        builder: (context, state) => const ActivityLogScreen(),
      ),
      GoRoute(
        path: '/diagnostics',
        builder: (context, state) => const DiagnosticsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (context, state) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/companion', builder: (context, state) => const CompanionScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/study', builder: (context, state) => const StudyScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/planner', builder: (context, state) => const PlannerScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
    ],
  );
});
