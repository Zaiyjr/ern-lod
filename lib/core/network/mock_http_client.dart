import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/demo_account.dart';

/// An HTTP Mock Client / Interceptor that intercepts REST API calls
/// to `https://api.example.com` and provides realistic offline responses
/// with realistic latency and error validation.
class MockHttpClient extends http.BaseClient {
  MockHttpClient({
    this.defaultDelay = const Duration(milliseconds: 600),
    http.Client? innerClient,
  }) : _inner = innerClient ?? http.Client();

  final Duration defaultDelay;

  /// Real network delegate for hosts outside the mock surface, so calls
  /// such as OpenStreetMap tiles and Nominatim pass through untouched.
  final http.Client _inner;

  // In-memory registered user database for offline testing.
  // TODO(Slice 2 follow-up): replace with the real backend /api/v1/auth
  // endpoints; keep route shapes stable until then.
  final Map<String, _MockUserEntry> _users = {
    DemoAccount.email: _MockUserEntry(
      id: 'usr_mock_001',
      email: DemoAccount.email,
      password: DemoAccount.password,
      displayName: DemoAccount.displayName,
      photoUrl: null,
    ),
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Only the mock API surface is intercepted; everything else (OSM
    // tiles, Nominatim, and future real fleets) goes to the real network.
    if (request.url.host != 'api.example.com') {
      return _inner.send(request);
    }

    // Simulate real network trip
    if (defaultDelay > Duration.zero) {
      await Future<void>.delayed(defaultDelay);
    }

    final path = request.url.path;

    // Login endpoint
    if (path.endsWith('/v1/auth/login') && request.method == 'POST') {
      return _handleLogin(request);
    }

    // Register endpoint
    if (path.endsWith('/v1/auth/register') && request.method == 'POST') {
      return _handleRegister(request);
    }

    // Google sign-in endpoint (mock: resolves a canned Google identity)
    if (path.endsWith('/v1/auth/google') && request.method == 'POST') {
      return _handleGoogle(request);
    }

    // Default 404 for unhandled mock routes
    return _jsonResponse(
      statusCode: 404,
      body: {'error': 'Not Found', 'path': request.url.toString()},
    );
  }

  Future<http.StreamedResponse> _handleLogin(http.BaseRequest request) async {
    final body = await _parseBody(request);
    final email = body['email'] as String? ?? '';
    final password = body['password'] as String? ?? '';

    final user = _users[email.toLowerCase()];

    // Validate credentials
    if (user == null || user.password != password) {
      return _jsonResponse(
        statusCode: 401,
        body: {'message': 'Invalid email or password'},
      );
    }

    return _jsonResponse(
      statusCode: 200,
      body: {
        'id': user.id,
        'email': user.email,
        'display_name': user.displayName,
        'photo_url': user.photoUrl,
        'token': 'mock_jwt_token_${user.id}',
      },
    );
  }

  /// Validates a Google id token and resolves it to a canned Google
  /// identity, upserting the user so repeat sign-ins are idempotent.
  ///
  /// TODO(new backend): real flow verifies the id token server-side.
  Future<http.StreamedResponse> _handleGoogle(http.BaseRequest request) async {
    final body = await _parseBody(request);
    final idToken = body['id_token'] as String? ?? '';

    if (idToken.isEmpty) {
      return _jsonResponse(
        statusCode: 401,
        body: {'message': 'Missing or invalid Google id token'},
      );
    }

    const googleEmail = 'rider.google@gmail.com';
    final user = _users.putIfAbsent(
      googleEmail,
      () => _MockUserEntry(
        id: 'usr_mock_google_001',
        email: googleEmail,
        password: '', // passwordless: Google identity only
        displayName: 'May Vong',
        photoUrl: null,
      ),
    );

    return _jsonResponse(
      statusCode: 200,
      body: {
        'id': user.id,
        'email': user.email,
        'display_name': user.displayName,
        'photo_url': user.photoUrl,
        'token': 'mock_jwt_token_${user.id}',
      },
    );
  }

  Future<http.StreamedResponse> _handleRegister(http.BaseRequest request) async {
    final body = await _parseBody(request);
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    final password = body['password'] as String? ?? '';
    final displayName = body['displayName'] as String? ??
        (email.contains('@') ? email.split('@').first : 'User');

    if (email.isEmpty || password.length < 6) {
      return _jsonResponse(
        statusCode: 400,
        body: {'message': 'Password must be at least 6 characters'},
      );
    }

    if (_users.containsKey(email)) {
      return _jsonResponse(
        statusCode: 409,
        body: {'message': 'Email is already registered'},
      );
    }

    final newId = 'usr_mock_${DateTime.now().millisecondsSinceEpoch}';
    final newUser = _MockUserEntry(
      id: newId,
      email: email,
      password: password,
      displayName: displayName,
      photoUrl: null,
    );
    _users[email] = newUser;

    return _jsonResponse(
      statusCode: 201,
      body: {
        'id': newUser.id,
        'email': newUser.email,
        'display_name': newUser.displayName,
        'photo_url': newUser.photoUrl,
        'token': 'mock_jwt_token_${newUser.id}',
      },
    );
  }

  Future<Map<String, dynamic>> _parseBody(http.BaseRequest request) async {
    if (request is http.Request) {
      if (request.body.isEmpty) return {};
      try {
        return jsonDecode(request.body) as Map<String, dynamic>;
      } catch (_) {
        return {};
      }
    }
    final bytes = await request.finalize().toBytes();
    if (bytes.isEmpty) return {};
    try {
      return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  http.StreamedResponse _jsonResponse({
    required int statusCode,
    required Map<String, dynamic> body,
  }) {
    final bodyString = jsonEncode(body);
    final bodyBytes = utf8.encode(bodyString);
    final stream = Stream.value(bodyBytes);

    return http.StreamedResponse(
      stream,
      statusCode,
      contentLength: bodyBytes.length,
      headers: {'content-type': 'application/json'},
    );
  }
}

class _MockUserEntry {
  _MockUserEntry({
    required this.id,
    required this.email,
    required this.password,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String password;
  final String? displayName;
  final String? photoUrl;
}
