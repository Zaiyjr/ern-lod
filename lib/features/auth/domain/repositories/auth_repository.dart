import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';

/// Contract for auth persistence, implemented in the data layer.
///
/// The domain layer depends only on this interface (dependency
/// inversion), never on a concrete datasource.
abstract interface class AuthRepository {
  /// Signs in with [email] and [password], returning the authenticated [User].
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  });

  /// Returns the cached [User] if a live session exists, else [None].
  Future<Either<Failure, User?>> getCurrentUser();

  /// Persists the session after a successful sign-in.
  Future<Either<Failure, void>> cacheSession(User user);

  /// Clears the cached session on sign-out.
  Future<Either<Failure, void>> signOut();
}
