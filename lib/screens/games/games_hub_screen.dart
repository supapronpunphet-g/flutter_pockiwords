import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../providers/game_provider.dart';
import '../../utils/constants.dart';
import 'match_pairs_game_screen.dart';
import 'memory_flip_game_screen.dart';
import 'quiz_game_screen.dart';
import 'speed_rush_game_screen.dart';
import 'typing_challenge_screen.dart';

class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key, required this.deck, required this.cards});

  final Deck deck;
  final List<Flashcard> cards;

  static const _minCards = 4;

  bool get _hasEnough => cards.length >= _minCards;

  void _launch(BuildContext context, GameType type) {
    debugPrint(
      '[GamesHub] launching ${type.name} for deck ${deck.id} '
      '(${cards.length} cards)',
    );
    if (!_hasEnough) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please add at least 4 cards to play this game.'),
        ),
      );
      return;
    }
    final builder = switch (type) {
      GameType.matchPairs => (_) => MatchPairsGameScreen(deck: deck, cards: cards),
      GameType.multipleChoice => (_) => QuizGameScreen(deck: deck, cards: cards),
      GameType.typing => (_) => TypingChallengeScreen(deck: deck, cards: cards),
      GameType.memoryFlip => (_) => MemoryFlipGameScreen(deck: deck, cards: cards),
      GameType.speedRush => (_) => SpeedRushGameScreen(deck: deck, cards: cards),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: builder));
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    return Scaffold(
      appBar: AppBar(title: Text('Games · ${deck.title}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (!_hasEnough)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Please add at least $_minCards cards to play these '
                        'games. You currently have ${cards.length}.',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Text(
              'Pick a game',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final type in GameType.values) ...[
              _GameTile(
                type: type,
                disabled: !_hasEnough,
                bestScore: gameProvider.bestScore(type),
                onTap: () => _launch(context, type),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.type,
    required this.disabled,
    required this.bestScore,
    required this.onTap,
  });

  final GameType type;
  final bool disabled;
  final int bestScore;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: type.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: type.gradient.last.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(type.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        type.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      if (bestScore > 0) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'Best · $bestScore',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
