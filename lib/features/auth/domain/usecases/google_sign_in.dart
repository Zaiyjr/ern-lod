import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Coordinates a Google sign-in: authenticate with an id token, then
/// cache the session — mirroring [SignIn]'s shape so the Bloc folds the
/// same Either type.
///
/// The id token is currently produced by the offline mock flow; when the
/// real provider is introduced, presentation obtains a real Google id
/// token and this use case stays unchanged.
class GoogleSignIn implements UseCase<User, GoogleSignInParams> {
  const GoogleSignIn(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, User>> call(GoogleSignInParams params) async {
    final result =
        await _repository.signInWithGoogle(idToken: params.idToken);

    return result.fold<Future<Either<Failure, User>>>(
      (failure) async => Left<Failure, User>(failure),
      (user) async {
        await _repository.cacheSession(user);
        return Right<Failure, User>(user);
      },
    );
  }
}

class GoogleSignInParams extends Equatable {
  const GoogleSignInParams({required this.idToken});

  final String idToken;

  @override
  List<Object?> get props => [idToken];
}
