import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';

/// States emitted by [AuthBloc].
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial / loading a session (splash).
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Sign-in request in flight.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated, carrying the [User].
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

/// Not signed in (or signed out). [message] surfaces an error, if any.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
}
