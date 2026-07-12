import '../../core/pocketbase/pb.dart';
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
      throw Exception('Gagal memuat riwayat penarikan: $e');
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
      throw Exception('Gagal mengajukan penarikan: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}
