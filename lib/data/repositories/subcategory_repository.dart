import '../../core/pocketbase/pb.dart';
import '../models/subcategory_model.dart';

class SubcategoryRepository {
  /// Fetch all active subcategories for a given category
  Future<List<SubcategoryModel>> getSubcategories(String categoryId) async {
    try {
      final records = await pb.collection('subcategories').getFullList(
        filter: 'category_id = "$categoryId" && is_active = true',
        sort: 'order',
        expand: 'category_id',
      );
      return records.map((r) => SubcategoryModel.fromRecord(r)).toList();
    } catch (e) {
      throw Exception('Gagal memuat subkategori: $e');
    }
  }
}
