import 'package:pocketbase/pocketbase.dart';
import 'package:http/http.dart' as http;
import '../../core/pocketbase/pb.dart';
import '../../core/exceptions/app_exception.dart';
import '../models/partner_model.dart';

class PartnerRepository {
  /// Fetch a single partner's details by ID
  Future<PartnerModel> getPartner(String partnerId) async {
    try {
      final record = await pb.collection('partners').getOne(partnerId);
      return PartnerModel.fromRecord(record);
    } on ClientException catch (e) {
      if (e.statusCode == 404) {
        throw NotFoundException(message: 'Mitra tidak ditemukan.');
      }
      throw NetworkException(message: 'Gagal memuat profil mitra. Periksa koneksi internet.');
    } catch (e) {
      throw NetworkException(message: 'Gagal memuat profil mitra.');
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
    } on ClientException catch (e) {
      if (e.response['email'] != null) {
        throw ValidationException(message: 'Email sudah terdaftar sebagai mitra.');
      }
      if (e.response['phone'] != null) {
        throw ValidationException(message: 'No HP sudah terdaftar sebagai mitra.');
      }
      throw ValidationException(message: 'Gagal mendaftar sebagai mitra. Periksa data Anda.');
    } catch (e) {
      throw NetworkException(message: 'Gagal mendaftar sebagai mitra. Periksa koneksi internet.');
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
      throw NetworkException(message: 'Gagal memperbarui status online. Periksa koneksi internet.');
    }
  }

  /// Fetch available partners (online, verified, active) whose
  /// [partner_skills] cover all [subcategoryIds] from the order.
  /// Uses optimized filtering with PocketBase expand for better performance.
  Future<List<PartnerModel>> getAvailablePartners({
    List<String> subcategoryIds = const [],
  }) async {
    try {
      if (subcategoryIds.isEmpty) {
        // If no skill filter, return all online/verified/active partners
        final records = await pb.collection('partners').getFullList(
          filter: 'is_online = true && is_verified = true && is_active = true',
          sort: '-rating,-total_jobs',
        );
        return records.map((r) => PartnerModel.fromRecord(r)).toList();
      }

      // Build filter for partner_skills with all required subcategories
      // Using a more efficient approach: get partners who have at least one skill,
      // then filter for those who have ALL required skills
      final skillFilter = subcategoryIds
          .map((id) => 'subcategory_id = "$id"')
          .join(' || ');

      // Fetch partner_skills with expand to get partner details
      final skillRecords = await pb.collection('partner_skills').getFullList(
        filter: skillFilter,
        expand: 'partner_id',
      );

      // Group skills by partner and track their partner data
      final skillsByPartner = <String, Set<String>>{};
      final partnerDataMap = <String, RecordModel>{};
      
      for (final skill in skillRecords) {
        final partnerId = skill.getStringValue('partner_id');
        final subcategoryId = skill.getStringValue('subcategory_id');
        
        skillsByPartner
            .putIfAbsent(partnerId, () => {})
            .add(subcategoryId);
        
        // Cache partner data from expand
        final expandedPartner = skill.get<RecordModel?>('expand.partner_id');
        if (expandedPartner != null) {
          partnerDataMap[partnerId] = expandedPartner;
        }
      }

      // Filter partners who have ALL required skills AND are online/verified/active
      final requiredSkills = subcategoryIds.toSet();
      final eligiblePartners = <PartnerModel>[];
      
      for (final entry in skillsByPartner.entries) {
        final partnerId = entry.key;
        final partnerSkills = entry.value;
        
        // Check if partner has all required skills
        if (requiredSkills.every(partnerSkills.contains)) {
          // Get partner data from cache or fetch if not cached
          RecordModel? partnerRecord = partnerDataMap[partnerId];
          if (partnerRecord == null) {
            try {
              partnerRecord = await pb.collection('partners').getOne(partnerId);
            } catch (e) {
              continue; // Skip if partner not found
            }
          }
          
          // Check if partner is online, verified, and active
          if (partnerRecord.getBoolValue('is_online') == true &&
              partnerRecord.getBoolValue('is_verified') == true &&
              partnerRecord.getBoolValue('is_active') == true) {
            eligiblePartners.add(PartnerModel.fromRecord(partnerRecord));
          }
        }
      }

      // Sort by rating and total jobs
      eligiblePartners.sort((a, b) {
        if (a.rating != b.rating) {
          return b.rating.compareTo(a.rating);
        }
        return b.totalJobs.compareTo(a.totalJobs);
      });

      return eligiblePartners;
    } catch (e) {
      throw NetworkException(message: 'Gagal memuat mitra yang tersedia. Periksa koneksi internet.');
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
