import 'package:flutter/material.dart';

import 'login_page.dart';
import 'register_page.dart';

/// Entry page for unauthenticated users, managing switching between
/// login and register modes.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _isLogin
          ? LoginPage(
              key: const ValueKey('LoginPage'),
              onToggleMode: _toggleMode,
            )
          : RegisterPage(
              key: const ValueKey('RegisterPage'),
              onToggleMode: _toggleMode,
            ),
    );
  }
}
