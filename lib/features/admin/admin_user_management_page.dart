import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/pocketbase/pb.dart';
import '../../data/models/user_model.dart';
import '../../data/models/partner_model.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<UserModel> _users = [];
  List<PartnerModel> _partners = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userRecords = await pb.collection('users').getFullList(sort: '-created');
      final partnerRecords = await pb.collection('partners').getFullList(sort: '-created');
      
      if (mounted) {
        setState(() {
          _users = userRecords.map((r) => UserModel.fromRecord(r)).toList();
          _partners = partnerRecords.map((r) => PartnerModel.fromRecord(r)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Gagal memuat pengguna: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data. Periksa koneksi internet.'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(String id, bool currentStatus) async {
    try {
      await pb.collection('users').update(id, body: {'is_active': !currentStatus});
      _loadData();
    } catch (e) {
      debugPrint('Gagal update status user: $e');
    }
  }

  Future<void> _togglePartnerStatus(String id, bool currentStatus) async {
    try {
      await pb.collection('partners').update(id, body: {'is_active': !currentStatus});
      _loadData();
    } catch (e) {
      debugPrint('Gagal update status partner: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: const Text('Manajemen Akun'),
          backgroundColor: AppColors.surface,
          elevation: 0.5,
          automaticallyImplyLeading: false,
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Pengguna'),
              Tab(text: 'Mitra'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUserList(),
                    _buildPartnerList(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildUserList() {
    if (_users.isEmpty) return const Center(child: Text('Tidak ada data pengguna.'));
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final isActive = user.isActive;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isActive ? AppColors.primaryLight : Colors.grey.shade300,
                child: Icon(Icons.person, color: isActive ? AppColors.primary : Colors.grey),
              ),
              title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(user.email.isNotEmpty ? user.email : user.phone),
              trailing: Switch(
                value: isActive,
                activeColor: AppColors.success,
                onChanged: (val) => _toggleUserStatus(user.id, isActive),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPartnerList() {
    if (_partners.isEmpty) return const Center(child: Text('Tidak ada data mitra.'));
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _partners.length,
        itemBuilder: (context, index) {
          final partner = _partners[index];
          final isActive = partner.isActive;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isActive ? AppColors.success.withValues(alpha: 0.2) : Colors.grey.shade300,
                child: Icon(Icons.work, color: isActive ? AppColors.success : Colors.grey),
              ),
              title: Text(partner.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Status: ${partner.isVerified ? "Terverifikasi" : "Pending"}'),
              trailing: Switch(
                value: isActive,
                activeColor: AppColors.success,
                onChanged: (val) => _togglePartnerStatus(partner.id, isActive),
              ),
            ),
          );
        },
      ),
    );
  }
}
