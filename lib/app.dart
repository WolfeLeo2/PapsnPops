import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/auth_provider.dart';
import 'shared/widgets/app_scaffold.dart';

import 'features/dashboard/dashboard_screen.dart';
import 'features/pos/pos_screen.dart';
import 'features/tabs/tabs_screen.dart';
import 'features/sales_history/sales_history_screen.dart';
import 'features/stock/products_screen.dart';
import 'features/stock/receive_stock_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/stock/product_detail_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/verify_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/reset_password_screen.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

final goRouterProvider = Provider<GoRouter>((ref) {
  final authUser = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authUser != null;
      final path = state.uri.path;
      final isAuthRoute =
          path == '/login' ||
          path == '/signup' ||
          path == '/verify' ||
          path == '/forgot-password' ||
          path == '/reset-password';

      if (!isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }

      final role = authUser.userMetadata?['role'];
      if (role == null) {
        return path == '/onboarding' ? null : '/onboarding';
      }

      if (isAuthRoute || path == '/onboarding' || path == '/') {
        return role == 'owner' ? '/dashboard' : '/pos';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) =>
            VerifyScreen(email: state.extra as String?),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) =>
            ResetPasswordScreen(email: state.extra as String?),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/pos',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PosScreen()),
          ),
          GoRoute(
            path: '/tabs',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TabsScreen()),
          ),
          GoRoute(
            path: '/sales',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SalesHistoryScreen()),
          ),
          GoRoute(
            path: '/products',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProductsScreen()),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return ProductDetailScreen(productId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/stock',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReceiveStockScreen()),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: ReportsScreen()),
            redirect: (context, state) {
              final user = ref.read(authProvider);
              final role = user?.userMetadata?['role'];
              if (role != 'owner') return '/pos';
              return null;
            },
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: SettingsScreen()),
            redirect: (context, state) {
              final user = ref.read(authProvider);
              final role = user?.userMetadata?['role'];
              if (role != 'owner') return '/pos';
              return null;
            },
          ),
        ],
      ),
    ],
  );
});

class PapsnPopsApp extends ConsumerWidget {
  const PapsnPopsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'PAPs n POPs',
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
