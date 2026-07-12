import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/pocketbase/pb.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _logout(BuildContext context) {
    pb.authStore.clear();
    // Setelah clear, AuthNotifier di app_router akan mendeteksi perubahan
    // dan me-redirect otomatis ke halaman login (path: '/').
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Halaman Profil'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Keluar (Logout)'),
            ),
          ],
        ),
      ),
    );
  }
}
