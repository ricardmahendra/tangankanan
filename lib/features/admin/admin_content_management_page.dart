import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/pocketbase/pb.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';

class AdminContentManagementPage extends StatefulWidget {
  const AdminContentManagementPage({super.key});

  @override
  State<AdminContentManagementPage> createState() => _AdminContentManagementPageState();
}

class _AdminContentManagementPageState extends State<AdminContentManagementPage> {
  final _categoryRepo = CategoryRepository();
  bool _isLoading = true;
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _categoryRepo.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat kategori.'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _toggleCategoryStatus(String id, bool currentStatus) async {
    try {
      await pb.collection('categories').update(id, body: {'is_active': !currentStatus});
      _loadCategories();
    } catch (e) {
      debugPrint('Gagal update status kategori: $e');
    }
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final iconController = TextEditingController();
    final colorController = TextEditingController(text: '#1E40AF');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kategori'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama Kategori')),
            TextField(controller: iconController, decoration: const InputDecoration(labelText: 'Ikon (URL/Nama)')),
            TextField(controller: colorController, decoration: const InputDecoration(labelText: 'Warna (Hex)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await pb.collection('categories').create(body: {
                    'name': nameController.text,
                    'icon': iconController.text,
                    'color': colorController.text,
                    'is_active': true,
                    'order': _categories.length + 1,
                  });
                  if (mounted) Navigator.pop(ctx);
                  _loadCategories();
                } catch (e) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Gagal tambah kategori')));
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Konten'),
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const Center(child: Text('Belum ada kategori.'))
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryLight,
                            child: const Icon(Icons.category, color: AppColors.primary),
                          ),
                          title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Status: ${category.isActive ? "Aktif" : "Nonaktif"}'),
                          trailing: Switch(
                            value: category.isActive,
                            activeColor: AppColors.success,
                            onChanged: (val) => _toggleCategoryStatus(category.id, category.isActive),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
