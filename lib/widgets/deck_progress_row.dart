import 'package:flutter/material.dart';

import '../models/deck.dart';
import '../utils/constants.dart';

class DeckProgressRow extends StatelessWidget {
  const DeckProgressRow({
    super.key,
    required this.deck,
    required this.learned,
    required this.total,
    required this.onTap,
  });

  final Deck deck;
  final int learned;
  final int total;
  final VoidCallback onTap;

  double get _ratio => total == 0 ? 0 : learned / total;

  @override
  Widget build(BuildContext context) {
    final percent = (_ratio * 100).round();
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      deck.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _ratio.clamp(0, 1)),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, _) => LinearProgressIndicator(
                    minHeight: 8,
                    value: value,
                    backgroundColor:
                        AppColors.secondary.withValues(alpha: 0.5),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$learned of $total cards learned',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
