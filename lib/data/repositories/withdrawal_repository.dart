import '../../core/pocketbase/pb.dart';
import '../../core/exceptions/app_exception.dart';
import '../models/withdrawal_model.dart';

class WithdrawalRepository {
  /// Fetch withdrawal list for a partner
  Future<List<WithdrawalModel>> getWithdrawals(String partnerId) async {
    try {
      final records = await pb.collection('withdrawals').getList(
        filter: 'partner_id = "$partnerId"',
        sort: '-created',
      );
      return records.items.map((r) => WithdrawalModel.fromRecord(r)).toList();
    } catch (e) {
      throw NetworkException(message: 'Gagal memuat riwayat penarikan. Periksa koneksi internet.');
    }
  }

  /// Submit a new withdrawal request
  Future<WithdrawalModel> requestWithdrawal({
    required String partnerId,
    required int amount,
    required String bankName,
    required String bankAccount,
  }) async {
    try {
      // 1. Fetch partner record to verify balance
      final partnerRecord = await pb.collection('partners').getOne(partnerId);
      final currentBalance = partnerRecord.getIntValue('balance');

      if (currentBalance < amount) {
        throw Exception('Saldo tidak mencukupi untuk melakukan penarikan.');
      }

      if (amount < 50000) {
        throw Exception('Minimal penarikan adalah Rp 50.000.');
      }

      // 2. Create the withdrawal request (status defaults to 'pending')
      final body = {
        'partner_id': partnerId,
        'amount': amount,
        'bank_name': bankName,
        'bank_account': bankAccount,
        'status': 'pending',
      };

      final record = await pb.collection('withdrawals').create(body: body);
      return WithdrawalModel.fromRecord(record);
    } catch (e) {
      throw NetworkException(message: 'Gagal mengajukan penarikan. Periksa koneksi internet.');
    }
  }

  /// Approve a withdrawal request (admin action)
  Future<WithdrawalModel> approveWithdrawal(String withdrawalId) async {
    try {
      final record = await pb.collection('withdrawals').update(
        withdrawalId,
        body: {'status': 'approved'},
      );
      return WithdrawalModel.fromRecord(record);
    } catch (e) {
      throw NetworkException(message: 'Gagal menyetujui penarikan. Periksa koneksi internet.');
    }
  }

  /// Reject a withdrawal request (admin action)
  Future<WithdrawalModel> rejectWithdrawal(String withdrawalId, String adminNote) async {
    try {
      final record = await pb.collection('withdrawals').update(
        withdrawalId,
        body: {
          'status': 'rejected',
          'admin_note': adminNote,
        },
      );
      return WithdrawalModel.fromRecord(record);
    } catch (e) {
      throw NetworkException(message: 'Gagal menolak penarikan. Periksa koneksi internet.');
    }
  }

  /// Mark withdrawal as transferred and deduct from partner balance (admin action)
  Future<WithdrawalModel> markAsTransferred(String withdrawalId) async {
    try {
      // 1. Get withdrawal details
      final withdrawalRecord = await pb.collection('withdrawals').getOne(withdrawalId);
      final partnerId = withdrawalRecord.getStringValue('partner_id');
      final amount = withdrawalRecord.getIntValue('amount');

      // 2. Get partner current balance
      final partnerRecord = await pb.collection('partners').getOne(partnerId);
      final currentBalance = partnerRecord.getIntValue('balance');

      // 3. Verify balance is sufficient
      if (currentBalance < amount) {
        throw ValidationException(message: 'Saldo mitra tidak mencukupi untuk transfer.');
      }

      // 4. Deduct from partner balance
      await pb.collection('partners').update(partnerId, body: {
        'balance': currentBalance - amount,
      });

      // 5. Update withdrawal status to transferred with timestamp
      final record = await pb.collection('withdrawals').update(
        withdrawalId,
        body: {
          'status': 'transferred',
          'transferred_at': DateTime.now().toIso8601String(),
        },
      );

      return WithdrawalModel.fromRecord(record);
    } on ValidationException {
      rethrow;
    } catch (e) {
      throw NetworkException(message: 'Gagal menandai transfer selesai. Periksa koneksi internet.');
    }
  }

  /// Get all pending withdrawals for admin
  Future<List<WithdrawalModel>> getPendingWithdrawals() async {
    try {
      final records = await pb.collection('withdrawals').getFullList(
        filter: 'status = "pending"',
        sort: '-created',
      );
      return records.items.map((r) => WithdrawalModel.fromRecord(r)).toList();
    } catch (e) {
      throw NetworkException(message: 'Gagal memuat penarikan pending. Periksa koneksi internet.');
    }
  }

  /// Get all approved withdrawals (ready for transfer) for admin
  Future<List<WithdrawalModel>> getApprovedWithdrawals() async {
    try {
      final records = await pb.collection('withdrawals').getFullList(
        filter: 'status = "approved"',
        sort: '-created',
      );
      return records.items.map((r) => WithdrawalModel.fromRecord(r)).toList();
    } catch (e) {
      throw NetworkException(message: 'Gagal memuat penarikan disetujui. Periksa koneksi internet.');
    }
  }
}
