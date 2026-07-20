import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import screens (We will create these shortly)
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/authentication/auth_screen.dart';
import '../../features/home/presentation/dashboard_screen.dart';
import '../../features/companion/presentation/companion_screen.dart';
import '../../features/study/presentation/study_screen.dart';
import '../../features/planner/presentation/planner_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import 'scaffold_with_nav_bar.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
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
