import 'package:dartz/dartz.dart';

import 'package:ride_booking/core/error/exceptions.dart';
import 'package:ride_booking/core/error/failures.dart';
import 'package:ride_booking/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ride_booking/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:ride_booking/features/auth/data/models/user_model.dart';
import 'package:ride_booking/features/auth/domain/entities/user.dart';
import 'package:ride_booking/features/auth/domain/repositories/auth_repository.dart';

/// A configurable in-memory [AuthRepository] for domain/presentation tests.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.user,
    this.signInFailure,
    this.cacheFailure,
  });

  /// User returned by a successful [signIn]/[getCurrentUser].
  final User? user;

  /// When non-null, [signIn] returns this failure instead of a user.
  final Failure? signInFailure;

  /// When non-null, [cacheSession] returns this failure.
  final Failure? cacheFailure;

  bool cacheSessionCalled = false;
  bool signOutCalled = false;

  @override
  Future<Either<Failure, User>> signIn({
    required String email,
    required String password,
  }) async {
    final failure = signInFailure;
    if (failure != null) return Left(failure);
    return Right(user!);
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async => Right(user);

  @override
  Future<Either<Failure, void>> cacheSession(User user) async {
    cacheSessionCalled = true;
    final failure = cacheFailure;
    if (failure != null) return Left(failure);
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    signOutCalled = true;
    return const Right(null);
  }
}

/// A configurable [AuthRemoteDataSource] for data-layer tests.
class FakeRemoteDataSource implements AuthRemoteDataSource {
  FakeRemoteDataSource({this.user, this.error});

  final UserModel? user;

  /// When non-null, [signIn] throws this instead of returning a user.
  final Object? error;

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final thrown = error;
    if (thrown != null) throw thrown;
    return user!;
  }
}

/// A configurable [AuthLocalDataSource] for data-layer tests.
class FakeLocalDataSource implements AuthLocalDataSource {
  UserModel? cached;

  @override
  Future<void> cacheSession(UserModel user) async => cached = user;

  @override
  Future<UserModel> getLastSession() async {
    final session = cached;
    if (session == null) throw const SessionExpiredException();
    return session;
  }

  @override
  Future<void> clearSession() async => cached = null;
}
