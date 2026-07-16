class AppException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  AppException({
    required this.message,
    this.code,
    this.statusCode,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({String message = 'Gagal terhubung ke server. Periksa koneksi internet Anda.'})
      : super(message: message, code: 'NETWORK_ERROR');
}

class ServerException extends AppException {
  ServerException({
    required String message,
    int? statusCode,
  }) : super(message: message, code: 'SERVER_ERROR', statusCode: statusCode);
}

class AuthException extends AppException {
  AuthException({String message = 'Sesi Anda telah berakhir. Silakan login kembali.'})
      : super(message: message, code: 'AUTH_ERROR');
}

class ValidationException extends AppException {
  ValidationException({required String message})
      : super(message: message, code: 'VALIDATION_ERROR');
}

class NotFoundException extends AppException {
  NotFoundException({String message = 'Data tidak ditemukan.'})
      : super(message: message, code: 'NOT_FOUND');
}

class PermissionException extends AppException {
  PermissionException({required String message})
      : super(message: message, code: 'PERMISSION_DENIED');
}
