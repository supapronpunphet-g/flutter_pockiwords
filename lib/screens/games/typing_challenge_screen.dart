import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../providers/game_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/game_result_view.dart';
import '../../widgets/pocki_button.dart';

class TypingChallengeScreen extends StatefulWidget {
  const TypingChallengeScreen({
    super.key,
    required this.deck,
    required this.cards,
  });

  final Deck deck;
  final List<Flashcard> cards;

  @override
  State<TypingChallengeScreen> createState() => _TypingChallengeScreenState();
}

class _TypingChallengeScreenState extends State<TypingChallengeScreen> {
  static const _maxRounds = 10;
  late List<Flashcard> _round;
  final _input = TextEditingController();
  int _index = 0;
  int _correct = 0;
  final List<Flashcard> _wrong = [];
  bool? _lastWasCorrect;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    final pool = List<Flashcard>.from(widget.cards)..shuffle(Random());
    _round = pool.take(min(_maxRounds, pool.length)).toList();
    _index = 0;
    _correct = 0;
    _wrong.clear();
    _lastWasCorrect = null;
    _finished = false;
    _input.clear();
  }

  void _check() {
    if (_input.text.trim().isEmpty) return;
    final card = _round[_index];
    final correct = _input.text.trim().toLowerCase() ==
        card.frontWord.trim().toLowerCase();
    setState(() {
      _lastWasCorrect = correct;
      if (correct) {
        _correct += 1;
      } else {
        _wrong.add(card);
      }
    });
  }

  void _next() {
    if (_index >= _round.length - 1) {
      _finishGame();
      return;
    }
    setState(() {
      _index += 1;
      _input.clear();
      _lastWasCorrect = null;
    });
  }

  Future<void> _finishGame() async {
    setState(() => _finished = true);
    await context.read<GameProvider>().saveScore(
          gameType: GameType.typing,
          score: _correct,
          deckId: widget.deck.id,
        );
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      final wrongList = _wrong.isEmpty
          ? 'No wrong answers — perfect!'
          : 'Words to review: ${_wrong.map((c) => c.frontWord).take(5).join(", ")}'
              '${_wrong.length > 5 ? "…" : ""}';
      return GameResultView(
        gameType: GameType.typing,
        score: _correct,
        maxScore: _round.length,
        subtitle: wrongList,
        onPlayAgain: () => setState(_setup),
        onDone: () => Navigator.of(context).pop(),
      );
    }

    final card = _round[_index];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Typing Challenge'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Text(
                '${_index + 1} / ${_round.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: (_index + 1) / _round.length,
                  backgroundColor:
                      AppColors.secondary.withValues(alpha: 0.5),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB5EAD7), Color(0xFF8FD9C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  children: [
                    const Text(
                      'TYPE THE WORD FOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      card.backTranslation,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _input,
                autofocus: true,
                enabled: _lastWasCorrect == null,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _check(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  hintText: 'Type here…',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_lastWasCorrect == null)
                PockiButton(
                  label: 'Check',
                  icon: Icons.check_rounded,
                  onPressed: _check,
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: (_lastWasCorrect!
                            ? AppColors.success
                            : AppColors.error)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _lastWasCorrect!
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: _lastWasCorrect!
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _lastWasCorrect!
                              ? 'Correct! 🎉'
                              : 'The answer is "${card.frontWord}"',
                          style: TextStyle(
                            color: _lastWasCorrect!
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PockiButton(
                  label: _index >= _round.length - 1 ? 'Finish' : 'Next',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _next,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
