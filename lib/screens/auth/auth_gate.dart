import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/loading_view.dart';
import '../home_screen.dart';
import 'verify_email_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    debugPrint('[AuthGate] resolved status=${auth.status.name}');
    return switch (auth.status) {
      AuthStatus.loading => const LoadingView(message: 'Waking up Pocki…'),
      AuthStatus.signedOut => const WelcomeScreen(),
      AuthStatus.awaitingVerification => const VerifyEmailScreen(),
      AuthStatus.signedIn => const HomeScreen(),
    };
  }
}
