import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/pocki_button.dart';
import '../../widgets/pocki_text_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    // Capture before any async gap — these references stay valid even after
    // popUntil disposes this State.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final ok = await auth.register(
      username: _username.text,
      email: _email.text,
      password: _password.text,
    );

    if (ok) {
      // Pop everything pushed on top of AuthGate so the verify-email screen
      // (which AuthGate is now showing for the unverified user) becomes
      // visible. Without this we stay stuck on RegisterScreen.
      navigator.popUntil((route) => route.isFirst);
      messenger.showSnackBar(const SnackBar(
        content: Text(
          'Verification email sent. Please check your inbox or spam folder.',
        ),
        duration: Duration(seconds: 5),
      ));
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
      appBar: AppBar(title: const Text('Create Account')),
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
                  'Hi there! 🌸',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Set up your PockiWords account to start learning.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),
                PockiTextField(
                  controller: _username,
                  label: 'Username',
                  icon: Icons.person_rounded,
                  validator: Validators.username,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
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
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                PockiTextField(
                  controller: _confirm,
                  label: 'Confirm password',
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  validator: (v) =>
                      Validators.confirmPassword(v, _password.text),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpacing.xl),
                PockiButton(
                  label: 'Sign Up',
                  loading: auth.busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () {
                    // Replace Register with Login regardless of how the user
                    // got here — the link clearly says "go to login", so
                    // dropping them on Welcome would be unexpected.
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ));
                  },
                  child: const Text('Already have an account? Log in'),
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
