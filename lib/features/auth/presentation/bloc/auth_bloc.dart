import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/check_auth_status.dart';
import '../../domain/usecases/register.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

/// Orchestrates the auth flow: turns [AuthEvent]s into [AuthState]s by
/// calling use cases and folding the [Either] result.
///
/// Knows nothing about datasources or the widget tree — it depends only
/// on domain use cases, keeping the presentation layer testable.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.signIn,
    required this.register,
    required this.checkAuthStatus,
    required this.signOut,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  final SignIn signIn;
  final Register register;
  final CheckAuthStatus checkAuthStatus;
  final SignOut signOut;

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final Either<Failure, User?> result =
        await checkAuthStatus(const NoParams());

    result.fold(
      (_) => emit(const AuthUnauthenticated()),
      (user) => user == null
          ? emit(const AuthUnauthenticated())
          : emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final Either<Failure, User> result = await signIn(
      SignInParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) => emit(AuthUnauthenticated(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final Either<Failure, User> result = await register(
      RegisterParams(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      ),
    );

    result.fold(
      (failure) => emit(AuthUnauthenticated(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await signOut(const NoParams());
    emit(const AuthUnauthenticated());
  }
}
