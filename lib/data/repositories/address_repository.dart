import '../../core/pocketbase/pb.dart';
import '../models/address_model.dart';

class AddressRepository {
  /// Fetch all addresses for a user
  Future<List<AddressModel>> getAddresses(String userId) async {
    try {
      final records = await pb.collection('addresses').getFullList(
        filter: 'user_id = "$userId"',
        sort: '-is_default,-created',
      );
      return records.map((r) => AddressModel.fromRecord(r)).toList();
    } catch (e) {
      throw Exception('Gagal memuat alamat: $e');
    }
  }

  /// Create a new address
  Future<AddressModel> createAddress(AddressModel address) async {
    try {
      // If this is set as default, unset other default addresses
      if (address.isDefault) {
        await _unsetDefaultAddress(address.userId);
      }

      final record = await pb.collection('addresses').create(body: address.toJson());
      return AddressModel.fromRecord(record);
    } catch (e) {
      throw Exception('Gagal menambah alamat: $e');
    }
  }

  /// Update an existing address
  Future<AddressModel> updateAddress(String addressId, AddressModel address) async {
    try {
      // If this is set as default, unset other default addresses
      if (address.isDefault) {
        await _unsetDefaultAddress(address.userId);
      }

      final record = await pb.collection('addresses').update(
        addressId,
        body: address.toJson(),
      );
      return AddressModel.fromRecord(record);
    } catch (e) {
      throw Exception('Gagal memperbarui alamat: $e');
    }
  }

  /// Delete an address
  Future<void> deleteAddress(String addressId) async {
    try {
      await pb.collection('addresses').delete(addressId);
    } catch (e) {
      throw Exception('Gagal menghapus alamat: $e');
    }
  }

  /// Set an address as default
  Future<AddressModel> setAsDefault(String addressId, String userId) async {
    try {
      await _unsetDefaultAddress(userId);
      
      final record = await pb.collection('addresses').update(
        addressId,
        body: {'is_default': true},
      );
      return AddressModel.fromRecord(record);
    } catch (e) {
      throw Exception('Gagal mengatur alamat default: $e');
    }
  }

  /// Unset default address for a user
  Future<void> _unsetDefaultAddress(String userId) async {
    try {
      final records = await pb.collection('addresses').getFullList(
        filter: 'user_id = "$userId" && is_default = true',
      );
      
      for (final record in records) {
        await pb.collection('addresses').update(
          record.id,
          body: {'is_default': false},
        );
      }
    } catch (e) {
      // Ignore errors for unsetting default
      print('Warning: Failed to unset default address: $e');
    }
  }

  /// Get default address for a user
  Future<AddressModel?> getDefaultAddress(String userId) async {
    try {
      final records = await pb.collection('addresses').getFullList(
        filter: 'user_id = "$userId" && is_default = true',
      );
      
      if (records.isNotEmpty) {
        return AddressModel.fromRecord(records.first);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
