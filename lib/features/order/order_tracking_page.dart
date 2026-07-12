import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../core/pocketbase/pb.dart' as import_pb;

class OrderTrackingPage extends StatefulWidget {
  final String orderId;

  const OrderTrackingPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final OrderRepository _repo = OrderRepository();
  bool _isLoading = true;
  String _error = '';
  OrderModel? _order;

  // Track status indices for the stepper
  final List<String> _statusList = [
    'pending',
    'confirmed',
    'on_the_way',
    'arrived',
    'in_progress',
    'completed'
  ];

  final Map<String, String> _statusDisplay = {
    'pending': 'Menunggu Konfirmasi',
    'confirmed': 'Mitra Dikonfirmasi',
    'on_the_way': 'Mitra Menuju Lokasi',
    'arrived': 'Mitra Tiba',
    'in_progress': 'Pekerjaan Berlangsung',
    'completed': 'Selesai',
    'cancelled': 'Dibatalkan',
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final order = await _repo.getOrderDetail(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
      _setupRealtimeSubscription();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setupRealtimeSubscription() {
    if (_order == null) return;
    
    // Using the partner id for subscription wouldn't work easily here since we want to listen to a specific order ID.
    // The OrderRepository currently has subscribeToOrders which filters by partnerId.
    // Let's create a custom subscription here for the specific order.
    import_pb.pb.collection('orders').subscribe(widget.orderId, (e) {
      if (e.record != null && mounted) {
        // We get a raw record back, fetch full details to get expands (like partner info if it changed)
        _repo.getOrderDetail(widget.orderId).then((updatedOrder) {
          if (mounted) {
            setState(() {
              _order = updatedOrder;
            });
          }
        });
      }
    }).catchError((err) {
      print('Realtime subscription error: $err');
      return () async {}; // Return empty async function to satisfy UnsubscribeFunc return type
    });
  }

  @override
  void dispose() {
    import_pb.pb.collection('orders').unsubscribe(widget.orderId);
    super.dispose();
  }

  void _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini? Saldo Anda akan dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        await _repo.updateOrderStatus(
          widget.orderId,
          'cancelled',
          cancelledBy: 'user',
          cancelReason: 'Dibatalkan oleh pengguna',
        );
        // The realtime subscription will update the UI to cancelled
        setState(() => _isLoading = false);
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membatalkan: $e'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lacak Pesanan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/main'), // Always go to main from tracking to prevent back stack weirdness
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(child: Text(_error));
    }
    if (_order == null) {
      return const Center(child: Text('Pesanan tidak ditemukan'));
    }

    final isCancelled = _order!.status == 'cancelled';
    final currentStatusIndex = _statusList.indexOf(_order!.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _order!.orderCode,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isCancelled ? AppColors.danger : AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusDisplay[_order!.status] ?? _order!.status,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stepper
          if (!isCancelled)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: List.generate(_statusList.length, (index) {
                  final status = _statusList[index];
                  final isActive = index <= currentStatusIndex;
                  final isLast = index == _statusList.length - 1;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? AppColors.primary : AppColors.border,
                            ),
                            child: isActive
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                          if (!isLast)
                            Container(
                              width: 2,
                              height: 30,
                              color: isActive && index < currentStatusIndex
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _statusDisplay[status]!,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                              color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          if (isCancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cancel, color: AppColors.danger, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Pesanan Dibatalkan',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: AppColors.danger,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _order!.cancelReason.isNotEmpty ? _order!.cancelReason : '-',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Partner Card
          if (_order!.partner != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mitra',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _order!.partner!.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isCancelled)
                    IconButton(
                      icon: const Icon(Icons.chat, color: AppColors.primary),
                      onPressed: () {
                        context.push('/chat/${_order!.id}');
                      },
                    ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Cancel Button (Only if pending or confirmed)
          if (!isCancelled && (_order!.status == 'pending' || _order!.status == 'confirmed'))
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _cancelOrder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Batalkan Pesanan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Review Button (Only if completed)
          if (_order!.status == 'completed')
             SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/order/review/${_order!.id}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Beri Ulasan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

