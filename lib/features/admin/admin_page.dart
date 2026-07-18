import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/pocketbase/pb.dart';
import '../../data/models/partner_model.dart';
import '../../data/models/withdrawal_model.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/withdrawal_repository.dart';
import '../../data/repositories/order_repository.dart';
import 'admin_user_management_page.dart';
import 'admin_content_management_page.dart';
import 'admin_cs_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _withdrawalRepo = WithdrawalRepository();
  final _orderRepo = OrderRepository();

  int _currentIndex = 0;

  // Stats
  int _totalUsers = 0;
  int _totalPartners = 0;
  int _pendingVerifications = 0;
  int _pendingWithdrawalsCount = 0;
  int _activeOrders = 0;

  // Data
  List<PartnerModel> _pendingPartners = [];
  List<WithdrawalModel> _pendingWithdrawalsList = [];
  List<WithdrawalModel> _approvedWithdrawalsList = [];
  List<OrderModel> _recentOrders = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // Load stats
      final users = await pb.collection('users').getFullList();
      final partners = await pb.collection('partners').getFullList();
      final pendingPartners = await pb.collection('partners').getFullList(
        filter: 'is_verified = false',
      );
      final pendingWithdrawals = await pb.collection('withdrawals').getFullList(
        filter: 'status = "pending"',
      );
      final activeOrders = await pb.collection('orders').getFullList(
        filter: 'status != "completed" && status != "cancelled"',
      );

      setState(() {
        _totalUsers = users.length;
        _totalPartners = partners.length;
        _pendingVerifications = pendingPartners.length;
        _pendingWithdrawalsCount = pendingWithdrawals.length;
        _activeOrders = activeOrders.length;
        _isLoading = false;
      });

      // Load detailed data for tabs
      await _loadPendingPartners();
      await _loadPendingWithdrawals();
      await _loadRecentOrders();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPendingPartners() async {
    try {
      final partners = await pb.collection('partners').getFullList(
        filter: 'is_verified = false',
        sort: '-created',
      );
      setState(() {
        _pendingPartners = partners.map((r) => PartnerModel.fromRecord(r)).toList();
      });
    } catch (e) {
      debugPrint('Gagal load pending partners: $e');
    }
  }

  Future<void> _loadPendingWithdrawals() async {
    try {
      final pending = await _withdrawalRepo.getPendingWithdrawals();
      final approved = await _withdrawalRepo.getApprovedWithdrawals();
      setState(() {
        _pendingWithdrawalsList = pending;
        _approvedWithdrawalsList = approved;
      });
    } catch (e) {
      debugPrint('Gagal load withdrawals: $e');
    }
  }

  Future<void> _loadRecentOrders() async {
    try {
      final orders = await _orderRepo.getRecentOrders(10);
      setState(() {
        _recentOrders = orders;
      });
    } catch (e) {
      debugPrint('Gagal load recent orders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(
                index: _currentIndex,
                children: [
                  _buildDashboardTab(),
                  _buildVerificationTab(),
                  _buildWithdrawalTab(),
                  _buildOrdersTab(),
                  const AdminUserManagementPage(),
                  const AdminContentManagementPage(),
                  const AdminCSPage(),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_user_outlined),
            activeIcon: Icon(Icons.verified_user),
            label: 'Verifikasi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Withdrawal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Akun',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            activeIcon: Icon(Icons.category),
            label: 'Konten',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.headset_mic_outlined),
            activeIcon: Icon(Icons.headset_mic),
            label: 'CS',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Dashboard',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 24),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total User',
                    _totalUsers.toString(),
                    Icons.people,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Mitra',
                    _totalPartners.toString(),
                    Icons.work,
                    AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Verifikasi Pending',
                    _pendingVerifications.toString(),
                    Icons.pending,
                    AppColors.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Withdrawal Pending',
                    _pendingWithdrawalsCount.toString(),
                    Icons.money,
                    AppColors.statusConfirmed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Pesanan Aktif',
              _activeOrders.toString(),
              Icons.shopping_cart,
              AppColors.statusInProgress,
              fullWidth: true,
            ),

            const SizedBox(height: 32),

            // Quick Actions
            const Text(
              'Aksi Cepat',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickAction(
              'Verifikasi Mitra',
              Icons.verified_user,
              AppColors.warning,
              () {
                setState(() => _currentIndex = 1);
              },
            ),
            const SizedBox(height: 12),
            _buildQuickAction(
              'Approve Withdrawal',
              Icons.account_balance_wallet,
              AppColors.statusConfirmed,
              () {
                setState(() => _currentIndex = 2);
              },
            ),
            const SizedBox(height: 12),
            _buildQuickAction(
              'Kelola Pesanan',
              Icons.list_alt,
              AppColors.primary,
              () {
                setState(() => _currentIndex = 3);
              },
            ),
            const SizedBox(height: 12),
            _buildQuickAction(
              'Manajemen Akun (User/Mitra)',
              Icons.people,
              AppColors.primaryMid,
              () {
                setState(() => _currentIndex = 4);
              },
            ),
            const SizedBox(height: 12),
            _buildQuickAction(
              'Manajemen Konten (Kategori)',
              Icons.category,
              AppColors.primary,
              () {
                setState(() => _currentIndex = 5);
              },
            ),
            const SizedBox(height: 12),
            _buildQuickAction(
              'Customer Service',
              Icons.headset_mic,
              AppColors.success,
              () {
                setState(() => _currentIndex = 6);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationTab() {
    return RefreshIndicator(
      onRefresh: _loadPendingPartners,
      child: _pendingPartners.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: _buildEmptyState('Tidak ada mitra yang perlu diverifikasi'),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingPartners.length,
              itemBuilder: (context, index) {
                final partner = _pendingPartners[index];
                return _buildPartnerVerificationCard(partner);
              },
            ),
    );
  }

  Widget _buildPartnerVerificationCard(PartnerModel partner) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    partner.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        partner.phone,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildInfoRow('NIK', partner.nik),
            _buildInfoRow('Phone', partner.phone),
            _buildInfoRow('Bio', partner.bio),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectPartner(partner),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approvePartner(partner),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Setujui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approvePartner(PartnerModel partner) async {
    try {
      await pb.collection('partners').update(partner.id, body: {
        'is_verified': true,
      });
      await _loadPendingPartners();
      await _loadDashboardData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mitra berhasil disetujui'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _rejectPartner(PartnerModel partner) async {
    try {
      await pb.collection('partners').update(partner.id, body: {
        'is_active': false,
      });
      await _loadPendingPartners();
      await _loadDashboardData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mitra ditolak'), backgroundColor: AppColors.textSecondary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Widget _buildWithdrawalTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
            ],
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
          ),
          Flexible(
            child: TabBarView(
              children: [
                _buildPendingWithdrawalsList(),
                _buildApprovedWithdrawalsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingWithdrawalsList() {
    return RefreshIndicator(
      onRefresh: _loadPendingWithdrawals,
      child: _pendingWithdrawalsList.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _buildEmptyState('Tidak ada penarikan yang pending'),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingWithdrawalsList.length,
              itemBuilder: (context, index) {
                final withdrawal = _pendingWithdrawalsList[index];
                return _buildWithdrawalCard(withdrawal, isPending: true);
              },
            ),
    );
  }

  Widget _buildApprovedWithdrawalsList() {
    return RefreshIndicator(
      onRefresh: _loadPendingWithdrawals,
      child: _approvedWithdrawalsList.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _buildEmptyState('Tidak ada penarikan yang disetujui'),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _approvedWithdrawalsList.length,
              itemBuilder: (context, index) {
                final withdrawal = _approvedWithdrawalsList[index];
                return _buildWithdrawalCard(withdrawal, isPending: false);
              },
            ),
    );
  }

  Widget _buildWithdrawalCard(WithdrawalModel withdrawal, {required bool isPending}) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currencyFormat.format(withdrawal.amount),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  withdrawal.created != null
                      ? DateFormat('dd MMM yyyy, HH:mm').format(withdrawal.created!)
                      : '',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Bank', withdrawal.bankName),
            _buildInfoRow('No Rekening', withdrawal.bankAccount),
            const SizedBox(height: 12),
            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectWithdrawal(withdrawal),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Tolak'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveWithdrawal(withdrawal),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _markAsTransferred(withdrawal),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Transfer Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveWithdrawal(WithdrawalModel withdrawal) async {
    try {
      await pb.collection('withdrawals').update(withdrawal.id, body: {
        'status': 'approved',
      });
      await _loadPendingWithdrawals();
      await _loadDashboardData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal disetujui'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _rejectWithdrawal(WithdrawalModel withdrawal) async {
    final reason = await _showRejectDialog();
    if (reason == null) return;

    try {
      await _withdrawalRepo.rejectWithdrawal(withdrawal.id, reason);
      await _loadPendingWithdrawals();
      await _loadDashboardData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal ditolak'), backgroundColor: AppColors.textSecondary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _markAsTransferred(WithdrawalModel withdrawal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Transfer'),
        content: Text(
          'Apakah Anda yakin sudah mentransfer Rp ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(withdrawal.amount)} ke ${withdrawal.bankName} - ${withdrawal.bankAccount}?\n\n'
          'Saldo mitra akan dipotong otomatis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Ya, Sudah Transfer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _withdrawalRepo.markAsTransferred(withdrawal.id);
        await _loadPendingWithdrawals();
        await _loadDashboardData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transfer berhasil dicatat, saldo mitra dipotong'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  Future<String?> _showRejectDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alasan Penolakan'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Masukkan alasan penolakan...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return RefreshIndicator(
      onRefresh: _loadRecentOrders,
      child: _recentOrders.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: _buildEmptyState('Tidak ada pesanan terbaru'),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _recentOrders.length,
              itemBuilder: (context, index) {
                final order = _recentOrders[index];
                return _buildOrderCard(order);
              },
            ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    Color statusColor;
    switch (order.status) {
      case 'pending':
        statusColor = AppColors.statusPending;
        break;
      case 'confirmed':
        statusColor = AppColors.statusConfirmed;
        break;
      case 'on_the_way':
        statusColor = AppColors.statusOnTheWay;
        break;
      case 'arrived':
        statusColor = AppColors.statusArrived;
        break;
      case 'in_progress':
        statusColor = AppColors.statusInProgress;
        break;
      case 'completed':
        statusColor = AppColors.statusCompleted;
        break;
      case 'cancelled':
        statusColor = AppColors.statusCancelled;
        break;
      default:
        statusColor = AppColors.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderCode,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Alamat', order.address),
            _buildInfoRow('Jadwal', DateFormat('dd MMM yyyy, HH:mm').format(order.scheduledAt)),
            _buildInfoRow('Total', currencyFormat.format(order.totalPrice + order.platformFee)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
