import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/pocketbase/pb.dart';
import 'admin_repository.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;
  final _adminRepo = AdminRepository();
  
  Map<String, dynamic> _stats = {
    'total_users': 0,
    'total_mitras': 0,
    'pending_mitras': 0,
    'pending_withdrawals': 0,
  };
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _adminRepo.getStatistics();
      setState(() => _stats = stats);
    } catch (e) {
      print('Error loading stats: $e');
    } finally {
      setState(() => _isLoadingStats = false);
    }
  }

  void _logout() {
    pb.authStore.clear();
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);

          switch (index) {
            case 0:
              // Stay on dashboard
              break;
            case 1:
              context.push('/admin/mitra');
              break;
            case 2:
              context.push('/admin/withdraw');
              break;
            case 3:
              _logout();
              break;
          }
        },
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              'Admin Panel',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          NavigationDrawerDestination(
            label: const Text('Dashboard'),
            icon: const Icon(Icons.dashboard),
            selectedIcon: const Icon(Icons.dashboard, color: Colors.blue),
          ),
          NavigationDrawerDestination(
            label: const Text('Verifikasi Mitra'),
            icon: const Icon(Icons.verified_user),
            selectedIcon:
                const Icon(Icons.verified_user, color: Colors.blue),
          ),
          NavigationDrawerDestination(
            label: const Text('Penarikan Dana'),
            icon: const Icon(Icons.account_balance_wallet),
            selectedIcon: const Icon(Icons.account_balance_wallet,
                color: Colors.blue),
          ),
          const Divider(),
          NavigationDrawerDestination(
            label: const Text('Logout'),
            icon: const Icon(Icons.exit_to_app),
            selectedIcon:
                const Icon(Icons.exit_to_app, color: Colors.red),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Text(
              'Selamat datang, Admin!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),

            // Dashboard Stats
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _StatCard(
                  title: 'Total Users',
                  count: _stats['total_users'].toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                  isLoading: _isLoadingStats,
                ),
                _StatCard(
                  title: 'Total Mitra',
                  count: _stats['total_mitras'].toString(),
                  icon: Icons.person_add,
                  color: Colors.green,
                  isLoading: _isLoadingStats,
                ),
                _StatCard(
                  title: 'Pending Verifikasi',
                  count: _stats['pending_mitras'].toString(),
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                  isLoading: _isLoadingStats,
                ),
                _StatCard(
                  title: 'Pending Penarikan',
                  count: _stats['pending_withdrawals'].toString(),
                  icon: Icons.money_off,
                  color: Colors.red,
                  isLoading: _isLoadingStats,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Aksi Cepat',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/admin/mitra'),
                    icon: const Icon(Icons.verified_user),
                    label: const Text('Verifikasi Mitra'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/admin/withdraw'),
                    icon: const Icon(Icons.account_balance_wallet),
                    label: const Text('Kelola Penarikan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadStatistics,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final bool isLoading;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 32, color: color),
              Column(
                children: [
                  isLoading
                      ? SizedBox(
                          height: 28,
                          width: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                          ),
                        )
                      : Text(
                          count,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: color),
                        ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
