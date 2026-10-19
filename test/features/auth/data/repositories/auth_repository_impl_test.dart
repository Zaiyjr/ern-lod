import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ride_booking/core/error/exceptions.dart';
import 'package:ride_booking/core/error/failures.dart';
import 'package:ride_booking/features/auth/data/models/user_model.dart';
import 'package:ride_booking/features/auth/data/repositories/auth_repository_impl.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeRemoteDataSource remote;
  late FakeLocalDataSource local;
  late AuthRepositoryImpl repository;

  const userModel = UserModel(
    id: '42',
    email: 'rider@example.com',
    displayName: 'Riley Rider',
  );

  setUp(() {
    remote = FakeRemoteDataSource();
    local = FakeLocalDataSource();
    repository = AuthRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
    );
  });

  group('signIn', () {
    test('maps a successful response to a Right of the domain entity',
        () async {
      remote = FakeRemoteDataSource(user: userModel);
      repository = AuthRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );

      final result = await repository.signIn(
        email: 'rider@example.com',
        password: 'hunter2',
      );

      expect(result.isRight(), isTrue);
      final user = result.getOrElse(() => throw StateError('expected Right'));
      expect(user.id, '42');
      expect(user.email, 'rider@example.com');
      expect(user.displayName, 'Riley Rider');
    });

    test('maps InvalidCredentialsException to InvalidCredentialsFailure',
        () async {
      remote = FakeRemoteDataSource(error: const InvalidCredentialsException());
      repository = AuthRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );

      final result = await repository.signIn(
        email: 'rider@example.com',
        password: 'wrong',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<InvalidCredentialsFailure>()),
        (_) => fail('expected a Left'),
      );
    });

    test('maps NetworkException to NetworkFailure', () async {
      remote = FakeRemoteDataSource(error: const NetworkException());
      repository = AuthRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );

      final result = await repository.signIn(
        email: 'rider@example.com',
        password: 'hunter2',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (_) => fail('expected a Left'),
      );
    });

    test('maps ServerException to ServerFailure', () async {
      remote = FakeRemoteDataSource(error: const ServerException('boom'));
      repository = AuthRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );

      final result = await repository.signIn(
        email: 'rider@example.com',
        password: 'hunter2',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('expected a Left'),
      );
    });
  });

  group('getCurrentUser', () {
    test('returns Right of the cached entity when a session exists', () async {
      await local.cacheSession(userModel);

      final result = await repository.getCurrentUser();

      expect(result.isRight(), isTrue);
      final user = result.getOrElse(() => throw StateError('expected Right'));
      expect(user.id, '42');
    });

    test('returns Right(null) when no session is cached', () async {
      final result = await repository.getCurrentUser();

      expect(result.isRight(), isTrue);
      expect(result.getOrElse(() => throw StateError('expected Right')), isNull);
    });
  });

  group('cacheSession / signOut', () {
    test('cacheSession round-trips through the local datasource', () async {
      final entity = userModel.toEntity();

      final cached = await repository.cacheSession(entity);
      expect(cached.isRight(), isTrue);

      final retrieved = await repository.getCurrentUser();
      expect(retrieved.getOrElse(() => throw StateError('expected Right')), entity);
    });

    test('signOut clears the cached session', () async {
      await local.cacheSession(userModel);

      final result = await repository.signOut();
      expect(result.isRight(), isTrue);

      final retrieved = await repository.getCurrentUser();
      expect(retrieved.getOrElse(() => throw StateError('expected Right')), isNull);
    });
  });
}
