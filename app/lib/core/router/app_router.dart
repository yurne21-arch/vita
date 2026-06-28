import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/mi_vida/presentation/mi_vida_screen.dart';
import '../../features/shell/placeholder_screen.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/app_shell.dart';

/// Crea el router. La sesión de Supabase decide si se ve el login o la app.
GoRouter createRouter() {
  final auth = Supabase.instance.client.auth;

  return GoRouter(
    initialLocation: '/mi-vida',
    refreshListenable: GoRouterRefreshStream(auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = auth.currentSession != null;
      final loggingIn = state.matchedLocation == '/login';
      if (!loggedIn) return loggingIn ? null : '/login';
      if (loggingIn) return '/mi-vida';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mi-vida',
                builder: (_, __) => const MiVidaScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/salud',
                builder: (context, __) => PlaceholderScreen(
                  title: AppLocalizations.of(context).tabSalud,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/proyectos',
                builder: (context, __) => PlaceholderScreen(
                  title: AppLocalizations.of(context).tabProyectos,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendario',
                builder: (context, __) => PlaceholderScreen(
                  title: AppLocalizations.of(context).tabCalendario,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mas',
                builder: (context, __) => PlaceholderScreen(
                  title: AppLocalizations.of(context).tabMas,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Convierte un Stream en un Listenable para refrescar el router
/// cuando cambia el estado de autenticación.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
