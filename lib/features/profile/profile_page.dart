import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/pocketbase/pb.dart';
import '../../data/models/user_model.dart';
import '../../data/models/partner_model.dart';
import '../../data/repositories/partner_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final PartnerRepository _partnerRepo = PartnerRepository();
  UserModel? _user;
  PartnerModel? _partnerStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final record = pb.authStore.record;
    if (record != null) {
      _user = UserModel.fromRecord(record);
      
      // Check if this user is also registered as a partner via NIK
      if (_user!.nik.isNotEmpty) {
        _partnerStatus = await _partnerRepo.checkPartnerExists(_user!.nik);
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _logout(BuildContext context) {
    pb.authStore.clear();
    // GoRouter will automatically redirect via AuthNotifier
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_user == null) {
      return const Center(child: Text('Gagal memuat profil'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header Profile
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: _user!.avatar.isNotEmpty ? NetworkImage(_user!.avatar) : null,
                  child: _user!.avatar.isEmpty 
                      ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  _user!.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  _user!.phone,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Mitra Status Section
          _buildMitraStatusCard(context),
          
          const SizedBox(height: 24),

          // Menu List
          _buildMenuTile(
            icon: Icons.person_outline,
            title: 'Edit Profil',
            onTap: () {
              context.push('/profile/edit');
            },
          ),
          _buildMenuTile(
            icon: Icons.location_on_outlined,
            title: 'Alamat Tersimpan',
            onTap: () {
              context.push('/profile/addresses');
            },
          ),
          _buildMenuTile(
            icon: Icons.help_outline,
            title: 'Bantuan & Dukungan',
            onTap: () {
              context.push('/profile/help');
            },
          ),
          
          const SizedBox(height: 32),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: const Text(
                'Keluar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMitraStatusCard(BuildContext context) {
    // 1. Not a partner at all
    if (_partnerStatus == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryMid],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingin penghasilan tambahan?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gabung menjadi Mitra TanganKanan dan mulai terima pesanan di sekitarmu.',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.push('/profile/register-mitra');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Daftar sebagai Mitra'),
            ),
          ],
        ),
      );
    }

    // 2. Partner exists but not verified
    if (!_partnerStatus!.isVerified) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning),
        ),
        child: Row(
          children: [
            const Icon(Icons.pending_actions, color: AppColors.warning, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Pendaftaran Sedang Diproses',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                  Text(
                    'Tim kami sedang memverifikasi data Anda.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 3. Partner is verified
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: AppColors.success, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Anda adalah Mitra Aktif',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Logic to switch to partner mode - for MVP logout and login as partner is required
                    // because PocketBase holds one auth state per collection easily.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Silakan logout dan login menggunakan email Anda untuk masuk ke Dashboard Mitra')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text('Cara Masuk Dashboard'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.primaryMid),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
