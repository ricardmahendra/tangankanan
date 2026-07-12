import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/partner_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/models/order_model.dart';

class MitraJobTab extends StatefulWidget {
  const MitraJobTab({super.key});

  @override
  State<MitraJobTab> createState() => _MitraJobTabState();
}

class _MitraJobTabState extends State<MitraJobTab> {
  final _partnerRepo = PartnerRepository();
  final _orderRepo = OrderRepository();

  bool _isLoading = false;
  String _partnerId = 'mock_mitra_id';
  
  List<OrderModel> _incomingOrders = [];
  List<OrderModel> _activeOrders = [];
  List<OrderModel> _historyOrders = [];

  // Countdown timers mapping (for simulated incoming job timers)
  final Map<String, int> _orderCountdowns = {};
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    final p = _partnerRepo.getCurrentPartner();
    if (p != null) {
      _partnerId = p.id;
    }
    _loadJobs();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _orderRepo.unsubscribeFromOrders();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() => _isLoading = true);
    try {
      // Load real database data if possible
      _incomingOrders = await _orderRepo.getIncomingOrders(_partnerId);
      _activeOrders = await _orderRepo.getActiveOrders(_partnerId);
      _historyOrders = await _orderRepo.getJobHistory(_partnerId);
    } catch (e) {
      print('Gagal memuat pesanan dari repo, menyetel fallback mock data: $e');
      _setMockData();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setMockData() {
    // Mock Incoming Orders (status = pending)
    _incomingOrders = [
      OrderModel(
        id: 'mock_inc_1',
        orderCode: 'TK-110293',
        userId: 'user_a',
        partnerId: _partnerId,
        categoryId: 'cat_cleaning',
        address: 'Perumahan Graha Kartini Blok A10, Jepara',
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        notes: 'Bersihkan dapur dan kamar mandi utama.',
        totalPrice: 75000,
        platformFee: 9000,
        partnerIncome: 66000,
        status: 'pending',
        created: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];

    // Initialize countdowns (simulating remaining seconds of 10-minute timer)
    for (var order in _incomingOrders) {
      final elapsedSecs = DateTime.now().difference(order.created ?? DateTime.now()).inSeconds;
      final remainingSecs = (10 * 60) - elapsedSecs;
      _orderCountdowns[order.id] = remainingSecs > 0 ? remainingSecs : 0;
    }

    // Mock Active Orders (status = confirmed/on_the_way/arrived/in_progress)
    _activeOrders = [
      OrderModel(
        id: 'mock_act_1',
        orderCode: 'TK-889021',
        userId: 'user_b',
        partnerId: _partnerId,
        categoryId: 'cat_laundry',
        address: 'Jl. Pemuda No. 45, Jepara',
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
        notes: 'Cuci pakaian 5 kg, tolong disetrika rapi.',
        totalPrice: 50000,
        platformFee: 6000,
        partnerIncome: 44000,
        status: 'confirmed',
      )
    ];

    // Mock History Orders (status = completed/cancelled)
    _historyOrders = [
      OrderModel(
        id: 'mock_his_1',
        orderCode: 'TK-774910',
        userId: 'user_c',
        partnerId: _partnerId,
        categoryId: 'cat_cleaning',
        address: 'Perum Tahunan Indah Blok C3, Jepara',
        scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
        totalPrice: 40000,
        platformFee: 4800,
        partnerIncome: 35200,
        status: 'completed',
        completedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      OrderModel(
        id: 'mock_his_2',
        orderCode: 'TK-551029',
        userId: 'user_d',
        partnerId: _partnerId,
        categoryId: 'cat_maintenance',
        address: 'Desa Senenan RT 03/RW 01, Jepara',
        scheduledAt: DateTime.now().subtract(const Duration(days: 3)),
        totalPrice: 150000,
        platformFee: 18000,
        partnerIncome: 132000,
        status: 'completed',
        completedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      OrderModel(
        id: 'mock_his_3',
        orderCode: 'TK-443912',
        userId: 'user_e',
        partnerId: _partnerId,
        categoryId: 'cat_helper',
        address: 'Jl. Shima No. 12, Jepara',
        scheduledAt: DateTime.now().subtract(const Duration(days: 5)),
        totalPrice: 60000,
        platformFee: 7200,
        partnerIncome: 52800,
        status: 'cancelled',
        cancelledBy: 'user',
        cancelReason: 'Salah pilih waktu penjadwalan.',
      )
    ];
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      bool hasUpdates = false;
      _orderCountdowns.forEach((key, value) {
        if (value > 0) {
          _orderCountdowns[key] = value - 1;
          hasUpdates = true;
        } else if (value == 0) {
          // Timeout, trigger auto-reject logic locally
          _orderCountdowns[key] = -1; // Flag as timed out
          _handleAutoCancel(key);
          hasUpdates = true;
        }
      });

      if (hasUpdates) {
        setState(() {});
      }
    });
  }

  Future<void> _handleAutoCancel(String orderId) async {
    try {
      await _orderRepo.updateOrderStatus(orderId, 'cancelled', cancelledBy: 'admin', cancelReason: 'Batas waktu respon habis (10 menit).');
    } catch (e) {
      print('Gagal membatalkan pesanan kedaluwarsa: $e');
    }
    _loadJobs();
  }

  Future<void> _acceptOrder(String orderId) async {
    setState(() => _isLoading = true);
    try {
      await _orderRepo.updateOrderStatus(orderId, 'confirmed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil diterima!'), backgroundColor: AppColors.success),
      );
      // Automatically navigate to the tracking page for this job
      context.push('/mitra/job/$orderId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menerima pesanan: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) {
        _loadJobs();
      }
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    setState(() => _isLoading = true);
    try {
      await _orderRepo.updateOrderStatus(orderId, 'cancelled', cancelledBy: 'partner', cancelReason: 'Ditolak oleh mitra.');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan berhasil ditolak.'), backgroundColor: AppColors.textSecondary),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menolak pesanan: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) {
        _loadJobs();
      }
    }
  }

  String _formatRupiah(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatTimer(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Kelola Pekerjaan', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.surface,
          elevation: 0.5,
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Pesanan Baru'),
              Tab(text: 'Aktif'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildIncomingTab(),
                  _buildActiveTab(),
                  _buildHistoryTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildIncomingTab() {
    if (_incomingOrders.isEmpty) {
      return _buildEmptyState('Belum ada tawaran masuk.', Icons.notifications_none_outlined);
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _incomingOrders.length,
        itemBuilder: (context, index) {
          final order = _incomingOrders[index];
          final countdown = _orderCountdowns[order.id] ?? 600;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer, color: AppColors.danger, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _formatTimer(countdown),
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        order.orderCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.border),
                
                // Job Details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppColors.primaryMid, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.address,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.schedule_outlined, color: AppColors.primaryMid, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(order.scheduledAt),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      if (order.notes.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Catatan: "${order.notes}"',
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                const Divider(color: AppColors.border, height: 1),

                // Footer Actions
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rejectOrder(order.id),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.danger),
                            foregroundColor: AppColors.danger,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Tolak'),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _acceptOrder(order.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Terima'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveTab() {
    if (_activeOrders.isEmpty) {
      return _buildEmptyState('Tidak ada pekerjaan berjalan.', Icons.assignment_outlined);
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _activeOrders.length,
        itemBuilder: (context, index) {
          final order = _activeOrders[index];
          
          Color badgeColor;
          switch (order.status) {
            case 'confirmed':
              badgeColor = AppColors.statusConfirmed;
              break;
            case 'on_the_way':
              badgeColor = AppColors.statusOnTheWay;
              break;
            case 'arrived':
              badgeColor = AppColors.statusArrived;
              break;
            case 'in_progress':
              badgeColor = AppColors.statusInProgress;
              break;
            default:
              badgeColor = AppColors.primary;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: InkWell(
              onTap: () => context.push('/mitra/job/${order.id}'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
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
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            order.status.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          order.orderCode,
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
                            order.address,
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
                          DateFormat('dd MMM yyyy, HH:mm').format(order.scheduledAt),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatRupiah(order.partnerIncome),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Text(
                          'Kelola Status \u2192',
                          style: TextStyle(
                            color: AppColors.primaryMid,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_historyOrders.isEmpty) {
      return _buildEmptyState('Belum ada riwayat pekerjaan.', Icons.history_toggle_off);
    }

    return RefreshIndicator(
      onRefresh: _loadJobs,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historyOrders.length,
        itemBuilder: (context, index) {
          final order = _historyOrders[index];
          final isCompleted = order.status == 'completed';
          final statusText = isCompleted ? 'SELESAI' : 'DIBATALKAN';
          final badgeColor = isCompleted ? AppColors.statusCompleted : AppColors.statusCancelled;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Padding(
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
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        order.orderCode,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    order.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(order.scheduledAt),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (!isCompleted && order.cancelReason.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Alasan: ${order.cancelReason}',
                      style: const TextStyle(fontSize: 12, color: AppColors.danger, fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 10),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pendapatan Bersih',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        isCompleted ? '+ ${_formatRupiah(order.partnerIncome)}' : 'Rp 0',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? AppColors.success : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String text, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
