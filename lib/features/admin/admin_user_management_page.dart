import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/pocketbase/pb.dart';
import '../../data/models/user_model.dart';
import '../../data/models/partner_model.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<UserModel> _users = [];
  List<PartnerModel> _partners = [];
  String _userSearch = '';
  String _partnerSearch = '';

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
      debugPrint('Gagal memuat data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat data. Periksa koneksi internet.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // ─── Toggle Status ────────────────────────────────────────────────────────

  Future<void> _toggleUserStatus(UserModel user) async {
    try {
      await pb.collection('users').update(user.id, body: {'is_active': !user.isActive});
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !user.isActive ? '${user.name} diaktifkan' : '${user.name} dinonaktifkan',
            ),
            backgroundColor: !user.isActive ? AppColors.success : AppColors.textSecondary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Gagal update status user: $e');
    }
  }

  Future<void> _togglePartnerStatus(PartnerModel partner) async {
    try {
      await pb.collection('partners').update(partner.id, body: {'is_active': !partner.isActive});
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !partner.isActive ? '${partner.name} diaktifkan' : '${partner.name} dinonaktifkan',
            ),
            backgroundColor: !partner.isActive ? AppColors.success : AppColors.textSecondary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Gagal update status mitra: $e');
    }
  }

  // ─── Delete ───────────────────────────────────────────────────────────────

  Future<void> _deleteUser(UserModel user) async {
    final confirm = await _showDeleteDialog(user.name);
    if (confirm != true) return;
    try {
      await pb.collection('users').delete(user.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Akun ${user.name} berhasil dihapus'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _deletePartner(PartnerModel partner) async {
    final confirm = await _showDeleteDialog(partner.name);
    if (confirm != true) return;
    try {
      await pb.collection('partners').delete(partner.id);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Akun ${partner.name} berhasil dihapus'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<bool?> _showDeleteDialog(String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Akun', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun "$name"?\nTindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─── Detail Bottom Sheet ──────────────────────────────────────────────────

  void _showUserDetail(UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _buildBadge(
                          user.isActive ? 'Aktif' : 'Nonaktif',
                          user.isActive ? AppColors.success : AppColors.danger,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              _detailRow(Icons.email_outlined, 'Email', user.email.isNotEmpty ? user.email : '-'),
              _detailRow(Icons.phone_outlined, 'Telepon', user.phone.isNotEmpty ? user.phone : '-'),
              _detailRow(Icons.badge_outlined, 'NIK', user.nik.isNotEmpty ? user.nik : '-'),
              _detailRow(Icons.location_on_outlined, 'Alamat', user.address.isNotEmpty ? user.address : '-'),
              _detailRow(Icons.person_outline, 'Role', user.role),
              if (user.created != null)
                _detailRow(Icons.calendar_today_outlined, 'Daftar',
                  DateFormat('dd MMMM yyyy', 'id').format(user.created!)),
              const SizedBox(height: 20),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleUserStatus(user);
                      },
                      icon: Icon(user.isActive ? Icons.block : Icons.check_circle_outline, size: 18),
                      label: Text(user.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: user.isActive ? AppColors.warning : AppColors.success,
                        side: BorderSide(color: user.isActive ? AppColors.warning : AppColors.success),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteUser(user);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus Akun'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPartnerDetail(PartnerModel partner) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.success.withValues(alpha: 0.15),
                    child: Text(
                      partner.name.isNotEmpty ? partner.name[0].toUpperCase() : 'M',
                      style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(partner.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          children: [
                            _buildBadge(
                              partner.isActive ? 'Aktif' : 'Nonaktif',
                              partner.isActive ? AppColors.success : AppColors.danger,
                            ),
                            _buildBadge(
                              partner.isVerified ? 'Terverifikasi' : 'Pending',
                              partner.isVerified ? AppColors.primary : AppColors.warning,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Stats row
              Row(
                children: [
                  Expanded(child: _statMini('Rating', '${partner.rating.toStringAsFixed(1)} ⭐')),
                  const SizedBox(width: 8),
                  Expanded(child: _statMini('Total Job', '${partner.totalJobs}')),
                  const SizedBox(width: 8),
                  Expanded(child: _statMini('Saldo', currencyFormat.format(partner.balance))),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _detailRow(Icons.email_outlined, 'Email', partner.email.isNotEmpty ? partner.email : '-'),
              _detailRow(Icons.phone_outlined, 'Telepon', partner.phone.isNotEmpty ? partner.phone : '-'),
              _detailRow(Icons.badge_outlined, 'NIK', partner.nik.isNotEmpty ? partner.nik : '-'),
              _detailRow(Icons.info_outline, 'Bio', partner.bio.isNotEmpty ? partner.cleanBio : '-'),
              _detailRow(Icons.account_balance_outlined, 'Bank', partner.bankName.isNotEmpty ? partner.bankName : '-'),
              _detailRow(Icons.credit_card_outlined, 'No. Rekening', partner.bankAccount.isNotEmpty ? partner.bankAccount : '-'),
              if (partner.created != null)
                _detailRow(Icons.calendar_today_outlined, 'Daftar',
                  DateFormat('dd MMMM yyyy', 'id').format(partner.created!)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _togglePartnerStatus(partner);
                      },
                      icon: Icon(partner.isActive ? Icons.block : Icons.check_circle_outline, size: 18),
                      label: Text(partner.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: partner.isActive ? AppColors.warning : AppColors.success,
                        side: BorderSide(color: partner.isActive ? AppColors.warning : AppColors.success),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deletePartner(partner);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus Akun'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(label,
              style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statMini(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value,
            style: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          Text(label,
            style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 10, color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
        style: TextStyle(
          fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: color,
        ),
      ),
    );
  }

  // ─── Stat Summary ─────────────────────────────────────────────────────────

  Widget _buildStatSummary({
    required int total,
    required int active,
    required String label,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem('Total $label', total.toString(), color),
          Container(width: 1, height: 32, color: color.withValues(alpha: 0.3)),
          _summaryItem('Aktif', active.toString(), AppColors.success),
          Container(width: 1, height: 32, color: color.withValues(alpha: 0.3)),
          _summaryItem('Nonaktif', (total - active).toString(), AppColors.danger),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
          style: TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18, color: color,
          ),
        ),
        Text(label,
          style: const TextStyle(
            fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ─── Search Bar ───────────────────────────────────────────────────────────

  Widget _buildSearchBar(String hint, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Manajemen Akun',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Pengguna (${_users.length})'),
            Tab(text: 'Mitra (${_partners.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUserTab(),
                _buildPartnerTab(),
              ],
            ),
    );
  }

  // ─── User Tab ─────────────────────────────────────────────────────────────

  Widget _buildUserTab() {
    final filtered = _users.where((u) =>
      u.name.toLowerCase().contains(_userSearch.toLowerCase()) ||
      u.email.toLowerCase().contains(_userSearch.toLowerCase()) ||
      u.phone.contains(_userSearch)
    ).toList();

    return Column(
      children: [
        _buildStatSummary(
          total: _users.length,
          active: _users.where((u) => u.isActive).length,
          label: 'Pengguna',
          color: AppColors.primary,
        ),
        _buildSearchBar('Cari nama, email, atau telepon...', (v) => setState(() => _userSearch = v)),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _userSearch.isEmpty ? 'Belum ada pengguna terdaftar' : 'Tidak ditemukan',
                        style: const TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildUserCard(filtered[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showUserDetail(user),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: user.isActive ? AppColors.primaryLight : Colors.grey.shade200,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18,
                      color: user.isActive ? AppColors.primary : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(user.name,
                              style: const TextStyle(
                                fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildBadge(
                            user.isActive ? 'Aktif' : 'Nonaktif',
                            user.isActive ? AppColors.success : AppColors.danger,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email.isNotEmpty ? user.email : user.phone,
                        style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.created != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Bergabung ${DateFormat('dd MMM yyyy').format(user.created!)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Toggle
                GestureDetector(
                  onTap: () => _toggleUserStatus(user),
                  child: Switch.adaptive(
                    value: user.isActive,
                    activeThumbColor: AppColors.success,
                    onChanged: (_) => _toggleUserStatus(user),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Partner Tab ──────────────────────────────────────────────────────────

  Widget _buildPartnerTab() {
    final filtered = _partners.where((p) =>
      p.name.toLowerCase().contains(_partnerSearch.toLowerCase()) ||
      p.email.toLowerCase().contains(_partnerSearch.toLowerCase()) ||
      p.phone.contains(_partnerSearch)
    ).toList();

    return Column(
      children: [
        _buildStatSummary(
          total: _partners.length,
          active: _partners.where((p) => p.isActive).length,
          label: 'Mitra',
          color: AppColors.success,
        ),
        _buildSearchBar('Cari nama, email, atau telepon mitra...', (v) => setState(() => _partnerSearch = v)),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_outline, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _partnerSearch.isEmpty ? 'Belum ada mitra terdaftar' : 'Tidak ditemukan',
                        style: const TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildPartnerCard(filtered[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPartnerCard(PartnerModel partner) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showPartnerDetail(partner),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: partner.isActive
                      ? AppColors.success.withValues(alpha: 0.15)
                      : Colors.grey.shade200,
                  child: Text(
                    partner.name.isNotEmpty ? partner.name[0].toUpperCase() : 'M',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18,
                      color: partner.isActive ? AppColors.success : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(partner.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        partner.email.isNotEmpty ? partner.email : partner.phone,
                        style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _buildBadge(
                            partner.isActive ? 'Aktif' : 'Nonaktif',
                            partner.isActive ? AppColors.success : AppColors.danger,
                          ),
                          _buildBadge(
                            partner.isVerified ? 'Terverifikasi' : 'Pending',
                            partner.isVerified ? AppColors.primary : AppColors.warning,
                          ),
                          _buildBadge(
                            '⭐ ${partner.rating.toStringAsFixed(1)}',
                            AppColors.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Saldo: ${currencyFormat.format(partner.balance)}  •  ${partner.totalJobs} job',
                        style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Toggle
                Switch.adaptive(
                  value: partner.isActive,
                  activeThumbColor: AppColors.success,
                  onChanged: (_) => _togglePartnerStatus(partner),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
