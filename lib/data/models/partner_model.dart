import 'package:equatable/equatable.dart';
import 'package:pocketbase/pocketbase.dart';

class PartnerModel extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String nik;
  final String ktpPhoto;
  final String selfiePhoto;
  final String avatar;
  final String bio;
  final bool isOnline;
  final bool isVerified;
  final bool isActive;
  final double rating;
  final int totalJobs;
  final int balance;
  final String bankName;
  final String bankAccount;
  final bool workAgreementSigned;
  final String role;
  final DateTime? created;
  final DateTime? updated;

  const PartnerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.nik = '',
    this.ktpPhoto = '',
    this.selfiePhoto = '',
    this.avatar = '',
    this.bio = '',
    this.isOnline = false,
    this.isVerified = false,
    this.isActive = true,
    this.rating = 0.0,
    this.totalJobs = 0,
    this.balance = 0,
    this.bankName = '',
    this.bankAccount = '',
    this.workAgreementSigned = false,
    this.role = 'mitra',
    this.created,
    this.updated,
  });

  factory PartnerModel.fromRecord(RecordModel record) {
    return PartnerModel(
      id: record.id,
      name: record.getStringValue('name'),
      phone: record.getStringValue('phone'),
      nik: record.getStringValue('nik'),
      ktpPhoto: record.getStringValue('ktp_photo'),
      selfiePhoto: record.getStringValue('selfie_photo'),
      avatar: record.getStringValue('avatar'),
      bio: record.getStringValue('bio'),
      isOnline: record.getBoolValue('is_online'),
      isVerified: record.getBoolValue('is_verified'),
      isActive: record.getBoolValue('is_active'),
      rating: record.getDoubleValue('rating'),
      totalJobs: record.getIntValue('total_jobs'),
      balance: record.getIntValue('balance'),
      bankName: record.getStringValue('bank_name'),
      bankAccount: record.getStringValue('bank_account'),
      workAgreementSigned: record.getBoolValue('work_agreement_signed'),
      role: record.getStringValue('role', 'mitra'),
      created: DateTime.tryParse(record.created),
      updated: DateTime.tryParse(record.updated),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'nik': nik,
      'bio': bio,
      'is_online': isOnline,
      'is_verified': isVerified,
      'is_active': isActive,
      'rating': rating,
      'total_jobs': totalJobs,
      'balance': balance,
      'bank_name': bankName,
      'bank_account': bankAccount,
      'work_agreement_signed': workAgreementSigned,
      'role': role,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        nik,
        ktpPhoto,
        selfiePhoto,
        avatar,
        bio,
        isOnline,
        isVerified,
        isActive,
        rating,
        totalJobs,
        balance,
        bankName,
        bankAccount,
        workAgreementSigned,
        role,
        created,
        updated,
      ];
}
