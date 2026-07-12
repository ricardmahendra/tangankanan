import 'package:pocketbase/pocketbase.dart';
import '../../core/pocketbase/pb.dart';
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
      throw Exception('Gagal memuat pesanan masuk: $e');
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
      throw Exception('Gagal memuat pesanan aktif: $e');
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
      throw Exception('Gagal memuat riwayat pesanan: $e');
    }
  }

  /// Get order details by ID
  Future<OrderModel> getOrderDetail(String orderId) async {
    try {
      final record = await pb.collection('orders').getOne(
        orderId,
        expand: 'user_id,order_items(order_id)',
      );
      return OrderModel.fromRecord(record);
    } catch (e) {
      throw Exception('Gagal memuat detail pesanan: $e');
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
      }

      final record = await pb.collection('orders').update(
        orderId,
        body: body,
        expand: 'user_id,order_items(order_id)',
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
      throw Exception('Gagal memperbarui status pesanan: $e');
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
}
