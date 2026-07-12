class AppConstants {
  // PocketBase
  static const String pocketBaseUrl = 'http://192.168.110.153:8090';
  
  // Business Rules
  static const double platformFeePercentage = 0.12; // 12%
  static const double partnerIncomePercentage = 0.88; // 88%
  static const int minWithdrawAmount = 50000; // Rp 50.000
  static const int mitraResponseTimeoutMinutes = 10;
  static const int mitraArrivalToleranceMinutes = 15;
  static const int maxWithdrawProcessingHours = 48;
  
  // Validation
  static const int nikLength = 16;
  static const int minPasswordLength = 8;
  static const int maxKtpPhotoSize = 5 * 1024 * 1024; // 5MB
  static const int maxAvatarSize = 2 * 1024 * 1024; // 2MB
  
  // Default Mitra Password
  static const String defaultMitraPassword = 'mitra123456';
  
  // Pagination
  static const int defaultPageSize = 20;
}
