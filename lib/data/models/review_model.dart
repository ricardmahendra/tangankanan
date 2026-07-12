import 'package:equatable/equatable.dart';
import 'package:pocketbase/pocketbase.dart';
import 'user_model.dart';
import 'partner_model.dart';

class ReviewModel extends Equatable {
  final String id;
  final String orderId;
  final String userId;
  final String partnerId;
  final int rating; // 1–5 stars
  final String comment;
  final DateTime? created;
  final DateTime? updated;

  // Expanded fields dari PocketBase
  final UserModel? user;
  final PartnerModel? partner;

  const ReviewModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.partnerId,
    required this.rating,
    this.comment = '',
    this.created,
    this.updated,
    this.user,
    this.partner,
  });

  factory ReviewModel.fromRecord(RecordModel record) {
    UserModel? expandedUser;
    final userRecord = record.get<RecordModel?>('expand.user_id');
    if (userRecord != null) {
      expandedUser = UserModel.fromRecord(userRecord);
    }

    PartnerModel? expandedPartner;
    final partnerRecord = record.get<RecordModel?>('expand.partner_id');
    if (partnerRecord != null) {
      expandedPartner = PartnerModel.fromRecord(partnerRecord);
    }

    return ReviewModel(
      id: record.id,
      orderId: record.getStringValue('order_id'),
      userId: record.getStringValue('user_id'),
      partnerId: record.getStringValue('partner_id'),
      rating: record.getIntValue('rating'),
      comment: record.getStringValue('comment'),
      created: DateTime.tryParse(record.get<String>('created')),
      updated: DateTime.tryParse(record.get<String>('updated')),
      user: expandedUser,
      partner: expandedPartner,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'user_id': userId,
      'partner_id': partnerId,
      'rating': rating,
      'comment': comment,
    };
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        userId,
        partnerId,
        rating,
        comment,
        created,
        updated,
        user,
        partner,
      ];
}
