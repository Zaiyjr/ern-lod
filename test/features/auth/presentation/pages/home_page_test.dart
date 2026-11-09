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
import 'package:ride_booking/features/ride/presentation/bloc/ride_bloc.dart';

import '../../helpers/fakes.dart';

void main() {
  const testUser = User(
    id: '1',
    email: 'alex@example.com',
    displayName: 'Alex Rider',
  );

  Widget wrap({User? user = testUser, RideBloc? rideBloc}) {
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
        child: HomePage(rideBloc: rideBloc),
      ),
    );
  }

  testWidgets('renders idle home sheet elements matching mockup',
      (tester) async {
    await tester.pumpWidget(wrap());

    // User initial
    expect(find.text('A'), findsOneWidget);

    // Search bar
    expect(find.text('Where to?'), findsOneWidget);

    // Greeting & sheet title
    expect(find.text('GOOD EVENING, ALEX'), findsOneWidget);
    expect(find.text('Where are you going?'), findsOneWidget);

    // Saved places
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Maple St 24 · 12 min'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('3rd Ave 88 · 24 min'), findsOneWidget);

    // Action button & note
    expect(find.text('Set pickup location'), findsOneWidget);
    expect(find.text('4 drivers near Riverside Park'), findsOneWidget);
  });

  testWidgets('tapping a saved destination opens ride selection',
      (tester) async {
    await tester.pumpWidget(wrap());

    await tester.tap(find.text('Home'));
    await tester.pump(const Duration(milliseconds: 300));

    // Route recap and category rows with fare quotes
    expect(find.text('Choose a ride'), findsOneWidget);
    expect(find.text('Maple St 24'), findsWidgets);
    expect(find.text('Ride · 4 seats'), findsOneWidget);
    expect(find.text('XL · 6 seats'), findsOneWidget);
    expect(find.text('Share · 2 seats'), findsOneWidget);
    expect(find.text('₭ 45000'), findsOneWidget);

    // Confirm CTA in the thumb zone
    expect(find.text('Confirm ride · ₭ 45000'), findsOneWidget);
  });

  testWidgets('switching category updates the confirm CTA quote',
      (tester) async {
    await tester.pumpWidget(wrap());

    await tester.tap(find.text('Home'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('XL · 6 seats'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Confirm ride · ₭ 78000'), findsOneWidget);
  });

  testWidgets(
      'confirm runs the simulated lifecycle to the completed summary',
      (tester) async {
    final rideBloc = _ShortRideBloc();
    await tester.pumpWidget(wrap(rideBloc: rideBloc));

    await tester.tap(find.text('Home'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Confirm ride · ₭ 45000'));
    await tester.idle();

    // Matching (simulated timer fires at ~200ms)
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Finding your driver'), findsOneWidget);
    expect(find.text('Cancel ride'), findsOneWidget);

    // Assigned: driver identity + actions (match fired at 200ms)
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Pickup in 3 min'), findsOneWidget);
    expect(find.text('Somchai · ★ 4.9'), findsOneWidget);
    expect(find.text('Toyota Vios · White · LP 1234'), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);

    // In progress (pickup fired at 500ms)
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.textContaining('On the way to'), findsOneWidget);

    // Completed summary (trip fired at 900ms)
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Ride completed'), findsOneWidget);

    // Acknowledge returns to the idle sheet
    await tester.tap(find.text('Start a new ride'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Where are you going?'), findsOneWidget);
  });

  testWidgets('cancel ride from matching shows the cancelled summary',
      (tester) async {
    final rideBloc = _ShortRideBloc();
    await tester.pumpWidget(wrap(rideBloc: rideBloc));

    await tester.tap(find.text('Home'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Confirm ride · ₭ 45000'));
    await tester.idle();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Finding your driver'), findsOneWidget);

    await tester.tap(find.text('Cancel ride'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ride cancelled'), findsOneWidget);
    expect(find.text('Start a new ride'), findsOneWidget);
  });
}

/// Bloc with staggered simulated delays (200/300/400ms) so each phase is
/// observable in widget tests with explicit `pump` steps.
class _ShortRideBloc extends RideBloc {
  _ShortRideBloc()
      : super(
          matchDelay: const Duration(milliseconds: 200),
          pickupDelay: const Duration(milliseconds: 300),
          tripDelay: const Duration(milliseconds: 400),
        );
}
