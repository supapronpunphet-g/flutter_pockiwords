import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/pocki_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _poller;
  bool _resending = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    // Poll every 3 seconds to detect verification.
    _poller = Timer.periodic(const Duration(seconds: 3), (_) async {
      final auth = context.read<AuthProvider>();
      await auth.refreshVerification();
    });
  }

  @override
  void dispose() {
    _poller?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_cooldown > 0) return;
    setState(() => _resending = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.sendVerificationEmail();
    if (!mounted) return;
    setState(() {
      _resending = false;
      if (ok) _cooldown = 30;
    });
    if (ok) {
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() {
          _cooldown -= 1;
          if (_cooldown <= 0) t.cancel();
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent.')),
      );
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.firebaseUser?.email ?? '';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  size: 80,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Verify your email',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  children: [
                    Text(
                      'We sent a verification link to\n$email.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppColors.primaryDark, size: 20),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              "Can't find it? Check your Spam or Junk folder. "
                              'After clicking the link, come back here — '
                              'we will detect it automatically.',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PockiButton(
                label: _cooldown > 0
                    ? 'Resend in $_cooldown s'
                    : 'Resend Verification Email',
                icon: Icons.mail_rounded,
                loading: _resending,
                onPressed: _cooldown > 0 ? null : _resend,
              ),
              const SizedBox(height: AppSpacing.md),
              PockiOutlineButton(
                label: 'I have verified my email',
                icon: Icons.check_circle_rounded,
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = await auth.refreshVerification();
                  if (!ok) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Not verified yet. Tap the link in your email '
                          'first, then try again.',
                        ),
                      ),
                    );
                  }
                  // On verified=true, AuthGate flips to HomeScreen automatically.
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  auth.logout();
                },
                child: const Text('Sign out / Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
