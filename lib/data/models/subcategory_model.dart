import 'package:equatable/equatable.dart';
import 'package:pocketbase/pocketbase.dart';
import 'category_model.dart';

class SubcategoryModel extends Equatable {
  final String id;
  final String categoryId;
  final String name;
  final String description;
  final int price;
  final String priceUnit; // per sesi / per kg / per jam / per item / per unit / per m² / per pekerjaan / per titik
  final bool isActive;
  final int order;

  // Expanded field dari PocketBase
  final CategoryModel? category;

  const SubcategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description = '',
    required this.price,
    this.priceUnit = 'per sesi',
    this.isActive = true,
    this.order = 0,
    this.category,
  });

  factory SubcategoryModel.fromRecord(RecordModel record) {
    CategoryModel? expandedCategory;
    final categoryRecord = record.get<RecordModel?>('expand.category_id');
    if (categoryRecord != null) {
      expandedCategory = CategoryModel.fromRecord(categoryRecord);
    }

    final rawPriceUnit = record.getStringValue('price_unit');

    return SubcategoryModel(
      id: record.id,
      categoryId: record.getStringValue('category_id'),
      name: record.getStringValue('name'),
      description: record.getStringValue('description'),
      price: record.getIntValue('price'),
      priceUnit: rawPriceUnit.isEmpty ? 'per sesi' : rawPriceUnit,
      isActive: record.getBoolValue('is_active', true),
      order: record.getIntValue('order'),
      category: expandedCategory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'price_unit': priceUnit,
      'is_active': isActive,
      'order': order,
    };
  }

  /// Apakah unit harga ini membutuhkan quantity stepper?
  /// Sesuai PRD: per kg, per jam, per item → tampilkan stepper
  bool get hasQuantityStepper =>
      priceUnit == 'per kg' ||
      priceUnit == 'per jam' ||
      priceUnit == 'per item';

  @override
  List<Object?> get props => [
        id,
        categoryId,
        name,
        description,
        price,
        priceUnit,
        isActive,
        order,
        category,
      ];
}
