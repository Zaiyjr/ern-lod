import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ride_booking/features/auth/domain/usecases/check_auth_status.dart';
import 'package:ride_booking/features/auth/domain/usecases/sign_in.dart';
import 'package:ride_booking/features/auth/domain/usecases/sign_out.dart';
import 'package:ride_booking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ride_booking/features/auth/presentation/pages/login_page.dart';

import '../../helpers/fakes.dart';

void main() {
  Widget wrap() {
    final repository = FakeAuthRepository();
    final bloc = AuthBloc(
      signIn: SignIn(repository),
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
}
