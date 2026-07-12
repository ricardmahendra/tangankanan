import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import '../../core/pocketbase/pb.dart';
import '../models/user_model.dart';

class AuthRepository {
  /// Login via Email or Phone with Password
  Future<UserModel> login(String identity, String password) async {
    try {
      final authRecord = await pb.collection('users').authWithPassword(identity, password);
      return UserModel.fromRecord(authRecord.record!);
    } on ClientException catch (e) {
      throw Exception('Gagal login. Periksa kembali kredensial Anda. (${e.statusCode})');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Register new User
  /// Web-compatible: Uses bytes instead of file path to ensure it works in browser testing.
  Future<UserModel> registerUser({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String nik,
    required String address,
    required String ktpPhotoName,
    required List<int> ktpPhotoBytes,
  }) async {
    try {
      final body = {
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'nik': nik,
        'address': address,
        'emailVisibility': true,
        'role': 'user',
        'is_active': true,
      };

      final record = await pb.collection('users').create(
        body: body,
        files: [
          http.MultipartFile.fromBytes(
            'ktp_photo',
            ktpPhotoBytes,
            filename: ktpPhotoName,
          ),
        ],
      );

      // Auto-login after successful registration
      await login(email, password);
      
      return UserModel.fromRecord(record);
    } catch (e) {
      throw Exception('Gagal mendaftar: $e');
    }
  }

  /// Logout
  void logout() {
    pb.authStore.clear();
  }

  /// Get current user profile from local store
  UserModel? getCurrentUser() {
    final record = pb.authStore.model;
    if (record is RecordModel) {
      return UserModel.fromRecord(record);
    }
    return null;
  }
}
