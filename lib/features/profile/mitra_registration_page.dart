import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/pocketbase/pb.dart';
import '../../data/models/category_model.dart';
import '../../data/models/subcategory_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/partner_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/subcategory_repository.dart';

class MitraRegistrationPage extends StatefulWidget {
  const MitraRegistrationPage({super.key});

  @override
  State<MitraRegistrationPage> createState() => _MitraRegistrationPageState();
}

class _MitraRegistrationPageState extends State<MitraRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _partnerRepo = PartnerRepository();
  final _categoryRepo = CategoryRepository();
  final _subcategoryRepo = SubcategoryRepository();
  final ImagePicker _picker = ImagePicker();

  UserModel? _user;
  
  final _nikController = TextEditingController();
  final _bioController = TextEditingController();
  
  Uint8List? _ktpBytes;
  String? _ktpName;
  
  Uint8List? _selfieBytes;
  String? _selfieName;

  bool _isAgreed = false;
  bool _isLoading = false;
  bool _isLoadingSkills = true;
  
  // Skills selection
  List<CategoryModel> _categories = [];
  Map<String, List<SubcategoryModel>> _subcategoriesByCategory = {};
  Set<String> _selectedSubcategoryIds = {};

  @override
  void initState() {
    super.initState();
    final record = pb.authStore.record;
    if (record != null) {
      _user = UserModel.fromRecord(record);
      // Pre-fill if NIK exists
      if (_user!.nik.isNotEmpty) {
        _nikController.text = _user!.nik;
      }
    }
    _loadSkills();
  }

  Future<void> _loadSkills() async {
    try {
      final categories = await _categoryRepo.getCategories();
      final Map<String, List<SubcategoryModel>> subcategoriesMap = {};
      
      for (final category in categories) {
        final subcategories = await _subcategoryRepo.getSubcategories(category.id);
        if (subcategories.isNotEmpty) {
          subcategoriesMap[category.id] = subcategories;
        }
      }
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _subcategoriesByCategory = subcategoriesMap;
          _isLoadingSkills = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSkills = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nikController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isKtp) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // compress to save upload size
    );
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        if (isKtp) {
          _ktpBytes = bytes;
          _ktpName = image.name;
        } else {
          _selfieBytes = bytes;
          _selfieName = image.name;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ktpBytes == null || _selfieBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto KTP dan Selfie wajib diunggah'), backgroundColor: AppColors.danger),
      );
      return;
    }
    if (_selectedSubcategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu keahlian'), backgroundColor: AppColors.danger),
      );
      return;
    }
    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus menyetujui syarat & ketentuan'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final defaultMitraPassword = 'mitra123456';

      await _partnerRepo.registerPartner(
        name: _user!.name,
        phone: _user!.phone,
        email: _user!.email,
        password: defaultMitraPassword,
        nik: _nikController.text,
        bio: _bioController.text,
        ktpPhotoName: _ktpName!,
        ktpPhotoBytes: _ktpBytes!,
        selfiePhotoName: _selfieName!,
        selfiePhotoBytes: _selfieBytes!,
        skillIds: _selectedSubcategoryIds.toList(),
      );

      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Pendaftaran Berhasil'),
            content: const Text(
              'Pendaftaran Anda sebagai Mitra telah berhasil disubmit dan sedang dalam proses verifikasi.\n\n'
              'Password default Mitra Anda: mitra123456\n(Silakan login dengan email Anda)'
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  context.pop(); // go back to profile
                },
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Scaffold(body: Center(child: Text('User tidak valid')));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Jadi Mitra'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lengkapi Data Diri',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Data Anda akan kami verifikasi untuk memastikan keamanan dan kenyamanan pengguna.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    
                    // NIK
                    TextFormField(
                      controller: _nikController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Induk Kependudukan (NIK)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'NIK tidak boleh kosong';
                        if (value.length != 16) return 'NIK harus 16 digit';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Bio
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Diri & Keahlian (Bio)',
                        border: OutlineInputBorder(),
                        hintText: 'Ceritakan pengalaman dan keahlian Anda...',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Bio tidak boleh kosong';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // KTP Upload
                    const Text(
                      'Foto KTP',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildImagePickerBox(
                      isKtp: true,
                      bytes: _ktpBytes,
                      onTap: () => _pickImage(true),
                    ),
                    const SizedBox(height: 16),

                    // Selfie Upload
                    const Text(
                      'Foto Selfie dengan KTP',
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _buildImagePickerBox(
                      isKtp: false,
                      bytes: _selfieBytes,
                      onTap: () => _pickImage(false),
                    ),

                    const SizedBox(height: 24),

                    // Skills Selection
                    const Text(
                      'Pilih Keahlian',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pilih layanan yang bisa Anda kerjakan (minimal 1)',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_isLoadingSkills)
                      const Center(child: CircularProgressIndicator())
                    else if (_subcategoriesByCategory.isEmpty)
                      const Text('Tidak ada keahlian tersedia')
                    else
                      ..._categories.map((category) {
                        final subcategories = _subcategoriesByCategory[category.id];
                        if (subcategories == null || subcategories.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                category.name,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: subcategories.map((sub) {
                                final isSelected = _selectedSubcategoryIds.contains(sub.id);
                                return FilterChip(
                                  label: Text(
                                    sub.name,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary,
                                  checkmarkColor: Colors.white,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedSubcategoryIds.add(sub.id);
                                      } else {
                                        _selectedSubcategoryIds.remove(sub.id);
                                      }
                                    });
                                  },
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: AppColors.border),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }).toList(),

                    const SizedBox(height: 24),

                    // Work Agreement
                    const Text(
                      'Perjanjian Kerja Mitra',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Syarat & Ketentuan:',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '1. Mitra wajib merespon pesanan dalam waktu maksimal 10 menit.\n'
                            '2. Mitra wajib tiba di lokasi dalam toleransi ±15 menit dari jadwal.\n'
                            '3. Mitra wajib menyelesaikan pekerjaan sesuai standar kualitas.\n'
                            '4. Mitra akan menerima 88% dari total harga layanan, 12% untuk platform.\n'
                            '5. Mitra dapat melakukan penarikan saldo minimal Rp 50.000.\n'
                            '6. Mitra yang mendapatkan rating rendah (< 3.0) dapat di-suspend.\n'
                            '7. Mitra wajib menjaga sikap profesional terhadap pengguna.\n'
                            '8. Pelanggaran berat dapat mengakibatkan penghapusan akun mitra.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Checkbox(
                                value: _isAgreed,
                                activeColor: AppColors.primary,
                                onChanged: (val) {
                                  setState(() => _isAgreed = val ?? false);
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  'Saya telah membaca dan menyetujui seluruh syarat & ketentuan di atas.',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Kirim Pendaftaran',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImagePickerBox({required bool isKtp, required Uint8List? bytes, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
        ),
        child: bytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(bytes, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    isKtp ? 'Ambil/Pilih Foto KTP' : 'Ambil/Pilih Foto Selfie',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
      ),
    );
  }
}
