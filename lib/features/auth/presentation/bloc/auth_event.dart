import 'package:equatable/equatable.dart';

/// Events consumed by [AuthBloc].
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// User submitted the login form.
class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// App start: resolve whether a cached session exists.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// User tapped sign-out.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
