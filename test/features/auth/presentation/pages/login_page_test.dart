import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ride_booking/features/auth/domain/entities/user.dart';
import 'package:ride_booking/features/auth/domain/usecases/check_auth_status.dart';
import 'package:ride_booking/features/auth/domain/usecases/google_sign_in.dart';
import 'package:ride_booking/features/auth/domain/usecases/register.dart';
import 'package:ride_booking/features/auth/domain/usecases/sign_in.dart';
import 'package:ride_booking/features/auth/domain/usecases/sign_out.dart';
import 'package:ride_booking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ride_booking/features/auth/presentation/pages/login_page.dart';

import '../../helpers/fakes.dart';

void main() {
  const user = User(id: '1', email: 'alex@example.com', displayName: 'Alex Rider');
  Widget wrap() {
    final repository = FakeAuthRepository();
    final bloc = AuthBloc(
      signIn: SignIn(repository),
      googleSignIn: GoogleSignIn(repository),
      register: Register(repository),
      checkAuthStatus: CheckAuthStatus(repository),
      signOut: SignOut(repository),
    );
    return MaterialApp(
      home: BlocProvider.value(
        value: bloc,
        child: const LoginPage(),
      ),
    );
  }

  testWidgets('renders the email and password fields', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('shows validation errors when submitting an empty form',
      (tester) async {
    await tester.pumpWidget(wrap());

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('rejects an email without an @ sign', (tester) async {
    await tester.pumpWidget(wrap());

    await tester.enterText(
      find.byType(TextFormField).first,
      'not-an-email',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('offers demo-account and Google sign-in entry points',
      (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.text('Use demo account'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.textContaining('Demo: alex@example.com'), findsOneWidget);
  });

  testWidgets('demo account button dispatches the demo sign-in',
      (tester) async {
    final repository = FakeAuthRepository(
      user: user,
    );
    final bloc = AuthBloc(
      signIn: SignIn(repository),
      googleSignIn: GoogleSignIn(repository),
      register: Register(repository),
      checkAuthStatus: CheckAuthStatus(repository),
      signOut: SignOut(repository),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: const LoginPage(),
        ),
      ),
    );

    await tester.tap(find.text('Use demo account'));
    await tester.idle();

    // The demo credentials resolve through the full sign-in path.
    expect(bloc.state, isA<AuthAuthenticated>());
  });
}
