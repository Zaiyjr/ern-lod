import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Contract for local session persistence, swappable in tests.
abstract interface class AuthLocalDataSource {
  Future<void> cacheSession(UserModel user);
  Future<UserModel> getLastSession();
  Future<void> clearSession();
}

/// In-memory session cache.
///
/// Swap for a `shared_preferences`/`flutter_secure_storage` backed
/// implementation without touching the domain layer — only this
/// datasource changes.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  UserModel? _cached;

  @override
  Future<void> cacheSession(UserModel user) async => _cached = user;

  @override
  Future<UserModel> getLastSession() async {
    final user = _cached;
    if (user == null) throw const SessionExpiredException();
    return user;
  }

  @override
  Future<void> clearSession() async => _cached = null;
}
