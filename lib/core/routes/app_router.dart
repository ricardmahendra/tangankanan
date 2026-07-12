import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import '../pocketbase/pb.dart';
import '../../features/main/main_page.dart';
import '../../features/auth/login/login_page.dart';
import '../../features/auth/register/register_page.dart';

// Auth State Notifier for Router
// This allows go_router to re-evaluate the redirect logic whenever
// the authentication state changes in PocketBase.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    if (!isPocketBaseInitialized) return;

    pb.authStore.onChange.listen((event) {
      notifyListeners();
    });
  }
}

final authNotifier = AuthNotifier();

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  refreshListenable: authNotifier,
  redirect: (BuildContext context, GoRouterState state) {
    final bool isLoggedIn = isPocketBaseInitialized && pb.authStore.isValid;
    final String currentPath = state.uri.path;
    final bool isAuthPage = currentPath == '/' || currentPath == '/register';

    // If user is not logged in and tries to access a protected page
    if (!isLoggedIn && !isAuthPage) {
      return '/';
    }

    // If user is already logged in and tries to access login/register page
    if (isLoggedIn && isAuthPage) {
      String role = 'user';

      if (isPocketBaseInitialized) {
        final model = pb.authStore.model;

        if (model is RecordModel) {
          if (model.collectionName == '_superusers') {
            role = 'admin';
          } else {
            role = model.getStringValue('role');
            if (role.isEmpty) role = 'user';
          }
        }
      }

      // Role-based redirect as specified in PRD
      if (role == 'mitra') {
        return '/mitra';
      } else if (role == 'admin') {
        return '/admin';
      } else {
        return '/main';
      }
    }

    return null; // no redirect needed
  },
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Routing Error: ${state.error}',
        style: const TextStyle(color: Colors.red),
      ),
    ),
  ),
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/main',
      builder: (context, state) => const MainPage(),
    ),
    GoRoute(
      path: '/order/confirm', // Placed before /order/:categoryId to avoid conflict
      builder: (context, state) => const PlaceholderPage('OrderConfirmPage'),
    ),
    GoRoute(
      path: '/order/:categoryId',
      builder: (context, state) => PlaceholderPage('SubcategoryPage ${state.pathParameters['categoryId']}'),
    ),
    GoRoute(
      path: '/order/:categoryId/detail',
      builder: (context, state) => const PlaceholderPage('OrderDetailPage'),
    ),
    GoRoute(
      path: '/order/:categoryId/partners',
      builder: (context, state) => const PlaceholderPage('PartnerSelectPage'),
    ),
    GoRoute(
      path: '/order/tracking/:orderId',
      builder: (context, state) => PlaceholderPage('OrderTrackingPage ${state.pathParameters['orderId']}'),
    ),
    GoRoute(
      path: '/order/review/:orderId',
      builder: (context, state) => PlaceholderPage('OrderReviewPage ${state.pathParameters['orderId']}'),
    ),
    GoRoute(
      path: '/chat/:orderId',
      builder: (context, state) => PlaceholderPage('ChatPage ${state.pathParameters['orderId']}'),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const PlaceholderPage('HistoryPage'),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const PlaceholderPage('ProfilePage'),
    ),
    GoRoute(
      path: '/mitra',
      builder: (context, state) => const PlaceholderPage('MitraPage'),
    ),
    GoRoute(
      path: '/mitra/job/:orderId',
      builder: (context, state) => PlaceholderPage('MitraJobPage ${state.pathParameters['orderId']}'),
    ),
    GoRoute(
      path: '/mitra/finance',
      builder: (context, state) => const PlaceholderPage('MitraFinancePage'),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const PlaceholderPage('AdminPage'),
    ),
    GoRoute(
      path: '/admin/mitra',
      builder: (context, state) => const PlaceholderPage('AdminMitraVerifyPage'),
    ),
    GoRoute(
      path: '/admin/withdraw',
      builder: (context, state) => const PlaceholderPage('AdminWithdrawPage'),
    ),
  ],
);

// A placeholder widget for routes that haven't been implemented yet.
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          'Halaman $title sedang dalam pengembangan',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
