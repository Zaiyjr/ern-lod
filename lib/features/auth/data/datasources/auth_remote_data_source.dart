import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Contract for the auth API, so the implementation is swappable in tests.
abstract interface class AuthRemoteDataSource {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> register({
    required String email,
    required String password,
    String? displayName,
  });
}

/// Calls a real REST endpoint to authenticate.
///
/// Throws [InvalidCredentialsException] on a 401 and [ServerException]
/// on any other non-2xx, keeping exceptions out of the domain layer.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static final _endpoint = Uri.parse('https://api.example.com/v1/auth/login');
  static final _registerEndpoint =
      Uri.parse('https://api.example.com/v1/auth/register');

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final http.Response response;
    try {
      response = await _client.post(
        _endpoint,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
    } on http.ClientException {
      throw const NetworkException();
    }

    switch (response.statusCode) {
      case 200:
        return UserModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      case 401:
        throw const InvalidCredentialsException();
      default:
        throw ServerException('Login failed (${response.statusCode})');
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final http.Response response;
    try {
      response = await _client.post(
        _registerEndpoint,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          if (displayName != null) 'displayName': displayName,
        }),
      );
    } on http.ClientException {
      throw const NetworkException();
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        return UserModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      case 400:
      case 409:
        final dynamic body = jsonDecode(response.body);
        final msg = body is Map<String, dynamic>
            ? (body['message'] as String? ?? 'Registration failed')
            : 'Registration failed';
        throw ServerException(msg);
      default:
        throw ServerException('Registration failed (${response.statusCode})');
    }
  }
}
