import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/pages/password_recovery_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/feed/presentation/pages/feed_page.dart';
import '../../features/hosts/presentation/pages/host_profile_page.dart';
import '../../features/hosts/presentation/pages/host_search_page.dart';
import '../../features/experiences/presentation/pages/experience_detail_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import 'main_shell.dart';
import 'route_guards.dart';

GoRouter createAppRouter({
  required bool authConfigured,
  required bool authRequired,
  Listenable? authRefresh,
}) {
  return GoRouter(
    initialLocation: authRequired ? '/auth' : '/feed',
    refreshListenable: authRefresh,
    redirect: (context, state) {
      if (!authRequired) return null;

      final onAuthPage = state.matchedLocation == '/auth';
      final onRecoveryPage = state.matchedLocation == '/auth/update-password';
      if (!authConfigured) return onAuthPage ? null : '/auth';

      final signedIn = Supabase.instance.client.auth.currentSession != null;
      final isPasswordRecovery =
          authRefresh is AuthRouterRefresh && authRefresh.isPasswordRecovery;

      if (isPasswordRecovery && !onRecoveryPage) {
        return '/auth/update-password';
      }
      if (onRecoveryPage) {
        return isPasswordRecovery && signedIn ? null : '/auth';
      }
      if (!signedIn && !onAuthPage) return '/auth';
      if (signedIn && onAuthPage) return '/feed';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => AuthPage(authConfigured: authConfigured),
      ),
      GoRoute(
        path: '/auth/update-password',
        builder: (context, state) => authConfigured
            ? const PasswordRecoveryPage()
            : AuthPage(authConfigured: false),
      ),
      GoRoute(
        path: '/host/:hostId',
        builder: (context, state) =>
            HostProfilePage(hostId: state.pathParameters['hostId']!),
      ),
      GoRoute(
        path: '/experience/:experienceId',
        builder: (context, state) => ExperienceDetailPage(
          experienceId: state.pathParameters['experienceId']!,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // 0 - Mapa
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) {
                  return const MapPage();
                },
              ),
            ],
          ),

          // 1 - Feed
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                builder: (context, state) {
                  return const FeedPage();
                },
              ),
            ],
          ),

          // 2 - Buscar anfitriones
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const HostSearchPage(),
              ),
            ],
          ),

          // 3 - Calendario
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) {
                  return const CalendarPage();
                },
              ),
            ],
          ),

          // 4 - Perfil
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) {
                  return const ProfilePage();
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
