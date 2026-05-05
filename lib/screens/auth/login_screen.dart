import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/pocki_button.dart';
import '../../widgets/pocki_text_field.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    // Capture before async gap — survives State disposal after popUntil.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await auth.login(email: _email.text, password: _password.text);

    if (ok) {
      // Pop everything above AuthGate. AuthGate then renders HomeScreen
      // (verified) or VerifyEmailScreen (unverified) based on the new state.
      navigator.popUntil((route) => route.isFirst);
    } else if (mounted && auth.errorMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(auth.errorMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      appBar: AppBar(title: const Text('Welcome Back')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Welcome back! 💕',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Log in to continue your learning streak.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
                PockiTextField(
                  controller: _email,
                  label: 'Email',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                PockiTextField(
                  controller: _password,
                  label: 'Password',
                  icon: Icons.lock_rounded,
                  obscure: true,
                  validator: Validators.password,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ));
                    },
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PockiButton(
                  label: 'Log In',
                  loading: auth.busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () {
                    // Use push (not pushReplacement) so the back button on
                    // RegisterScreen returns to Login instead of jumping
                    // straight to Welcome.
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const RegisterScreen(),
                    ));
                  },
                  child: const Text("Don't have an account? Sign up"),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
