import 'package:equatable/equatable.dart';
import 'package:pocketbase/pocketbase.dart';

class OrderItemModel extends Equatable {
  final String id;
  final String orderId;
  final String subcategoryId;
  final String name;
  final int price;
  final int quantity;
  final int subtotal;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.subcategoryId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItemModel.fromRecord(RecordModel record) {
    return OrderItemModel(
      id: record.id,
      orderId: record.getStringValue('order_id'),
      subcategoryId: record.getStringValue('subcategory_id'),
      name: record.getStringValue('name'),
      price: record.getIntValue('price'),
      quantity: record.getIntValue('quantity', 1),
      subtotal: record.getIntValue('subtotal'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'subcategory_id': subcategoryId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        subcategoryId,
        name,
        price,
        quantity,
        subtotal,
      ];
}
