import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:midtrans_sdk/midtrans_sdk.dart';
import '../../core/constants/app_colors.dart';
import '../../core/pocketbase/pb.dart';
import '../../data/models/order_flow_data.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/payment_repository.dart';
import 'package:uuid/uuid.dart';

class OrderConfirmPage extends StatefulWidget {
  final OrderFlowData flowData;

  const OrderConfirmPage({
    super.key,
    required this.flowData,
  });

  @override
  State<OrderConfirmPage> createState() => _OrderConfirmPageState();
}

class _OrderConfirmPageState extends State<OrderConfirmPage> {
  final OrderRepository _repo = OrderRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();
  bool _isProcessing = false;
  
  // Selected payment method (defaulting to QRIS)
  String _paymentMethod = 'QRIS';
  final List<String> _paymentOptions = ['QRIS', 'Transfer Bank', 'E-Wallet'];

  @override
  void initState() {
    super.initState();
    _initMidtrans();
  }

  void _initMidtrans() {
    // Initialize Midtrans SDK
    // In production, use your actual client key from Midtrans dashboard
    MidtransSDK.init(
      clientKey: 'SB-Mid-client-xxx', // Replace with your actual client key
      merchantBaseUrl: 'https://your-backend.com', // Your backend URL
      enableLog: true,
    );
  }

  Future<void> _processPaymentAndOrder() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final userRecord = pb.authStore.record;
      if (userRecord == null) throw Exception('Sesi pengguna tidak valid');

      // Calculate financials
      final totalPrice = widget.flowData.totalPrice;
      final platformFee = (totalPrice * 0.12).round();
      final partnerIncome = (totalPrice * 0.88).round();
      final grandTotal = totalPrice + platformFee;
      
      // Generate unique order code
      final shortUuid = const Uuid().v4().substring(0, 6).toUpperCase();
      final orderCode = 'TK-$shortUuid';

      // Prepare items data
      final itemsData = widget.flowData.selectedItems.map((sel) {
        return {
          'subcategory_id': sel.subcategory.id,
          'name': sel.subcategory.name,
          'price': sel.subcategory.price,
          'quantity': sel.quantity,
          'subtotal': sel.subtotal,
        };
      }).toList();

      // Get Snap Token from Midtrans
      final snapToken = await _paymentRepo.getSnapToken(
        orderId: orderCode,
        amount: grandTotal,
        customerName: userRecord.getStringValue('name'),
        customerEmail: userRecord.getStringValue('email'),
        customerPhone: userRecord.getStringValue('phone'),
      );

      // Open Midtrans Snap UI
      final result = await MidtransSDK.startPaymentUi(
        snapToken: snapToken,
        skipCustomerDetails: true,
      );

      if (result.transactionStatus == 'settlement' || 
          result.transactionStatus == 'capture') {
        // Payment successful, create order
        final order = await _repo.createOrder(
          orderCode: orderCode,
          userId: userRecord.id,
          partnerId: widget.flowData.selectedPartner!.id,
          categoryId: widget.flowData.category.id,
          address: widget.flowData.address,
          scheduledAt: widget.flowData.scheduledAt!,
          notes: widget.flowData.notes,
          totalPrice: totalPrice,
          platformFee: platformFee,
          partnerIncome: partnerIncome,
          paymentMethod: _paymentMethod,
          itemsData: itemsData,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran berhasil! Menunggu konfirmasi mitra.'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/order/tracking/${order.id}');
        }
      } else {
        // Payment failed or cancelled
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pembayaran ${result.transactionStatus ?? 'gagal'}. Silakan coba lagi.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final totalPrice = widget.flowData.totalPrice;
    final platformFee = (totalPrice * 0.12).round();
    final grandTotal = totalPrice + platformFee;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Konfirmasi Pesanan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isProcessing
          ? _buildLoadingState()
          : _buildBody(currencyFormat, platformFee, grandTotal),
      bottomNavigationBar: _isProcessing
          ? null
          : _buildBottomBar(currencyFormat, grandTotal),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 24),
          Text(
            'Memproses Pembayaran...\nMohon tunggu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(NumberFormat format, int platformFee, int grandTotal) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mitra Section
          const Text(
            'Mitra Terpilih',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
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
                      Text(
                        widget.flowData.selectedPartner!.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.warning, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            widget.flowData.selectedPartner!.rating.toStringAsFixed(1),
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Detail Layanan Section
          const Text(
            'Detail Layanan',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(widget.flowData.scheduledAt!),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.flowData.address,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                ...widget.flowData.selectedItems.map((sel) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${sel.subcategory.name} (x${sel.quantity})',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                            ),
                          ),
                          Text(
                            format.format(sel.subtotal),
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 24),
          
          // Payment Method Section
          const Text(
            'Metode Pembayaran',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: _paymentOptions.map((option) {
                return RadioListTile<String>(
                  title: Text(
                    option,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                  ),
                  value: option,
                  groupValue: _paymentMethod,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _paymentMethod = val!;
                    });
                  },
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Ringkasan Pembayaran
          const Text(
            'Ringkasan Pembayaran',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                    Text(format.format(widget.flowData.totalPrice), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Biaya Layanan (12%)', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                    Text(format.format(platformFee), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pembayaran',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      format.format(grandTotal),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(NumberFormat format, int grandTotal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _processPaymentAndOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Bayar ${format.format(grandTotal)}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
