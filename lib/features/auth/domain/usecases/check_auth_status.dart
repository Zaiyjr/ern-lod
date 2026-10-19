import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Resolves the current session on app start (splash → login or home).
class CheckAuthStatus implements UseCase<User?, NoParams> {
  const CheckAuthStatus(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, User?>> call(NoParams params) =>
      _repository.getCurrentUser();
}
