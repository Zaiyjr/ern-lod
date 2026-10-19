/// Base exception for all data-layer failures.
///
/// Thrown by datasources and mapped to [Failure]s by repository
/// implementations, so the domain layer never sees an exception.
class ServerException implements Exception {
  const ServerException([this.message = 'Unexpected server error']);

  final String message;

  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection']);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when credentials are rejected by the auth API.
class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException(
      [this.message = 'Email or password is incorrect']);

  final String message;

  @override
  String toString() => 'InvalidCredentialsException: $message';
}

/// Thrown when a cached session exists but is expired.
class SessionExpiredException implements Exception {
  const SessionExpiredException([this.message = 'Session expired']);

  final String message;

  @override
  String toString() => 'SessionExpiredException: $message';
}
