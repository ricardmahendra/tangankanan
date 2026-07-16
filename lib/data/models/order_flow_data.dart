import 'package:equatable/equatable.dart';
import 'category_model.dart';
import 'subcategory_model.dart';
import 'partner_model.dart';

class OrderFlowData extends Equatable {
  final CategoryModel category;
  final List<SubcategorySelection> selectedItems;
  final String address;
  final String recipientName;
  final String recipientPhone;
  final String? addressId; // Optional: ID of saved address
  final DateTime? scheduledAt;
  final String notes;
  final PartnerModel? selectedPartner;

  const OrderFlowData({
    required this.category,
    this.selectedItems = const [],
    this.address = '',
    this.recipientName = '',
    this.recipientPhone = '',
    this.addressId,
    this.scheduledAt,
    this.notes = '',
    this.selectedPartner,
  });

  OrderFlowData copyWith({
    CategoryModel? category,
    List<SubcategorySelection>? selectedItems,
    String? address,
    String? recipientName,
    String? recipientPhone,
    String? addressId,
    DateTime? scheduledAt,
    String? notes,
    PartnerModel? selectedPartner,
  }) {
    return OrderFlowData(
      category: category ?? this.category,
      selectedItems: selectedItems ?? this.selectedItems,
      address: address ?? this.address,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      addressId: addressId ?? this.addressId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      notes: notes ?? this.notes,
      selectedPartner: selectedPartner ?? this.selectedPartner,
    );
  }

  int get totalPrice => selectedItems.fold(
      0, (total, item) => total + (item.subcategory.price * item.quantity));

  @override
  List<Object?> get props => [
        category,
        selectedItems,
        address,
        recipientName,
        recipientPhone,
        addressId,
        scheduledAt,
        notes,
        selectedPartner,
      ];
}

class SubcategorySelection extends Equatable {
  final SubcategoryModel subcategory;
  final int quantity;

  const SubcategorySelection({
    required this.subcategory,
    this.quantity = 1,
  });

  SubcategorySelection copyWith({
    SubcategoryModel? subcategory,
    int? quantity,
  }) {
    return SubcategorySelection(
      subcategory: subcategory ?? this.subcategory,
      quantity: quantity ?? this.quantity,
    );
  }

  int get subtotal => subcategory.price * quantity;

  @override
  List<Object?> get props => [subcategory, quantity];
}
