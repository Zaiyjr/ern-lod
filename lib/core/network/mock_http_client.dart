import 'dart:convert';
import 'package:http/http.dart' as http;

/// An HTTP Mock Client / Interceptor that intercepts REST API calls
/// to `https://api.example.com` and provides realistic offline responses
/// with realistic latency and error validation.
class MockHttpClient extends http.BaseClient {
  MockHttpClient({this.defaultDelay = const Duration(milliseconds: 600)});

  final Duration defaultDelay;

  // In-memory registered user database for offline testing
  final Map<String, _MockUserEntry> _users = {
    'alex@example.com': _MockUserEntry(
      id: 'usr_mock_001',
      email: 'alex@example.com',
      password: 'password123',
      displayName: 'Alex Rider',
      photoUrl: null,
    ),
  };

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
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
