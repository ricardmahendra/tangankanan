import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/pocketbase/pb.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  final OrderRepository _repo = OrderRepository();
  late TabController _tabController;
  
  List<OrderModel> _allOrders = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });
      final userId = pb.authStore.record?.id ?? '';
      final data = await _repo.getUserOrders(userId);
      if (mounted) {
        setState(() {
          _allOrders = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<OrderModel> _getFilteredOrders(int tabIndex) {
    switch (tabIndex) {
      case 0: // Semua
        return _allOrders;
      case 1: // Aktif (pending, confirmed, on_the_way, arrived, in_progress)
        return _allOrders.where((o) => ['pending', 'confirmed', 'on_the_way', 'arrived', 'in_progress'].contains(o.status)).toList();
      case 2: // Selesai
        return _allOrders.where((o) => o.status == 'completed').toList();
      case 3: // Dibatalkan
        return _allOrders.where((o) => o.status == 'cancelled').toList();
      default:
        return _allOrders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Aktif'),
            Tab(text: 'Selesai'),
            Tab(text: 'Dibatalkan'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrders,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrderList(_getFilteredOrders(0)),
                    _buildOrderList(_getFilteredOrders(1)),
                    _buildOrderList(_getFilteredOrders(2)),
                    _buildOrderList(_getFilteredOrders(3)),
                  ],
                ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Belum ada pesanan.',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    
    // Status text and colors
    String statusText = order.status;
    Color statusColor = AppColors.primary;
    
    switch (order.status) {
      case 'pending':
        statusText = 'Menunggu Konfirmasi';
        statusColor = AppColors.warning;
        break;
      case 'confirmed':
        statusText = 'Dikonfirmasi';
        statusColor = AppColors.primaryMid;
        break;
      case 'on_the_way':
      case 'arrived':
      case 'in_progress':
        statusText = 'Sedang Berlangsung';
        statusColor = AppColors.primary;
        break;
      case 'completed':
        statusText = 'Selesai';
        statusColor = AppColors.success;
        break;
      case 'cancelled':
        statusText = 'Dibatalkan';
        statusColor = AppColors.danger;
        break;
    }

    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(order.scheduledAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          context.push('/order/tracking/${order.id}');
        },
        borderRadius: BorderRadius.circular(12),
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
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (order.partner != null)
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Mitra: ${order.partner!.name}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total (${order.items?.length ?? 0} Layanan)',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    currencyFormat.format(order.totalPrice + order.platformFee),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 16,
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
}
