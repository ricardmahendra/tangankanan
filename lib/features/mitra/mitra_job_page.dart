import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';
import '../../core/location/location_service.dart';

class MitraJobPage extends StatefulWidget {
  final String orderId;
  const MitraJobPage({super.key, required this.orderId});

  @override
  State<MitraJobPage> createState() => _MitraJobPageState();
}

class _MitraJobPageState extends State<MitraJobPage> {
  final _orderRepo = OrderRepository();
  bool _isLoading = false;
  OrderModel? _order;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    setState(() => _isLoading = true);
    try {
      _order = await _orderRepo.getOrderDetail(widget.orderId);
    } catch (e) {
      print('Gagal mengambil detail dari repo: $e. Membuat mock detail.');
      _setMockOrder();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setMockOrder() {
    _order = OrderModel(
      id: widget.orderId,
      orderCode: widget.orderId.startsWith('mock') ? 'TK-889021' : 'TK-ORDER-${widget.orderId.substring(0, 4).toUpperCase()}',
      userId: 'mock_user_1',
      partnerId: 'mock_mitra_id',
      categoryId: 'cat_cleaning',
      address: 'Jl. Pemuda No. 45, RT 02 / RW 03, Kecamatan Jepara, Kabupaten Jepara',
      scheduledAt: DateTime.now().add(const Duration(hours: 1)),
      notes: 'Harap membersihkan area dapur dengan teliti. Lap kompor dan sink cuci piring.',
      totalPrice: 100000,
      platformFee: 12000,
      partnerIncome: 88000,
      status: 'confirmed', // confirmed, on_the_way, arrived, in_progress, completed
      paymentStatus: 'paid',
      paymentMethod: 'QRIS',
      items: const [
        OrderItemModel(
          id: 'item_1',
          orderId: 'mock_act_1',
          subcategoryId: 'sub_1',
          name: 'Menyapu & Mengepel Rumah',
          price: 50000,
          quantity: 1,
          subtotal: 50000,
        ),
        OrderItemModel(
          id: 'item_2',
          orderId: 'mock_act_1',
          subcategoryId: 'sub_2',
          name: 'Pembersihan Kamar Mandi',
          price: 35000,
          quantity: 1,
          subtotal: 35000,
        ),
        OrderItemModel(
          id: 'item_3',
          orderId: 'mock_act_1',
          subcategoryId: 'sub_3',
          name: 'Mengepel Teras Depan',
          price: 15000,
          quantity: 1,
          subtotal: 15000,
        )
      ],
    );
  }

  Future<void> _updateStatus(String nextStatus) async {
    if (_order == null) return;

    // 1. Validasi Jadwal (on_the_way)
    if (nextStatus == 'on_the_way') {
      final now = DateTime.now();
      // Boleh berangkat maksimal 2 jam sebelumnya
      final earliestDeparture = _order!.scheduledAt.subtract(const Duration(hours: 2));
      if (now.isBefore(earliestDeparture)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terlalu cepat! Anda hanya bisa berangkat maksimal 2 jam sebelum jadwal.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    // 2. Validasi Tiba (arrived)
    if (nextStatus == 'arrived') {
      setState(() => _isLoading = true);
      try {
        final locationService = LocationService();
        final hasPermission = await locationService.hasPermission() || await locationService.requestPermission();
        if (hasPermission) {
          final position = await locationService.getCurrentLocation();
          if (position != null) {
            // Simulasi: Order MVP saat ini tidak punya GPS koordinat di alamat,
            // Kita bypass dengan validasi radius if order.latitude != 0
            if (_order!.latitude != 0.0 && _order!.longitude != 0.0) {
              final distance = locationService.calculateDistance(
                position.latitude,
                position.longitude,
                _order!.latitude,
                _order!.longitude,
              );
              // Validasi radius (misal 500 meter = 0.5 km)
              if (distance > 0.5) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Anda belum berada di lokasi tujuan. (Jarak: ${locationService.formatDistance(distance)})'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                  setState(() => _isLoading = false);
                }
                return;
              }
            }
          }
        }
      } catch (e) {
        print('Gagal memvalidasi lokasi: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }

    setState(() => _isLoading = true);
    try {
      final updated = await _orderRepo.updateOrderStatus(widget.orderId, nextStatus);
      if (!mounted) return;
      setState(() {
        _order = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status pekerjaan diperbarui menjadi: ${nextStatus.replaceAll('_', ' ').toUpperCase()}'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      print('Gagal memperbarui status di backend: $e. Melakukan simulasi status lokal.');
      if (!mounted) return;
      
      // Local UI update simulation if database offline
      setState(() {
        _order = OrderModel(
          id: _order!.id,
          orderCode: _order!.orderCode,
          userId: _order!.userId,
          partnerId: _order!.partnerId,
          categoryId: _order!.categoryId,
          address: _order!.address,
          scheduledAt: _order!.scheduledAt,
          notes: _order!.notes,
          totalPrice: _order!.totalPrice,
          platformFee: _order!.platformFee,
          partnerIncome: _order!.partnerIncome,
          status: nextStatus,
          paymentStatus: nextStatus == 'completed' ? 'paid' : _order!.paymentStatus,
          paymentMethod: _order!.paymentMethod,
          items: _order!.items,
          completedAt: nextStatus == 'completed' ? DateTime.now() : null,
        );
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Simulasi: Status diperbarui menjadi ${nextStatus.replaceAll('_', ' ').toUpperCase()}'),
          backgroundColor: AppColors.success,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelJob() async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pekerjaan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Berikan alasan pembatalan pekerjaan ini:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Alasan pembatalan...',
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Alasan pembatalan wajib diisi!')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Batalkan Kerja'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        await _orderRepo.updateOrderStatus(
          widget.orderId,
          'cancelled',
          cancelledBy: 'partner',
          cancelReason: reasonController.text.trim(),
        );
        if (mounted) context.pop();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _order = OrderModel(
            id: _order!.id,
            orderCode: _order!.orderCode,
            userId: _order!.userId,
            partnerId: _order!.partnerId,
            categoryId: _order!.categoryId,
            address: _order!.address,
            scheduledAt: _order!.scheduledAt,
            notes: _order!.notes,
            totalPrice: _order!.totalPrice,
            platformFee: _order!.platformFee,
            partnerIncome: _order!.partnerIncome,
            status: 'cancelled',
            paymentStatus: _order!.paymentStatus,
            paymentMethod: _order!.paymentMethod,
            items: _order!.items,
            cancelledBy: 'partner',
            cancelReason: reasonController.text.trim(),
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Simulasi: Pekerjaan dibatalkan.')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
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

  @override
  Widget build(BuildContext context) {
    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Pekerjaan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final status = _order!.status;

    // Determine stepper current index
    int stepIndex = 0;
    if (status == 'on_the_way') stepIndex = 1;
    if (status == 'arrived') stepIndex = 2;
    if (status == 'in_progress') stepIndex = 3;
    if (status == 'completed') stepIndex = 4;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_order!.orderCode, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        actions: [
          if (status == 'confirmed')
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppColors.danger),
              onPressed: _cancelJob,
              tooltip: 'Batalkan Pekerjaan',
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stepper Status Alur Kerja
                  _buildStatusStepper(stepIndex),
                  const SizedBox(height: 24),

                  // Detail Customer Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pencari Jasa (Customer)',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primaryLight,
                              child: const Icon(Icons.person, color: AppColors.primaryMid),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _order!.user?.name ?? 'Siti Aminah (Customer)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _order!.user?.phone ?? '089876543210',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            // Chat Shortcut Button
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                              onPressed: () {
                                context.push('/chat/${_order!.id}');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppColors.primaryMid, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Alamat Rumah:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  const SizedBox(height: 2),
                                  Text(_order!.address, style: const TextStyle(fontSize: 13, height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Detail Layanan ordered
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Layanan Yang Dipesan',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (_order!.items != null)
                          ..._order!.items!.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.name} (x${item.quantity})',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Text(
                                      _formatRupiah(item.subtotal),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Pendapatan Kotor', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(_formatRupiah(_order!.totalPrice), style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Potongan Platform (12%)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text('- Rp 12.000', style: TextStyle(fontSize: 12, color: AppColors.danger)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Bersih Diterima',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            Text(
                              _formatRupiah(_order!.partnerIncome),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Catatan tambahan
                  if (_order!.notes.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Instruksi Khusus',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '"${_order!.notes}"',
                            style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textPrimary, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Tombol Status Dinamik
                  if (status != 'completed' && status != 'cancelled')
                    ElevatedButton(
                      onPressed: () {
                        if (status == 'confirmed') _updateStatus('on_the_way');
                        if (status == 'on_the_way') _updateStatus('arrived');
                        if (status == 'arrived') _updateStatus('in_progress');
                        if (status == 'in_progress') _updateStatus('completed');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getButtonColor(status),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_getButtonText(status)),
                    ),

                  if (status == 'completed')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle, color: AppColors.success),
                          SizedBox(width: 10),
                          Text(
                            'Pekerjaan Selesai & Dana Ditambahkan!',
                            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                  if (status == 'cancelled')
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.cancel, color: AppColors.danger),
                              SizedBox(width: 10),
                              Text(
                                'Pekerjaan Dibatalkan',
                                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          if (_order!.cancelReason.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Alasan: "${_order!.cancelReason}"',
                              style: const TextStyle(fontSize: 12, color: AppColors.danger, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusStepper(int currentStep) {
    final steps = ['Terkonfirmasi', 'Berangkat', 'Tiba', 'Mulai Kerja', 'Selesai'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(steps.length, (idx) {
              final isActive = idx <= currentStep;
              final isLast = idx == steps.length - 1;
              
              Color indicatorColor = isActive ? AppColors.primary : AppColors.border;
              if (idx == currentStep && currentStep == steps.length - 1) {
                indicatorColor = AppColors.success;
              }

              return Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: indicatorColor,
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2.5,
                          color: idx < currentStep ? AppColors.primary : AppColors.border,
                        ),
                      )
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps.map((step) {
              final isCurrent = steps.indexOf(step) == currentStep;
              return Text(
                step,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Color _getButtonColor(String status) {
    if (status == 'confirmed') return AppColors.primaryMid;
    if (status == 'on_the_way') return AppColors.statusOnTheWay;
    if (status == 'arrived') return AppColors.statusInProgress;
    if (status == 'in_progress') return AppColors.success;
    return AppColors.primary;
  }

  String _getButtonText(String status) {
    if (status == 'confirmed') return 'Saya Berangkat ke Lokasi';
    if (status == 'on_the_way') return 'Saya Sudah Tiba di Lokasi';
    if (status == 'arrived') return 'Mulai Pekerjaan';
    if (status == 'in_progress') return 'Pekerjaan Selesai';
    return 'Lanjut';
  }
}
