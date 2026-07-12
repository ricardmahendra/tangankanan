import 'package:pocketbase/pocketbase.dart';

class AddressModel {
  final String id;
  final String userId;
  final String label;
  final String recipientName;
  final String recipientPhone;
  final String address;
  final String? notes;
  final bool isDefault;
  final DateTime created;
  final DateTime updated;

  AddressModel({
    required this.id,
    required this.userId,
    required this.label,
    required this.recipientName,
    required this.recipientPhone,
    required this.address,
    this.notes,
    required this.isDefault,
    required this.created,
    required this.updated,
  });

  factory AddressModel.fromRecord(RecordModel record) {
    return AddressModel(
      id: record.id,
      userId: record.getStringValue('user_id'),
      label: record.getStringValue('label'),
      recipientName: record.getStringValue('recipient_name'),
      recipientPhone: record.getStringValue('recipient_phone'),
      address: record.getStringValue('address'),
      notes: record.getStringValue('notes'),
      isDefault: record.getBoolValue('is_default'),
      created: record.created ?? DateTime.now(),
      updated: record.updated ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'label': label,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'address': address,
      'notes': notes,
      'is_default': isDefault,
    };
  }
}
