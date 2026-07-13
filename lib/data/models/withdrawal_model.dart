import 'package:equatable/equatable.dart';
import 'package:pocketbase/pocketbase.dart';

class WithdrawalModel extends Equatable {
  final String id;
  final String partnerId;
  final String mitraName;
  final int amount;
  final String bankName;
  final String bankAccount;
  final String status; // pending, approved, rejected, transferred
  final String adminNote;
  final String note;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final DateTime? transferredAt;
  final DateTime? created;
  final DateTime? updated;

  const WithdrawalModel({
    required this.id,
    required this.partnerId,
    this.mitraName = '',
    required this.amount,
    required this.bankName,
    required this.bankAccount,
    this.status = 'pending',
    this.adminNote = '',
    this.note = '',
    required this.requestedAt,
    this.processedAt,
    this.transferredAt,
    this.created,
    this.updated,
  });

  factory WithdrawalModel.fromRecord(RecordModel record) {
    // Get mitra name from expanded relation
    String mitraName = '';
    final expanded = record.toJson()['expand'] as Map?;
    if (expanded != null && expanded.containsKey('mitra_id')) {
      final mitraData = expanded['mitra_id'] as Map?;
      if (mitraData != null) {
        mitraName = mitraData['name'] ?? '';
      }
    }

    return WithdrawalModel(
      id: record.id,
      partnerId: record.getStringValue('mitra_id'),
      mitraName: mitraName,
      amount: record.getIntValue('amount'),
      bankName: record.getStringValue('bank_name'),
      bankAccount: record.getStringValue('bank_account'),
      status: record.getStringValue('status', 'pending'),
      adminNote: record.getStringValue('admin_note'),
      note: record.getStringValue('note'),
      requestedAt: DateTime.tryParse(record.created) ?? DateTime.now(),
      processedAt: DateTime.tryParse(record.getStringValue('processed_at')),
      transferredAt: DateTime.tryParse(record.getStringValue('transferred_at')),
      created: DateTime.tryParse(record.created),
      updated: DateTime.tryParse(record.updated),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partner_id': partnerId,
      'amount': amount,
      'bank_name': bankName,
      'bank_account': bankAccount,
      'status': status,
      'admin_note': adminNote,
      'transferred_at': transferredAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        partnerId,
        amount,
        bankName,
        bankAccount,
        status,
        adminNote,
        transferredAt,
        created,
        updated,
      ];
}
