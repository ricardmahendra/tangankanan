import 'package:equatable/equatable.dart';
import 'package:pocketbase/pocketbase.dart';
import 'user_model.dart';
import 'partner_model.dart';
import 'order_item_model.dart';

class OrderModel extends Equatable {
  final String id;
  final String orderCode;
  final String userId;
  final String partnerId;
  final String categoryId;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime scheduledAt;
  final String notes;
  final int totalPrice;
  final int platformFee;
  final int partnerIncome;
  final String status; // pending, confirmed, on_the_way, arrived, in_progress, completed, cancelled
  final String paymentStatus; // unpaid, paid, refunded
  final String paymentMethod;
  final String midtransToken;
  final String cancelledBy; // user, partner, admin
  final String cancelReason;
  final DateTime? completedAt;
  final DateTime? created;
  final DateTime? updated;

  // Expanded fields from PocketBase `expand`
  final UserModel? user;
  final PartnerModel? partner;
  final List<OrderItemModel>? items;

  const OrderModel({
    required this.id,
    required this.orderCode,
    required this.userId,
    this.partnerId = '',
    required this.categoryId,
    required this.address,
    this.latitude = 0.0,
    this.longitude = 0.0,
    required this.scheduledAt,
    this.notes = '',
    required this.totalPrice,
    required this.platformFee,
    required this.partnerIncome,
    this.status = 'pending',
    this.paymentStatus = 'unpaid',
    this.paymentMethod = '',
    this.midtransToken = '',
    this.cancelledBy = '',
    this.cancelReason = '',
    this.completedAt,
    this.created,
    this.updated,
    this.user,
    this.partner,
    this.items,
  });

  factory OrderModel.fromRecord(RecordModel record) {
    // Check for expands
    UserModel? expandedUser;
    final userRecord = record.expand['user_id']?.firstOrNull;
    if (userRecord != null) {
      expandedUser = UserModel.fromRecord(userRecord);
    }

    PartnerModel? expandedPartner;
    final partnerRecord = record.expand['partner_id']?.firstOrNull;
    if (partnerRecord != null) {
      expandedPartner = PartnerModel.fromRecord(partnerRecord);
    }

    List<OrderItemModel>? expandedItems;
    final itemsRecords = record.expand['order_items(order_id)'];
    if (itemsRecords != null) {
      expandedItems = itemsRecords.map((r) => OrderItemModel.fromRecord(r)).toList();
    }

    return OrderModel(
      id: record.id,
      orderCode: record.getStringValue('order_code'),
      userId: record.getStringValue('user_id'),
      partnerId: record.getStringValue('partner_id'),
      categoryId: record.getStringValue('category_id'),
      address: record.getStringValue('address'),
      latitude: record.getDoubleValue('latitude'),
      longitude: record.getDoubleValue('longitude'),
      scheduledAt: DateTime.tryParse(record.getStringValue('scheduled_at')) ?? DateTime.now(),
      notes: record.getStringValue('notes'),
      totalPrice: record.getIntValue('total_price'),
      platformFee: record.getIntValue('platform_fee'),
      partnerIncome: record.getIntValue('partner_income'),
      status: record.getStringValue('status', 'pending'),
      paymentStatus: record.getStringValue('payment_status', 'unpaid'),
      paymentMethod: record.getStringValue('payment_method'),
      midtransToken: record.getStringValue('midtrans_token'),
      cancelledBy: record.getStringValue('cancelled_by'),
      cancelReason: record.getStringValue('cancel_reason'),
      completedAt: DateTime.tryParse(record.getStringValue('completed_at')),
      created: DateTime.tryParse(record.created),
      updated: DateTime.tryParse(record.updated),
      user: expandedUser,
      partner: expandedPartner,
      items: expandedItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_code': orderCode,
      'user_id': userId,
      'partner_id': partnerId.isEmpty ? null : partnerId,
      'category_id': categoryId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'scheduled_at': scheduledAt.toIso8601String(),
      'notes': notes,
      'total_price': totalPrice,
      'platform_fee': platformFee,
      'partner_income': partnerIncome,
      'status': status,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'midtrans_token': midtransToken,
      'cancelled_by': cancelledBy,
      'cancel_reason': cancelReason,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        orderCode,
        userId,
        partnerId,
        categoryId,
        address,
        latitude,
        longitude,
        scheduledAt,
        notes,
        totalPrice,
        platformFee,
        partnerIncome,
        status,
        paymentStatus,
        paymentMethod,
        midtransToken,
        cancelledBy,
        cancelReason,
        completedAt,
        created,
        updated,
        user,
        partner,
        items,
      ];
}
