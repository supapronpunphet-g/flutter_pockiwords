import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/constants.dart';
import 'pocki_button.dart';

/// Shared end-of-game screen used by every mini-game.
class GameResultView extends StatelessWidget {
  const GameResultView({
    super.key,
    required this.gameType,
    required this.score,
    this.subtitle,
    this.maxScore,
    required this.onPlayAgain,
    required this.onDone,
  });

  final GameType gameType;
  final int score;
  final int? maxScore;
  final String? subtitle;
  final VoidCallback onPlayAgain;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(gameType.label)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              const Text('🎉', style: TextStyle(fontSize: 80))
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Great job!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gameType.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color:
                          gameType.gradient.last.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      maxScore == null ? '$score' : '$score / $maxScore',
                      style: const TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Final score',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
              const Spacer(),
              PockiButton(
                label: 'Play Again',
                icon: Icons.replay_rounded,
                onPressed: onPlayAgain,
              ),
              const SizedBox(height: AppSpacing.md),
              PockiOutlineButton(
                label: 'Done',
                icon: Icons.check_rounded,
                onPressed: onDone,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
