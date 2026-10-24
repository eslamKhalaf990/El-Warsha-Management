import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:warsha_app/view_models/user_v_m.dart';
import 'package:warsha_app/views/auth/login.dart';
import 'package:warsha_app/views/home.dart';

/// Root route: shows a splash while the saved session is restored, then Home
/// or Login. When the session ends, any pages or dialogs opened on top are
/// closed so the user lands on the login screen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _wasAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserViewModel>();

    if (_wasAuthenticated && !user.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
    _wasAuthenticated = user.isAuthenticated;

    if (user.isRestoring) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return user.isAuthenticated ? const Home() : const Login();
  }
}
