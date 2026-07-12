import 'package:equatable/equatable.dart';
import 'package:pocketbase/pocketbase.dart';

class CategoryModel extends Equatable {
  final String id;
  final String name;
  final bool isActive;
  final int order;

  const CategoryModel({
    required this.id,
    required this.name,
    this.isActive = true,
    this.order = 0,
  });

  factory CategoryModel.fromRecord(RecordModel record) {
    return CategoryModel(
      id: record.id,
      name: record.getStringValue('name'),
      isActive: record.getBoolValue('is_active', true),
      order: record.getIntValue('order'),
    );
  }

  @override
  List<Object?> get props => [id, name, isActive, order];
}
