import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/pocketbase/pb.dart';
import '../../data/models/chat_model.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/order_repository.dart';

class ChatPage extends StatefulWidget {
  final String orderId;

  const ChatPage({
    super.key,
    required this.orderId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatRepository _chatRepo = ChatRepository();
  final OrderRepository _orderRepo = OrderRepository();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatModel> _messages = [];
  OrderModel? _order;
  bool _isLoading = true;
  String _currentUserId = '';
  String _currentUserRole = 'user'; // 'user' or 'mitra'

  @override
  void initState() {
    super.initState();
    _currentUserId = pb.authStore.record?.id ?? '';
    _currentUserRole = pb.authStore.record?.collectionName == 'partners' ? 'mitra' : 'user';
    
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final order = await _orderRepo.getOrderDetail(widget.orderId);
      final messages = await _chatRepo.getMessages(widget.orderId);
      
      if (mounted) {
        setState(() {
          _order = order;
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }

      // Subscribe to real-time updates
      _chatRepo.subscribeToChat(widget.orderId, (e) {
        if (e.action == 'create' && e.record != null && mounted) {
          final newMsg = ChatModel.fromRecord(e.record!);
          // Add if not already in list (prevent duplication from own send)
          if (!_messages.any((m) => m.id == newMsg.id)) {
            setState(() {
              _messages.add(newMsg);
            });
            _scrollToBottom();
          }
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  void dispose() {
    _chatRepo.unsubscribeFromChat();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      final newMsg = await _chatRepo.sendMessage(
        orderId: widget.orderId,
        senderId: _currentUserId,
        senderType: _currentUserRole,
        message: text,
      );

      // Realtime subscription will also catch this, but we can add optimistically
      if (!_messages.any((m) => m.id == newMsg.id)) {
        setState(() {
          _messages.add(newMsg);
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine chat title
    String title = 'Chat';
    if (_order != null) {
      if (_currentUserRole == 'user' && _order!.partner != null) {
        title = _order!.partner!.name;
      } else if (_currentUserRole == 'mitra' && _order!.user != null) {
        title = _order!.user!.name;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_order != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                // Return to order details
                context.pop();
              },
            )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Order context bar
                if (_order != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pesanan: ${_order!.orderCode}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _order!.status.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Chat List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg.senderId == _currentUserId;

                      return _buildMessageBubble(msg, isMe);
                    },
                  ),
                ),
                
                // Input Area
                _buildInputArea(),
              ],
            ),
    );
  }

  Widget _buildMessageBubble(ChatModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.message,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: isMe ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                DateFormat('HH:mm').format(msg.created ?? DateTime.now()),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: isMe ? Colors.white70 : AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ketik pesan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
