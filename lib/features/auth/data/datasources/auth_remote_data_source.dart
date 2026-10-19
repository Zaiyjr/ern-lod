import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Contract for the auth API, so the implementation is swappable in tests.
abstract interface class AuthRemoteDataSource {
  Future<UserModel> signIn({required String email, required String password});
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
}
