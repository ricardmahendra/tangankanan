import 'package:equatable/equatable.dart';
import 'package:pocketbase/pocketbase.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String nik;
  final String ktpPhoto;
  final String address;
  final String avatar;
  final bool isActive;
  final String role;
  final DateTime? created;
  final DateTime? updated;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.nik = '',
    this.ktpPhoto = '',
    this.address = '',
    this.avatar = '',
    this.isActive = true,
    this.role = 'user',
    this.created,
    this.updated,
  });

  factory UserModel.fromRecord(RecordModel record) {
    return UserModel(
      id: record.id,
      name: record.getStringValue('name'),
      email: record.getStringValue('email'),
      phone: record.getStringValue('phone'),
      nik: record.getStringValue('nik'),
      ktpPhoto: record.getStringValue('ktp_photo'),
      address: record.getStringValue('address'),
      avatar: record.getStringValue('avatar'),
      isActive: record.getBoolValue('is_active'),
      role: record.getStringValue('role'),
      created: DateTime.tryParse(record.get<String>('created')),
      updated: DateTime.tryParse(record.get<String>('updated')),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'nik': nik,
      'address': address,
      'is_active': isActive,
      'role': role,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        nik,
        ktpPhoto,
        address,
        avatar,
        isActive,
        role,
        created,
        updated,
      ];
}
