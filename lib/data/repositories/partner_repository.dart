import 'package:pocketbase/pocketbase.dart';
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
