import 'package:dio/dio.dart';
import '../../core/constants/app_constants.dart';

class PaymentRepository {
  final Dio _dio = Dio();

  /// Get Snap Token from Midtrans API
  /// In production, this should call your backend which then calls Midtrans
  /// For MVP, we'll simulate the Snap token generation
  Future<String> getSnapToken({
    required String orderId,
    required int amount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    try {
      // In production, call your backend endpoint
      // final response = await _dio.post(
      //   'https://your-backend.com/api/payment/snap-token',
      //   data: {
      //     'order_id': orderId,
      //     'amount': amount,
      //     'customer_name': customerName,
      //     'customer_email': customerEmail,
      //     'customer_phone': customerPhone,
      //   },
      // );
      // return response.data['snap_token'];

      // For MVP/development, we'll return a mock Snap token
      // This won't actually work with real Midtrans, but allows UI testing
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Generate a mock token (in production, this comes from Midtrans)
      final mockToken = 'SB-Mid-server-${orderId}-${DateTime.now().millisecondsSinceEpoch}';
      
      return mockToken;
    } catch (e) {
      throw Exception('Gagal mendapatkan Snap token: $e');
    }
  }

  /// Verify payment status from Midtrans
  /// In production, this should call your backend to verify with Midtrans
  Future<bool> verifyPayment(String orderId) async {
    try {
      // In production, call your backend endpoint
      // final response = await _dio.get(
      //   'https://your-backend.com/api/payment/verify/$orderId',
      // );
      // return response.data['status'] == 'success';

      // For MVP, assume payment is successful
      await Future.delayed(const Duration(milliseconds: 300));
      return true;
    } catch (e) {
      throw Exception('Gagal verifikasi pembayaran: $e');
    }
  }
}
