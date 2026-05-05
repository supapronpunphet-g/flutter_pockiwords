import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../providers/game_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/game_result_view.dart';

class SpeedRushGameScreen extends StatefulWidget {
  const SpeedRushGameScreen({
    super.key,
    required this.deck,
    required this.cards,
  });

  final Deck deck;
  final List<Flashcard> cards;

  @override
  State<SpeedRushGameScreen> createState() => _SpeedRushGameScreenState();
}

class _SpeedRushGameScreenState extends State<SpeedRushGameScreen> {
  static const _seconds = 30;

  Timer? _timer;
  int _remaining = _seconds;
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _finished = false;

  late Flashcard _current;
  late List<String> _options;
  late int _correctIndex;
  int? _selected;
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    _newQuestion();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining -= 1;
        if (_remaining <= 0) _finishGame();
      });
    });
  }

  void _newQuestion() {
    final pool = List<Flashcard>.from(widget.cards)..shuffle(Random());
    _current = pool.first;
    final distractors = pool
        .skip(1)
        .map((c) => c.backTranslation)
        .toSet()
        .toList()
      ..shuffle(Random());
    _options = <String>[
      _current.backTranslation,
      ...distractors.take(3),
    ]..shuffle(Random());
    _correctIndex = _options.indexOf(_current.backTranslation);
    _selected = null;
    _locked = false;
  }

  void _onPick(int i) {
    if (_locked || _finished) return;
    setState(() {
      _selected = i;
      _locked = true;
      if (i == _correctIndex) {
        _streak += 1;
        _bestStreak = max(_bestStreak, _streak);
        // base 1 + streak bonus (capped) for combo feel
        _score += 1 + (_streak >= 3 ? 1 : 0) + (_streak >= 6 ? 2 : 0);
      } else {
        _streak = 0;
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || _finished) return;
      setState(_newQuestion);
    });
  }

  Future<void> _finishGame() async {
    if (_finished) return;
    _timer?.cancel();
    setState(() => _finished = true);
    await context.read<GameProvider>().saveScore(
          gameType: GameType.speedRush,
          score: _score,
          deckId: widget.deck.id,
        );
  }

  void _restart() {
    _timer?.cancel();
    setState(() {
      _remaining = _seconds;
      _score = 0;
      _streak = 0;
      _bestStreak = 0;
      _finished = false;
      _newQuestion();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining -= 1;
        if (_remaining <= 0) _finishGame();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return GameResultView(
        gameType: GameType.speedRush,
        score: _score,
        subtitle: 'Best streak: $_bestStreak ⚡',
        onPlayAgain: _restart,
        onDone: () => Navigator.of(context).pop(),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speed Rush'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Text(
                '⏱  $_remaining s',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: _remaining / _seconds,
                  backgroundColor:
                      AppColors.secondary.withValues(alpha: 0.5),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  _Pill(
                    icon: Icons.star_rounded,
                    text: 'Score $_score',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _Pill(
                    icon: Icons.bolt_rounded,
                    text: 'Streak $_streak',
                    color: const Color(0xFFFFA45C),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD86F), Color(0xFFFFA45C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  children: [
                    const Text(
                      'TRANSLATE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _current.frontWord,
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
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: _options.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final isCorrect = _locked && i == _correctIndex;
                  final isWrong = _locked && i == _selected && i != _correctIndex;
                  Color bg = AppColors.surface;
                  Color fg = AppColors.textPrimary;
                  if (isCorrect) {
                    bg = AppColors.success;
                    fg = Colors.white;
                  } else if (isWrong) {
                    bg = AppColors.error;
                    fg = Colors.white;
                  }
                  return Material(
                    color: bg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      onTap: _locked ? null : () => _onPick(i),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: bg == AppColors.surface
                                ? AppColors.secondary.withValues(alpha: 0.6)
                                : bg,
                            width: 1.4,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          _options[i],
                          style: TextStyle(
                            color: fg,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
