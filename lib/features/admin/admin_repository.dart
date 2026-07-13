import '../../core/pocketbase/pb.dart';
import '../../data/models/partner_model.dart';
import '../../data/models/withdrawal_model.dart';

class AdminRepository {
  /// Get all partners with is_verified = false
  Future<List<PartnerModel>> getPendingMitra() async {
    try {
      final records = await pb.collection('partners').getList(
            filter: 'is_verified = false',
            sort: '-created',
          );

      return records.items
          .map((record) => PartnerModel.fromRecord(record))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data mitra: $e');
    }
  }

  /// Approve/verify a partner
  Future<void> approveMitra(String mitraId) async {
    try {
      await pb.collection('partners').update(mitraId, body: {
        'is_verified': true,
        'is_active': true,
      });
    } catch (e) {
      throw Exception('Gagal verifikasi mitra: $e');
    }
  }

  /// Reject a partner
  Future<void> rejectMitra(String mitraId, String reason) async {
    try {
      await pb.collection('partners').update(mitraId, body: {
        'is_verified': false,
        'is_active': false,
      });

      // Optionally create a notification or log the rejection reason
      // You can store this in a separate collection if needed
    } catch (e) {
      throw Exception('Gagal menolak mitra: $e');
    }
  }

  /// Get all pending withdrawals
  Future<List<WithdrawalModel>> getPendingWithdrawals() async {
    try {
      final records = await pb.collection('withdrawals').getList(
            filter: 'status = "pending"',
            sort: '-created',
            expand: 'mitra_id',
          );

      return records.items
          .map((record) => WithdrawalModel.fromRecord(record))
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data penarikan: $e');
    }
  }

  /// Approve withdrawal
  Future<void> approveWithdrawal(String withdrawalId) async {
    try {
      await pb.collection('withdrawals').update(withdrawalId, body: {
        'status': 'approved',
        'processed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Gagal menyetujui penarikan: $e');
    }
  }

  /// Reject withdrawal
  Future<void> rejectWithdrawal(String withdrawalId, String reason) async {
    try {
      await pb.collection('withdrawals').update(withdrawalId, body: {
        'status': 'rejected',
        'note': reason,
        'processed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Gagal menolak penarikan: $e');
    }
  }

  /// Get admin statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final usersCount = await pb.collection('users').getList(page: 1, perPage: 1);
      final mitrasCount =
          await pb.collection('partners').getList(page: 1, perPage: 1);
      final pendingMitras = await pb
          .collection('partners')
          .getList(filter: 'is_verified = false', page: 1, perPage: 1);
      final pendingWithdrawals = await pb
          .collection('withdrawals')
          .getList(filter: 'status = "pending"', page: 1, perPage: 1);

      return {
        'total_users': usersCount.totalItems,
        'total_mitras': mitrasCount.totalItems,
        'pending_mitras': pendingMitras.totalItems,
        'pending_withdrawals': pendingWithdrawals.totalItems,
      };
    } catch (e) {
      throw Exception('Gagal mengambil statistik: $e');
    }
  }
}
