import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Registers a new user, then persists the session.
class Register implements UseCase<User, RegisterParams> {
  const Register(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, User>> call(RegisterParams params) async {
    final result = await _repository.register(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
    );

    return result.fold<Future<Either<Failure, User>>>(
      (failure) async => Left<Failure, User>(failure),
      (user) async {
        await _repository.cacheSession(user);
        return Right<Failure, User>(user);
      },
    );
  }
}

class RegisterParams extends Equatable {
  const RegisterParams({
    required this.email,
    required this.password,
    this.displayName,
  });

  final String email;
  final String password;
  final String? displayName;

  @override
  List<Object?> get props => [email, password, displayName];
}
