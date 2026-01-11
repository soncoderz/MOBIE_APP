/// Base exception class
class AppException implements Exception {
  final String message;
  final int? statusCode;

  AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Server exception - thrown when API returns an error
class ServerException extends AppException {
  ServerException(super.message, [super.statusCode]);
}

/// Network exception - thrown when there's no internet connection
class NetworkException extends AppException {
  NetworkException(super.message);
}

/// Authentication exception - thrown when auth fails
class AuthenticationException extends AppException {
  AuthenticationException(super.message, [super.statusCode]);
}

/// Validation exception - thrown when validation fails
class ValidationException extends AppException {
  ValidationException(super.message);
}

/// Field validation exception - thrown when a specific field has validation error
class FieldValidationException extends AppException {
  final String? field;
  
  FieldValidationException(String message, {this.field, int? statusCode}) 
      : super(message, statusCode);
}

/// Email not verified exception - thrown when user tries to login without verifying email
class EmailNotVerifiedException extends AppException {
  EmailNotVerifiedException(super.message, [super.statusCode]);
}

/// Cache exception - thrown when cache operations fail
class CacheException extends AppException {
  CacheException(super.message);
}
