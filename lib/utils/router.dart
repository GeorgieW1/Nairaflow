import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/home/main_wrapper.dart';
import '../screens/services/airtime_screen.dart';
import '../screens/services/data_screen.dart';
import '../screens/services/electricity_screen.dart';
import '../screens/wallet/fund_wallet_screen.dart';
import '../screens/transactions/transaction_history_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/onboarding/splash_screen.dart';
import '../screens/services/tv_screen.dart';

import '../screens/services/epin_screen.dart';
import '../screens/wallet/card_screen.dart';
import '../screens/reward/reward_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;

      final location = state.matchedLocation;

      // Show splash while checking auth status
      if (isLoading && location == '/splash') {
        return null;
      }

      // If loading is done
      if (!isLoading) {
        // If on splash and auth is determined, redirect appropriately
        // If on splash and auth is determined, redirect appropriately
        if (location == '/splash') {
          return isAuthenticated ? '/dashboard' : '/login';
        }

        // 1. Not Authenticated
        if (!isAuthenticated) {
          if (_isPublicRoute(location)) {
            return null; // Stay where you are
          }
          return '/login'; // Redirect to login
        }

        // 2. Authenticated
        if (isAuthenticated) {
          final user = authState.user;
          // Check if email is verified
          if (user != null && !user.isEmailVerified) {
            // Force redirection to verify-email if not already there
            if (location != '/verify-email') {
              return '/verify-email';
            }
            return null; // Allow staying on verify-email
          }

          // If Verified:
          
          // If trying to access verify-email while already verified, go to dashboard
          if (location == '/verify-email') {
            return '/dashboard';
          }

          // If on auth routes (login/register) or splash, go to dashboard
          if (_isAuthRoute(location) || location == '/splash') {
            return '/dashboard';
          }
        }
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Verify Email is now a protected route (requires auth)
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const EmailVerificationScreen(),
      ),

      // Main app with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainWrapper(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/cards',
            builder: (context, state) => const CardScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionHistoryScreen(),
          ),
          GoRoute(
            path: '/rewards',
            builder: (context, state) => const RewardScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Service routes
      GoRoute(
        path: '/airtime',
        builder: (context, state) => const AirtimeScreen(),
      ),
      GoRoute(
        path: '/data',
        builder: (context, state) => const DataScreen(),
      ),
      GoRoute(
        path: '/electricity',
        builder: (context, state) => const ElectricityScreen(),
      ),
      GoRoute(
        path: '/tv-subscription',
        builder: (context, state) => const TVScreen(),
      ),
      GoRoute(
        path: '/epin',
        builder: (context, state) => const EpinScreen(),
      ),

      // Wallet routes
      GoRoute(
        path: '/fund-wallet',
        builder: (context, state) => const FundWalletScreen(),
      ),
    ],
  );
});

bool _isPublicRoute(String route) {
  return ['/login', '/register', '/splash'].contains(route);
}

bool _isAuthRoute(String route) {
  return ['/login', '/register'].contains(route);
}
