import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/partner_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/models/partner_model.dart';
import '../../../data/models/order_model.dart';

class MitraHomeTab extends StatefulWidget {
  const MitraHomeTab({super.key});

  @override
  State<MitraHomeTab> createState() => _MitraHomeTabState();
}

class _MitraHomeTabState extends State<MitraHomeTab> {
  final _partnerRepo = PartnerRepository();
  final _orderRepo = OrderRepository();

  PartnerModel? _partner;
  List<OrderModel> _activeJobs = [];
  List<OrderModel> _completedJobs = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // 1. Get current logged in partner
    final activePartner = _partnerRepo.getCurrentPartner();
    if (activePartner != null) {
      _partner = activePartner;
    } else {
      // Mock partner data for local UI development when PocketBase is not authenticated
      _partner = const PartnerModel(
        id: 'mock_mitra_id',
        name: 'Budi Santoso',
        phone: '081234567890',
        nik: '3320010203040001',
        bio: 'Penyedia jasa kebersihan dan kelistrikan berpengalaman di Jepara.',
        isOnline: true,
        isVerified: true,
        rating: 4.8,
        totalJobs: 24,
        balance: 350000,
        bankName: 'Bank Central Asia (BCA)',
        bankAccount: '1234567890',
      );
    }

    try {
      if (_partner != null) {
        // Fetch active jobs
        _activeJobs = await _orderRepo.getActiveOrders(_partner!.id);
        
        // Fetch completed jobs for earnings overview
        final history = await _orderRepo.getJobHistory(_partner!.id);
        _completedJobs = history.where((o) => o.status == 'completed').take(5).toList();
      }
    } catch (e) {
      print('Gagal mengambil data pesanan: $e');
      // Mock active job and earnings list if database fails or is empty
      if (_activeJobs.isEmpty) {
        _activeJobs = [
          OrderModel(
            id: 'mock_order_1',
            orderCode: 'TK-889021',
            userId: 'user_1',
            partnerId: _partner!.id,
            categoryId: 'cat_cleaning',
            address: 'Jl. Pemuda No. 45, Jepara',
            scheduledAt: DateTime.now().add(const Duration(hours: 2)),
            notes: 'Mengepel seluruh lantai dan bersihkan debu lemari.',
            totalPrice: 50000,
            platformFee: 6000,
            partnerIncome: 44000,
            status: 'confirmed',
          )
        ];
      }

      if (_completedJobs.isEmpty) {
        _completedJobs = [
          OrderModel(
            id: 'mock_order_2',
            orderCode: 'TK-774910',
            userId: 'user_2',
            partnerId: _partner!.id,
            categoryId: 'cat_laundry',
            address: 'Perum Tahunan Indah Blok C3, Jepara',
            scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
            totalPrice: 40000,
            platformFee: 4800,
            partnerIncome: 35200,
            status: 'completed',
            completedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          OrderModel(
            id: 'mock_order_3',
            orderCode: 'TK-551029',
            userId: 'user_3',
            partnerId: _partner!.id,
            categoryId: 'cat_maintenance',
            address: 'Desa Senenan RT 03/RW 01, Jepara',
            scheduledAt: DateTime.now().subtract(const Duration(days: 3)),
            totalPrice: 150000,
            platformFee: 18000,
            partnerIncome: 132000,
            status: 'completed',
            completedAt: DateTime.now().subtract(const Duration(days: 3)),
          )
        ];
      }
    }
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    if (_partner == null) return;
    
    setState(() {
      _partner = PartnerModel(
        id: _partner!.id,
        name: _partner!.name,
        phone: _partner!.phone,
        nik: _partner!.nik,
        bio: _partner!.bio,
        isOnline: value,
        isVerified: _partner!.isVerified,
        rating: _partner!.rating,
        totalJobs: _partner!.totalJobs,
        balance: _partner!.balance,
        bankName: _partner!.bankName,
        bankAccount: _partner!.bankAccount,
      );
    });

    try {
      await _partnerRepo.updateOnlineStatus(_partner!.id, value);
    } catch (e) {
      print('Gagal memperbarui status online di backend: $e');
    }
  }

  String _formatRupiah(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_partner == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Profil Mitra
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primaryMid,
                      child: Text(
                        _partner!.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${_partner!.name} 👋',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _partner!.isOnline ? AppColors.success : AppColors.danger,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _partner!.isOnline ? 'Aktif menerima pesanan' : 'Tidak aktif',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Online/Offline Switch Toggle
                    Switch.adaptive(
                      value: _partner!.isOnline,
                      onChanged: _toggleOnlineStatus,
                      activeTrackColor: AppColors.success.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.success,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Kartu Dompet & Saldo
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryMid],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saldo Aktif Anda',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatRupiah(_partner!.balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: Colors.white30, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Min. Penarikan Rp 50.000',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              // Direct to Finance tab by clicking here
                              // This is simple for the user.
                            },
                            child: Row(
                              children: const [
                                Text(
                                  'Kelola Saldo',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Row Statistik Utama
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: AppColors.warning, size: 28),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _partner!.rating.toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Rating Anda',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.done_all, color: AppColors.success, size: 28),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_partner!.totalJobs} Pekerjaan',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Selesai',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Seksi Pekerjaan Aktif
                Text(
                  'Pekerjaan Aktif Saat Ini',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (_activeJobs.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      children: const [
                        Icon(
                          Icons.work_off_outlined,
                          size: 44,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada pekerjaan aktif.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ..._activeJobs.map((job) => _buildActiveJobCard(job)),

                const SizedBox(height: 24),

                // Seksi Pendapatan Terbaru
                Text(
                  'Pendapatan Terakhir',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _completedJobs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final job = _completedJobs[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.payments_outlined,
                              color: AppColors.primaryMid,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job.orderCode,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  job.completedAt != null
                                      ? DateFormat('dd MMM yyyy, HH:mm').format(job.completedAt!)
                                      : 'Selesai',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+ ${_formatRupiah(job.partnerIncome)}',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveJobCard(OrderModel job) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.statusConfirmed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    job.status.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.statusConfirmed,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  job.orderCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.primaryMid, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    job.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule_outlined, color: AppColors.primaryMid, size: 20),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm').format(job.scheduledAt),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pendapatan Bersih',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    Text(
                      _formatRupiah(job.partnerIncome),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to MitraJobPage with jobId
                    context.push('/mitra/job/${job.id}');
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(120, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Detail Kerja', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
