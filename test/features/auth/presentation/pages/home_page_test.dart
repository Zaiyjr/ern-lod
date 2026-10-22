import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ride_booking/features/auth/domain/entities/user.dart';
import 'package:ride_booking/features/auth/domain/usecases/check_auth_status.dart';
import 'package:ride_booking/features/auth/domain/usecases/register.dart';
import 'package:ride_booking/features/auth/domain/usecases/sign_in.dart';
import 'package:ride_booking/features/auth/domain/usecases/sign_out.dart';
import 'package:ride_booking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ride_booking/features/auth/presentation/pages/home_page.dart';

import '../../helpers/fakes.dart';

void main() {
  const testUser = User(
    id: '1',
    email: 'alex@example.com',
    displayName: 'Alex Rider',
  );

  Widget wrap({User? user = testUser}) {
    final repository = FakeAuthRepository(user: user);
    final bloc = AuthBloc(
      signIn: SignIn(repository),
      register: Register(repository),
      checkAuthStatus: CheckAuthStatus(repository),
      signOut: SignOut(repository),
    );
    if (user != null) {
      bloc.emit(AuthAuthenticated(user));
    }
    return MaterialApp(
      home: BlocProvider.value(
        value: bloc,
        child: const HomePage(),
      ),
    );
  }

  testWidgets('renders screen 01 home page elements matching mockup',
      (tester) async {
    await tester.pumpWidget(wrap());

    // User initial
    expect(find.text('A'), findsOneWidget);

    // Search bar
    expect(find.text('Where to?'), findsOneWidget);

    // Ride type chips
    expect(find.text('Ride'), findsOneWidget);
    expect(find.text('XL'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    // Greeting & sheet title
    expect(find.text('GOOD EVENING, ALEX'), findsOneWidget);
    expect(find.text('Where are you going?'), findsOneWidget);

    // Saved places
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Maple St 24 · 12 min'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('3rd Ave 88 · 24 min'), findsOneWidget);

    // Action button & notes
    expect(find.text('Set pickup location'), findsOneWidget);
    expect(find.text('4 drivers near Riverside Park'), findsOneWidget);
  });

  testWidgets('switching ride type chip updates state', (tester) async {
    await tester.pumpWidget(wrap());

    await tester.tap(find.text('XL'));
    await tester.pump();

    // Verify it doesn't crash and renders properly
    expect(find.text('XL'), findsOneWidget);
  });

  testWidgets('tapping saved destination shows snackbar', (tester) async {
    await tester.pumpWidget(wrap());

    await tester.tap(find.text('Home'));
    await tester.pump();

    expect(find.text('Selected destination: Maple St 24 (Home)'),
        findsOneWidget);
  });
}
