import 'package:pocketbase/pocketbase.dart';
import '../../core/pocketbase/pb.dart';
import '../../core/exceptions/app_exception.dart';
import '../models/order_model.dart';

class OrderRepository {
  /// Fetch incoming jobs for a partner (status is pending)
  Future<List<OrderModel>> getIncomingOrders(String partnerId) async {
    try {
      final records = await pb.collection('orders').getList(
        filter: 'partner_id = "$partnerId" && status = "pending"',
        sort: '-created',
        expand: 'user_id,order_items(order_id)',
      );
      return records.items.map((r) => OrderModel.fromRecord(r)).toList();
    } catch (e) {
      throw NetworkException(message: 'Gagal memuat pesanan masuk. Periksa koneksi internet.');
    }
  }

  /// Fetch active orders for a user (pending through in_progress)
  Future<List<OrderModel>> getUserActiveOrders(String userId) async {
    try {
      final records = await pb.collection('orders').getList(
        filter:
            'user_id = "$userId" && (status = "pending" || status = "confirmed" || status = "on_the_way" || status = "arrived" || status = "in_progress")',
        sort: '-created',
        expand: 'partner_id,order_items(order_id)',
      );
      return records.items.map((r) => OrderModel.fromRecord(r)).toList();
    } catch (e) {
      throw NetworkException(message: 'Gagal memuat pesanan aktif. Periksa koneksi internet.');
    }
  }

