import 'package:equatable/equatable.dart';
import 'package:pocketbase/pocketbase.dart';

class ChatModel extends Equatable {
  final String id;
  final String orderId;
  final String senderId; // bisa user_id atau partner_id
  final String senderType; // 'user' atau 'partner'
  final String message;
  final bool isRead;
  final DateTime? created;
  final DateTime? updated;

  const ChatModel({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderType,
    required this.message,
    this.isRead = false,
    this.created,
    this.updated,
  });

  factory ChatModel.fromRecord(RecordModel record) {
    return ChatModel(
      id: record.id,
      orderId: record.getStringValue('order_id'),
      senderId: record.getStringValue('sender_id'),
      senderType: record.getStringValue('sender_type'),
      message: record.getStringValue('message'),
      isRead: record.getBoolValue('is_read'),
      created: DateTime.tryParse(record.get<String>('created')),
      updated: DateTime.tryParse(record.get<String>('updated')),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'sender_id': senderId,
      'sender_type': senderType,
      'message': message,
      'is_read': isRead,
    };
  }

  /// Apakah pesan ini dikirim oleh user (bukan mitra)?
  bool get isFromUser => senderType == 'user';

  /// Apakah pesan ini dikirim oleh mitra?
  bool get isFromMitra => senderType == 'partner';

  /// Salin dengan nilai baru (untuk mark as read, dsb.)
  ChatModel copyWith({
    String? id,
    String? orderId,
    String? senderId,
    String? senderType,
    String? message,
    bool? isRead,
    DateTime? created,
    DateTime? updated,
  }) {
    return ChatModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        senderId,
        senderType,
        message,
        isRead,
        created,
        updated,
      ];
}
