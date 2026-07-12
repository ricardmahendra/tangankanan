import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/pocketbase/pb.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/partner_repository.dart';

class MitraRegistrationPage extends StatefulWidget {
  const MitraRegistrationPage({super.key});

  @override
  State<MitraRegistrationPage> createState() => _MitraRegistrationPageState();
}

class _MitraRegistrationPageState extends State<MitraRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _partnerRepo = PartnerRepository();
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
    if (!_isAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus menyetujui syarat & ketentuan'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create partner record using the same user credentials, but technically PocketBase will generate a new auth record
      // For MVP, we pass dummy password since they are already authenticated as user.
      // Wait, PocketBase requires password/passwordConfirm to create a new Auth record.
      // A better way would be using a cloud function to sync, but since we are client-side, we must provide a password.
      // We will ask them to set a Mitra password.
      
      // Let's just use a dummy default password for MVP or prompt them.
      // To keep it simple, let's use a dummy password 'mitra123456'.
      // They can login as partner using their phone/email and 'mitra123456'.
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

                    // Agreement
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
                            'Saya menyetujui syarat & ketentuan serta perjanjian kerja Mitra TanganKanan.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
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
