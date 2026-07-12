import '../../core/pocketbase/pb.dart';
import '../models/review_model.dart';

class ReviewRepository {
  /// Check if a review already exists for an order (1 review per order).
  Future<ReviewModel?> getReviewByOrderId(String orderId) async {
    try {
      final records = await pb.collection('reviews').getList(
        page: 1,
        perPage: 1,
        filter: 'order_id = "$orderId"',
        expand: 'user_id,partner_id',
      );

      if (records.items.isNotEmpty) {
        return ReviewModel.fromRecord(records.items.first);
      }
      return null;
    } catch (e) {
      throw Exception('Gagal memuat ulasan: $e');
    }
  }

  /// Submit a new review and recalculate partner rating.
  Future<ReviewModel> submitReview({
    required String orderId,
    required String userId,
    required String partnerId,
    required int rating,
    String comment = '',
  }) async {
    try {
      final existing = await getReviewByOrderId(orderId);
      if (existing != null) {
        throw Exception('Pesanan ini sudah memiliki ulasan.');
      }

      if (rating < 1 || rating > 5) {
        throw Exception('Rating harus antara 1 dan 5 bintang.');
      }

      final record = await pb.collection('reviews').create(
        body: {
          'order_id': orderId,
          'user_id': userId,
          'partner_id': partnerId,
          'rating': rating,
          'comment': comment.trim(),
        },
      );

      await updatePartnerRating(partnerId);

      return ReviewModel.fromRecord(record);
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      if (message.startsWith('Gagal')) rethrow;
      throw Exception('Gagal mengirim ulasan: $message');
    }
  }

  /// Recalculate partner rating as the average of all their reviews.
  Future<void> updatePartnerRating(String partnerId) async {
    try {
      final reviews = await pb.collection('reviews').getFullList(
        filter: 'partner_id = "$partnerId"',
      );

      if (reviews.isEmpty) return;

      final total = reviews.fold<int>(
        0,
        (sum, record) => sum + record.getIntValue('rating'),
      );
      final average = total / reviews.length;

      await pb.collection('partners').update(partnerId, body: {
        'rating': double.parse(average.toStringAsFixed(1)),
      });
    } catch (e) {
      // Review was saved; rating sync failure should not block the user flow.
    }
  }
}
