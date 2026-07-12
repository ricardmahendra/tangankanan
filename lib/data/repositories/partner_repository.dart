import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import '../../core/pocketbase/pb.dart';
import '../models/partner_model.dart';

class PartnerRepository {
  /// Fetch a single partner's details by ID
  Future<PartnerModel> getPartner(String partnerId) async {
    try {
      final record = await pb.collection('partners').getOne(partnerId);
      return PartnerModel.fromRecord(record);
    } catch (e) {
      throw Exception('Gagal memuat profil mitra: $e');
    }
  }

  /// Check if a user is already registered as a partner (via NIK or phone)
  Future<PartnerModel?> checkPartnerExists(String nik) async {
    try {
      final records = await pb.collection('partners').getList(
        page: 1,
        perPage: 1,
        filter: 'nik = "$nik"',
      );
      
      if (records.items.isNotEmpty) {
        return PartnerModel.fromRecord(records.items.first);
      }
      return null;
    } catch (e) {
      // If error occurs, assume not registered to avoid blocking
      return null;
    }
  }

  /// Register a user as a new Partner
  Future<PartnerModel> registerPartner({
    required String name,
    required String phone,
    required String email,
    required String password, // We will use the same password as the user account
    required String nik,
    required String bio,
    required String ktpPhotoName,
    required List<int> ktpPhotoBytes,
    required String selfiePhotoName,
    required List<int> selfiePhotoBytes,
    required List<String> skillIds,
  }) async {
    try {
      final body = {
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'nik': nik,
        'bio': bio,
        'is_online': false,
        'is_verified': false,
        'is_active': true,
        'role': 'mitra',
      };

      final record = await pb.collection('partners').create(
        body: body,
        files: [
          http.MultipartFile.fromBytes(
            'ktp_photo',
            ktpPhotoBytes,
            filename: ktpPhotoName,
          ),
          http.MultipartFile.fromBytes(
            'selfie_photo',
            selfiePhotoBytes,
            filename: selfiePhotoName,
          ),
        ],
      );

      // Create partner_skills records
      for (final skillId in skillIds) {
        await pb.collection('partner_skills').create(body: {
          'partner_id': record.id,
          'subcategory_id': skillId,
        });
      }

      return PartnerModel.fromRecord(record);
    } catch (e) {
      throw Exception('Gagal mendaftar sebagai mitra: $e');
    }
  }

  /// Toggle online/offline status for a partner
  Future<PartnerModel> updateOnlineStatus(String partnerId, bool isOnline) async {
    try {
      final record = await pb.collection('partners').update(
        partnerId,
        body: {'is_online': isOnline},
      );
      return PartnerModel.fromRecord(record);
    } catch (e) {
      throw Exception('Gagal memperbarui status online: $e');
    }
  }

  /// Fetch all available partners (online, verified, and active)
  Future<List<PartnerModel>> getAvailablePartners() async {
    try {
      final records = await pb.collection('partners').getFullList(
        filter: 'is_online = true && is_verified = true && is_active = true',
      );
      return records.map((r) => PartnerModel.fromRecord(r)).toList();
    } catch (e) {
      throw Exception('Gagal memuat mitra yang tersedia: $e');
    }
  }

  /// Get current logged in partner model if authenticated
  PartnerModel? getCurrentPartner() {
    final record = pb.authStore.record;
    if (record is RecordModel && record.collectionName == 'partners') {
      return PartnerModel.fromRecord(record);
    }
    return null;
  }
}
