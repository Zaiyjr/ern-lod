import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Coordinates a sign-in: authenticate, then cache the session.
///
/// Kept free of Flutter imports so it can be unit-tested with a fake
/// [AuthRepository].
class SignIn implements UseCase<User, SignInParams> {
  const SignIn(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, User>> call(SignInParams params) async {
    final result = await _repository.signIn(
      email: params.email,
      password: params.password,
    );

    // dartz's fold is synchronous, so both branches return a Future and
    // fold over `Future<Either<Failure, User>>`: Left short-circuits,
    // Right caches the session before returning the user.
    return result.fold<Future<Either<Failure, User>>>(
      (failure) async => Left<Failure, User>(failure),
      (user) async {
        await _repository.cacheSession(user);
        return Right<Failure, User>(user);
      },
    );
  }
}

class SignInParams extends Equatable {
  const SignInParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
