import '../../core/pocketbase/pb.dart';
import '../models/category_model.dart';

class CategoryRepository {
  /// Fetch all active categories sorted by order
  Future<List<CategoryModel>> getCategories() async {
    try {
      final records = await pb.collection('categories').getFullList(
        filter: 'is_active = true',
        sort: 'order',
      );
      return records.map((r) => CategoryModel.fromRecord(r)).toList();
    } catch (e) {
      throw Exception('Gagal memuat kategori: $e');
    }
  }
}
