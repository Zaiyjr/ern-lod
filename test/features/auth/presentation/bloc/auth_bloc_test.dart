import 'package:flutter_test/flutter_test.dart';

import 'package:ride_booking/core/error/failures.dart';
import 'package:ride_booking/features/auth/domain/entities/user.dart';
import 'package:ride_booking/features/auth/domain/usecases/check_auth_status.dart';
import 'package:ride_booking/features/auth/domain/usecases/register.dart';
import 'package:ride_booking/features/auth/domain/usecases/sign_in.dart';
import 'package:ride_booking/features/auth/domain/usecases/sign_out.dart';
import 'package:ride_booking/features/auth/presentation/bloc/auth_bloc.dart';

import '../../helpers/fakes.dart';

void main() {
  const user = User(id: '42', email: 'rider@example.com');

  AuthBloc buildBloc({
    User? user,
    Failure? signInFailure,
    Failure? registerFailure,
  }) {
    final repository = FakeAuthRepository(
      user: user,
      signInFailure: signInFailure,
      registerFailure: registerFailure,
    );
    return AuthBloc(
      signIn: SignIn(repository),
      register: Register(repository),
      checkAuthStatus: CheckAuthStatus(repository),
      signOut: SignOut(repository),
    );
  }

  test('AuthCheckRequested emits authenticated when a session exists',
      () async {
    final bloc = buildBloc(user: user);
    final expectation = expectLater(
      bloc.stream,
      emits(isA<AuthAuthenticated>()),
    );

    bloc.add(const AuthCheckRequested());
    await expectation;
    await bloc.close();
  });

  test('AuthCheckRequested emits unauthenticated when no session exists',
      () async {
    final bloc = buildBloc(user: null);
    final expectation = expectLater(
      bloc.stream,
      emits(isA<AuthUnauthenticated>()),
    );

    bloc.add(const AuthCheckRequested());
    await expectation;
    await bloc.close();
  });

  test('AuthSignInRequested emits [loading, authenticated] on success',
      () async {
    final bloc = buildBloc(user: user);
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoading>(), isA<AuthAuthenticated>()]),
    );

    bloc.add(const AuthSignInRequested(
      email: 'rider@example.com',
      password: 'hunter2',
    ));
    await expectation;
    await bloc.close();
  });

  test('AuthSignInRequested emits [loading, unauthenticated] on failure',
      () async {
    final bloc = buildBloc(
      user: user,
      signInFailure: const InvalidCredentialsFailure(),
    );
    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
    );

    bloc.add(const AuthSignInRequested(
      email: 'rider@example.com',
      password: 'wrong',
    ));
    await expectation;
    await bloc.close();
  });

  test('AuthSignOutRequested emits unauthenticated', () async {
    final bloc = buildBloc(user: user);
    final expectation = expectLater(
      bloc.stream,
      emits(isA<AuthUnauthenticated>()),
    );

    bloc.add(const AuthSignOutRequested());
    await expectation;
    await bloc.close();
  });
}
