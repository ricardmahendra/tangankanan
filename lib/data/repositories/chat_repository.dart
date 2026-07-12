import 'package:pocketbase/pocketbase.dart';
import '../../core/pocketbase/pb.dart';
import '../models/chat_model.dart';

class ChatRepository {
  /// Fetch all chat messages for a specific order
  Future<List<ChatModel>> getMessages(String orderId) async {
    try {
      final records = await pb.collection('chats').getFullList(
        filter: 'order_id = "$orderId"',
        sort: 'created',
      );
      return records.map((r) => ChatModel.fromRecord(r)).toList();
    } catch (e) {
      throw Exception('Gagal memuat pesan: $e');
    }
  }

  /// Send a new message
  Future<ChatModel> sendMessage({
    required String orderId,
    required String senderId,
    required String senderType, // 'user' or 'partner'
    required String message,
  }) async {
    try {
      final record = await pb.collection('chats').create(
        body: {
          'order_id': orderId,
          'sender_id': senderId,
          'sender_type': senderType,
          'message': message,
          'is_read': false,
        },
      );
      return ChatModel.fromRecord(record);
    } catch (e) {
      throw Exception('Gagal mengirim pesan: $e');
    }
  }

  /// Subscribe to real-time chat updates
  Future<void> subscribeToChat(String orderId, Function(RecordSubscriptionEvent) onEvent) async {
    try {
      await pb.collection('chats').subscribe('*', (e) {
        if (e.record != null && e.record!.getStringValue('order_id') == orderId) {
          onEvent(e);
        }
      });
    } catch (e) {
      print('Gagal subscribe chat: $e');
    }
  }

  /// Unsubscribe from chat updates
  Future<void> unsubscribeFromChat() async {
    try {
      await pb.collection('chats').unsubscribe('*');
    } catch (e) {
      print('Gagal unsubscribe chat: $e');
    }
  }
}
