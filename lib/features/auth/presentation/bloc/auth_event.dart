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

/// User tapped "Continue with Google".
///
/// The id token defaults to the mock identity exchange value while the
/// Google provider stands in for the real backend flow.
class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested({this.idToken = 'mock_google_id_token'});

  final String idToken;

  @override
  List<Object?> get props => [idToken];
}

/// User submitted the register form.
class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
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

/// App start: resolve whether a cached session exists.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// User tapped sign-out.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
