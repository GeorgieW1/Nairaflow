import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nairaflow/providers/auth_provider.dart';
import 'package:nairaflow/screens/auth/login_screen.dart';
import 'package:nairaflow/screens/auth/register_screen.dart';
import 'package:nairaflow/screens/home/dashboard_screen.dart';
import 'package:nairaflow/screens/home/main_wrapper.dart';
import 'package:nairaflow/screens/services/airtime_screen.dart';
import 'package:nairaflow/screens/services/data_screen.dart';
import 'package:nairaflow/screens/services/electricity_screen.dart';
import 'package:nairaflow/screens/wallet/fund_wallet_screen.dart';
import 'package:nairaflow/screens/transactions/transaction_history_screen.dart';
import 'package:nairaflow/screens/profile/profile_screen.dart';
import 'package:nairaflow/screens/onboarding/splash_screen.dart';

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
        if (location == '/splash') {
          return isAuthenticated ? '/dashboard' : '/login';
        }
        
        // If not authenticated and trying to access protected routes
        if (!isAuthenticated && !_isPublicRoute(location)) {
          return '/login';
        }
        
        // If authenticated and trying to access auth routes
        if (isAuthenticated && _isAuthRoute(location)) {
          return '/dashboard';
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
      
      // Main app with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainWrapper(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionHistoryScreen(),
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