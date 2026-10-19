import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'injection_container.dart';

/// Root widget: provides [AuthBloc] and routes on its state.
///
/// Auth routing is state-driven (`AuthAuthenticated` → [HomePage],
/// otherwise [LoginPage]) so navigation can never desync from the
/// session state.
class RideBookingApp extends StatefulWidget {
  const RideBookingApp({super.key});

  @override
  State<RideBookingApp> createState() => _RideBookingAppState();
}

class _RideBookingAppState extends State<RideBookingApp> {
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(const AuthCheckRequested());
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp(
        title: 'Ride Booking',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) => switch (state) {
            AuthAuthenticated() => const HomePage(),
            AuthInitial() || AuthLoading() => const _SplashView(),
            _ => const LoginPage(),
          },
        ),
      ),
    );
  }
}

/// Shown while the cached session is being resolved.
class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
