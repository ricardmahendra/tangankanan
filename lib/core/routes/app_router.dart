import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketbase/pocketbase.dart';
import '../pocketbase/pb.dart';
import '../../features/main/main_page.dart';
import '../../features/auth/login/login_page.dart';
import '../../features/auth/register/register_page.dart';
import '../../features/mitra/mitra_page.dart';
import '../../features/mitra/mitra_job_page.dart';
import '../../features/mitra/tabs/mitra_finance_tab.dart';
import '../../features/order/subcategory_page.dart';
import '../../features/order/order_detail_page.dart';
import '../../features/order/partner_select_page.dart';
import '../../features/order/order_confirm_page.dart';
import '../../features/order/order_tracking_page.dart';
import '../../features/order/order_review_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/profile/mitra_registration_page.dart';
import '../../features/profile/edit_profile_page.dart';
import '../../features/profile/saved_address_page.dart';
import '../../features/profile/help_support_page.dart';
import '../../features/admin/admin_page.dart';
import '../../features/admin/admin_mitra_verify_page.dart';
import '../../features/admin/admin_withdraw_page.dart';
import '../../features/chat/chat_page.dart';
import '../../features/history/history_page.dart';
import '../../features/home/notification_page.dart';
import '../../data/models/order_flow_data.dart';
import '../../data/models/category_model.dart';

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
        final record = pb.authStore.record;

        if (record is RecordModel) {
          if (record.collectionName == '_superusers') {
            role = 'admin';
          } else {
            role = record.getStringValue('role');
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
      path: '/notifications',
      builder: (context, state) => const NotificationPage(),
    ),
    GoRoute(
      path: '/order/confirm', // Placed before /order/:categoryId to avoid conflict
      builder: (context, state) {
        final flowData = state.extra as OrderFlowData;
        return OrderConfirmPage(flowData: flowData);
      },
    ),
    GoRoute(
      path: '/order/:categoryId',
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId']!;
        final category = state.extra as CategoryModel?;
        return SubcategoryPage(categoryId: categoryId, category: category);
      },
    ),
    GoRoute(
      path: '/order/:categoryId/detail',
      builder: (context, state) {
        final flowData = state.extra as OrderFlowData;
        return OrderDetailPage(flowData: flowData);
      },
    ),
    GoRoute(
      path: '/order/:categoryId/partners',
      builder: (context, state) {
        final flowData = state.extra as OrderFlowData;
        return PartnerSelectPage(flowData: flowData);
      },
    ),
    GoRoute(
      path: '/order/tracking/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        return OrderTrackingPage(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/order/review/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        return OrderReviewPage(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/profile/register-mitra',
      builder: (context, state) => const MitraRegistrationPage(),
    ),
    GoRoute(
      path: '/chat/:orderId',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        return ChatPage(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: '/profile/addresses',
      builder: (context, state) => const SavedAddressPage(),
    ),
    GoRoute(
      path: '/profile/help',
      builder: (context, state) => const HelpSupportPage(),
    ),
    GoRoute(
      path: '/mitra',
      builder: (context, state) => const MitraPage(),
    ),
    GoRoute(
      path: '/mitra/job/:orderId',
      builder: (context, state) => MitraJobPage(orderId: state.pathParameters['orderId'] ?? ''),
    ),
    GoRoute(
      path: '/mitra/finance',
      builder: (context, state) => const Scaffold(body: MitraFinanceTab()),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminPage(),
    ),
    GoRoute(
      path: '/admin/mitra',
      builder: (context, state) => const AdminMitraVerifyPage(),
    ),
    GoRoute(
      path: '/admin/withdraw',
      builder: (context, state) => const AdminWithdrawPage(),
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
