import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ride_booking/features/auth/domain/usecases/check_auth_status.dart';
import 'package:ride_booking/features/auth/domain/usecases/register.dart';
import 'package:ride_booking/features/auth/domain/usecases/sign_in.dart';
import 'package:ride_booking/features/auth/domain/usecases/sign_out.dart';
import 'package:ride_booking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ride_booking/features/auth/presentation/pages/register_page.dart';

import '../../helpers/fakes.dart';

void main() {
  Widget wrap() {
    final repository = FakeAuthRepository();
    final bloc = AuthBloc(
      signIn: SignIn(repository),
      register: Register(repository),
      checkAuthStatus: CheckAuthStatus(repository),
      signOut: SignOut(repository),
    );
    return MaterialApp(
      home: BlocProvider.value(
        value: bloc,
        child: const RegisterPage(),
      ),
    );
  }

  testWidgets('renders register form fields and create account button',
      (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.text('Create account'), findsNWidgets(2)); // Title & button
    expect(find.text('Full name (optional)'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });

  testWidgets('shows validation errors when submitting invalid email/password',
      (tester) async {
    await tester.pumpWidget(wrap());

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('validates password mismatch and length', (tester) async {
    await tester.pumpWidget(wrap());

    final fields = find.byType(TextFormField);
    // fields: 0 = name, 1 = email, 2 = password, 3 = confirm
    await tester.enterText(fields.at(1), 'user@test.com');
    await tester.enterText(fields.at(2), '123');
    await tester.enterText(fields.at(3), '123456');

    await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
    await tester.pump();

    expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
  });
}
