import 'package:equatable/equatable.dart';

/// Base class for every domain-layer failure.
///
/// Repositories return `Either<Failure, T>` instead of throwing, so
/// use cases and the presentation layer handle errors functionally.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Unexpected server error']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure(
      [super.message = 'Email or password is incorrect']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cached session unavailable']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Something went wrong']);
}
