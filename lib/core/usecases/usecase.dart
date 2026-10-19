import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Contract every use case implements.
///
/// [Output] is the success type, [Params] the input type. Use
/// [NoParams] when a use case takes no arguments. Implementations
/// stay pure: no Flutter imports, no I/O — they call repositories.
abstract interface class UseCase<Output, Params> {
  Future<Either<Failure, Output>> call(Params params);
}

/// Marker for use cases that take no input (e.g. `CheckAuthStatus`).
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
