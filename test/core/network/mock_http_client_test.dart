import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ride_booking/core/network/mock_http_client.dart';

void main() {
  late MockHttpClient client;

  setUp(() {
    client = MockHttpClient(defaultDelay: Duration.zero);
  });

  group('MockHttpClient', () {
    test('succeeds with default pre-seeded credentials', () async {
      final response = await client.post(
        Uri.parse('https://api.example.com/v1/auth/login'),
        body: jsonEncode({'email': 'alex@example.com', 'password': 'password123'}),
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['email'], 'alex@example.com');
      expect(body['display_name'], 'Alex Rider');
    });

    test('returns 401 on wrong password', () async {
      final response = await client.post(
        Uri.parse('https://api.example.com/v1/auth/login'),
        body: jsonEncode({'email': 'alex@example.com', 'password': 'wrong'}),
      );

      expect(response.statusCode, 401);
    });

    test('registers new user and allows login with new credentials', () async {
      final regResponse = await client.post(
        Uri.parse('https://api.example.com/v1/auth/register'),
        body: jsonEncode({
          'email': 'newuser@example.com',
          'password': 'secretpassword',
          'displayName': 'New User',
        }),
      );

      expect(regResponse.statusCode, 201);

      final loginResponse = await client.post(
        Uri.parse('https://api.example.com/v1/auth/login'),
        body: jsonEncode({
          'email': 'newuser@example.com',
          'password': 'secretpassword',
        }),
      );

      expect(loginResponse.statusCode, 200);
      final body = jsonDecode(loginResponse.body) as Map<String, dynamic>;
      expect(body['email'], 'newuser@example.com');
      expect(body['display_name'], 'New User');
    });

    test('rejects duplicate email registration with 409', () async {
      final regResponse = await client.post(
        Uri.parse('https://api.example.com/v1/auth/register'),
        body: jsonEncode({
          'email': 'alex@example.com',
          'password': 'password123',
        }),
      );

      expect(regResponse.statusCode, 409);
    });
  });
}
