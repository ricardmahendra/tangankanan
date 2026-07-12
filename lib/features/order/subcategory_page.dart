import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/category_model.dart';
import '../../data/models/subcategory_model.dart';
import '../../data/models/order_flow_data.dart';
import '../../data/repositories/subcategory_repository.dart';
import 'package:shimmer/shimmer.dart';

class SubcategoryPage extends StatefulWidget {
  final String categoryId;
  final CategoryModel? category;

  const SubcategoryPage({
    super.key,
    required this.categoryId,
    this.category,
  });

  @override
  State<SubcategoryPage> createState() => _SubcategoryPageState();
}

class _SubcategoryPageState extends State<SubcategoryPage> {
  final SubcategoryRepository _repo = SubcategoryRepository();
  bool _isLoading = true;
  String _error = '';
  List<SubcategoryModel> _subcategories = [];
  
  // Track selected subcategories and their quantities
  final Map<String, SubcategorySelection> _selections = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });
      final data = await _repo.getSubcategories(widget.categoryId);
      setState(() {
        _subcategories = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(SubcategoryModel item, bool? isSelected) {
    setState(() {
      if (isSelected == true) {
        _selections[item.id] = SubcategorySelection(subcategory: item);
      } else {
        _selections.remove(item.id);
      }
    });
  }

  void _updateQuantity(SubcategoryModel item, int newQuantity) {
    if (newQuantity < 1) return;
    if (_selections.containsKey(item.id)) {
      setState(() {
        _selections[item.id] = _selections[item.id]!.copyWith(quantity: newQuantity);
      });
    }
  }

  int get _totalPrice {
    return _selections.values.fold(0, (total, sel) => total + sel.subtotal);
  }

  void _onProceed() {
    if (_selections.isEmpty) return;
    
    // Create initial flow data
    final flowData = OrderFlowData(
      category: widget.category ?? CategoryModel(id: widget.categoryId, name: 'Layanan'), // Fallback if extra not provided
      selectedItems: _selections.values.toList(),
    );

    context.push('/order/${widget.categoryId}/detail', extra: flowData);
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.category?.name ?? 'Pilih Layanan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(currencyFormat),
      bottomNavigationBar: _buildBottomBar(currencyFormat),
    );
  }

  Widget _buildBody(NumberFormat format) {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(_error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_subcategories.isEmpty) {
      return const Center(
        child: Text('Tidak ada layanan tersedia untuk kategori ini.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subcategories.length,
      itemBuilder: (context, index) {
        final item = _subcategories[index];
        final isSelected = _selections.containsKey(item.id);
        final selection = _selections[item.id];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: isSelected,
                      activeColor: AppColors.primary,
                      onChanged: (val) => _toggleSelection(item, val),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '${format.format(item.price)} ${item.priceUnit}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryMid,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isSelected && item.hasQuantityStepper) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kuantitas (${item.priceUnit.replaceAll('per ', '')})',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppColors.primary,
                            onPressed: () => _updateQuantity(item, (selection?.quantity ?? 1) - 1),
                          ),
                          Text(
                            '${selection?.quantity ?? 1}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppColors.primary,
                            onPressed: () => _updateQuantity(item, (selection?.quantity ?? 1) + 1),
                          ),
                        ],
                      )
                    ],
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(NumberFormat format) {
    final bool hasSelection = _selections.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Estimasi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  format.format(_totalPrice),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: hasSelection ? _onProceed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Lanjut',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