  /// Fetch all orders for a specific user (History for User App)
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final records = await pb.collection('orders').getList(
        filter: 'user_id = "$userId"',
        sort: '-created',
        expand: 'partner_id,order_items(order_id)',
      );
      return records.items.map((r) => OrderModel.fromRecord(r)).toList();
    } catch (e) {
      throw NetworkException(message: 'Gagal memuat riwayat pesanan. Periksa koneksi internet.');
    }
  }

  /// Fetch active jobs for a partner (status: confirmed, on_the_way, arrived, in_progress)
  Future<List<OrderModel>> getActiveOrders(String partnerId) async {
    try {
      final records = await pb.collection('orders').getList(
        filter: 'partner_id = "$partnerId" && (status = "confirmed" || status = "on_the_way" || status = "arrived" || status = "in_progress")',
        sort: '-created',
        expand: 'user_id,order_items(order_id)',
      );
      return records.items.map((r) => OrderModel.fromRecord(r)).toList();
    } catch (e) {
      throw NetworkException(message: 'Gagal memuat pesanan aktif. Periksa koneksi internet.');
    }
  }

  /// Fetch completed and cancelled job history for a partner
  Future<List<OrderModel>> getJobHistory(String partnerId) async {
    try {
      final records = await pb.collection('orders').getList(
        filter: 'partner_id = "$partnerId" && (status = "completed" || status = "cancelled")',
        sort: '-created',
        expand: 'user_id,order_items(order_id)',
      );
      return records.items.map((r) => OrderModel.fromRecord(r)).toList();
    } catch (e) {
      throw NetworkException(message: 'Gagal memuat riwayat pesanan. Periksa koneksi internet.');
    }
  }

  /// Get order details by ID
  Future<OrderModel> getOrderDetail(String orderId) async {
    try {
      final record = await pb.collection('orders').getOne(
        orderId,
        expand: 'user_id,partner_id,order_items(order_id)',
      );
      return OrderModel.fromRecord(record);
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        throw NotFoundException(message: 'Pesanan tidak ditemukan.');
      }
      throw NetworkException(message: 'Gagal memuat detail pesanan. Periksa koneksi internet.');
    } catch (e) {
      throw NetworkException(message: 'Gagal memuat detail pesanan.');
    }
  }

  /// Create a new order and its order items
  Future<OrderModel> createOrder({
    required String orderCode,
    required String userId,
    required String partnerId,
    required String categoryId,
    required String address,
    required DateTime scheduledAt,
    required String notes,
    required int totalPrice,
    required int platformFee,
    required int partnerIncome,
    required String paymentMethod,
    required List<Map<String, dynamic>> itemsData,
  }) async {
    try {
      // 1. Create Order
      final orderRecord = await pb.collection('orders').create(
        body: {
          'order_code': orderCode,
          'user_id': userId,
          'partner_id': partnerId,
          'category_id': categoryId,
          'address': address,
          'scheduled_at': scheduledAt.toIso8601String(),
          'notes': notes,
          'total_price': totalPrice,
          'platform_fee': platformFee,
          'partner_income': partnerIncome,
          'status': 'pending',
          'payment_status': 'paid',
          'payment_method': paymentMethod,
        },
      );

      // 2. Create Order Items
      final orderId = orderRecord.id;
      for (final item in itemsData) {
        await pb.collection('order_items').create(body: {
          'order_id': orderId,
          'subcategory_id': item['subcategory_id'],
          'name': item['name'],
          'price': item['price'],
          'quantity': item['quantity'],
          'subtotal': item['subtotal'],
        });
      }

      // 3. Return full order with expands
      return getOrderDetail(orderId);
    } catch (e) {
      throw NetworkException(message: 'Gagal membuat pesanan. Periksa koneksi internet.');
    }
  }

  /// Update order status (with optional cancel fields)
  /// If completing the order, we update the status and record completion time.
  Future<OrderModel> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? cancelledBy,
    String? cancelReason,
  }) async {
    try {
      final body = <String, dynamic>{
        'status': newStatus,
      };

      if (newStatus == 'completed') {
        body['completed_at'] = DateTime.now().toIso8601String();
        body['payment_status'] = 'paid'; // Ensure it's paid when completed
      }

      if (newStatus == 'cancelled') {
        if (cancelledBy != null) body['cancelled_by'] = cancelledBy;
        if (cancelReason != null) body['cancel_reason'] = cancelReason;
        body['payment_status'] = 'refunded';
      }

      final record = await pb.collection('orders').update(
        orderId,
        body: body,
        expand: 'user_id,partner_id,order_items(order_id)',
      );

      // Handle balance updates locally if backend hook isn't active
      // In production, this should run in a PocketBase backend hook/transaction.
      if (newStatus == 'completed') {
        final order = OrderModel.fromRecord(record);
        final partnerId = order.partnerId;
        if (partnerId.isNotEmpty) {
          try {
            final partnerRecord = await pb.collection('partners').getOne(partnerId);
            final currentBalance = partnerRecord.getIntValue('balance');
            await pb.collection('partners').update(partnerId, body: {
              'balance': currentBalance + order.partnerIncome,
              'total_jobs': partnerRecord.getIntValue('total_jobs') + 1,
            });
          } catch (balanceErr) {
            // Log balance error but don't crash
            print('Gagal memperbarui saldo mitra secara lokal: $balanceErr');
          }
        }
      }

      return OrderModel.fromRecord(record);
    } catch (e) {
      throw NetworkException(message: 'Gagal memperbarui status pesanan. Periksa koneksi internet.');
    }
  }

  /// Realtime subscription to partner's orders
  Future<void> subscribeToOrders(String partnerId, Function(RecordSubscriptionEvent) onEvent) async {
    try {
      await pb.collection('orders').subscribe('*', (e) {
        // Filter events for this partner
        final record = e.record;
        if (record != null && record.getStringValue('partner_id') == partnerId) {
          onEvent(e);
        }
      });
    } catch (e) {
      print('Gagal subscribe realtime orders: $e');
    }
  }

  /// Unsubscribe from order updates
  Future<void> unsubscribeFromOrders() async {
    try {
      await pb.collection('orders').unsubscribe('*');
    } catch (e) {
      print('Gagal unsubscribe realtime orders: $e');
    }
  }

  /// Get recent orders for admin dashboard
  Future<List<OrderModel>> getRecentOrders(int limit) async {
    try {
      final records = await pb.collection('orders').getList(
        page: 1,
        perPage: limit,
        sort: '-created',
        expand: 'user_id,partner_id,order_items(order_id)',
      );
      return records.items.map((r) => OrderModel.fromRecord(r)).toList();
    } catch (e) {
      throw Exception('Gagal memuat pesanan terbaru: $e');
    }
  }
}
