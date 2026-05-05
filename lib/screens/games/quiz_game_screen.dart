import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../providers/game_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/game_result_view.dart';

class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({super.key, required this.deck, required this.cards});

  final Deck deck;
  final List<Flashcard> cards;

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> {
  static const _maxQuestions = 10;
  late List<_Question> _questions;
  int _index = 0;
  int _correct = 0;
  int? _selected;
  bool _showFeedback = false;
  Timer? _advanceTimer;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    final pool = List<Flashcard>.from(widget.cards)..shuffle(Random());
    final picks = pool.take(min(_maxQuestions, pool.length)).toList();
    _questions = picks
        .map((card) => _buildQuestion(card, widget.cards))
        .toList();
    _index = 0;
    _correct = 0;
    _selected = null;
    _showFeedback = false;
    _finished = false;
  }

  static _Question _buildQuestion(Flashcard answer, List<Flashcard> all) {
    final distractors = all
        .where((c) => c.id != answer.id)
        .map((c) => c.backTranslation)
        .toSet()
        .toList()
      ..shuffle(Random());
    final options = <String>[
      answer.backTranslation,
      ...distractors.take(3),
    ]..shuffle(Random());
    final correctIndex = options.indexOf(answer.backTranslation);
    return _Question(
      prompt: answer.frontWord,
      options: options,
      correctIndex: correctIndex,
    );
  }

  void _onPick(int i) {
    if (_showFeedback) return;
    setState(() {
      _selected = i;
      _showFeedback = true;
      if (i == _questions[_index].correctIndex) _correct += 1;
    });
    _advanceTimer = Timer(const Duration(milliseconds: 900), _advance);
  }

  void _advance() {
    if (!mounted) return;
    if (_index >= _questions.length - 1) {
      _finishGame();
      return;
    }
    setState(() {
      _index += 1;
      _selected = null;
      _showFeedback = false;
    });
  }

  Future<void> _finishGame() async {
    setState(() => _finished = true);
    await context.read<GameProvider>().saveScore(
          gameType: GameType.multipleChoice,
          score: _correct,
          deckId: widget.deck.id,
        );
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return GameResultView(
        gameType: GameType.multipleChoice,
        score: _correct,
        maxScore: _questions.length,
        subtitle: 'You answered $_correct out of ${_questions.length}.',
        onPlayAgain: () => setState(_setup),
        onDone: () => Navigator.of(context).pop(),
      );
    }

    final q = _questions[_index];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiple Choice'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Text(
                '${_index + 1} / ${_questions.length}',
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
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: (_index + 1) / _questions.length,
                  backgroundColor:
                      AppColors.secondary.withValues(alpha: 0.5),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
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
                    colors: [AppColors.secondary, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  children: [
                    const Text(
                      'What does this mean?',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      q.prompt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
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
                itemCount: q.options.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => _OptionTile(
                  text: q.options[i],
                  state: _stateFor(i, q.correctIndex),
                  onTap: () => _onPick(i),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _OptionState _stateFor(int i, int correct) {
    if (!_showFeedback) return _OptionState.idle;
    if (i == correct) return _OptionState.correct;
    if (i == _selected) return _OptionState.wrong;
    return _OptionState.faded;
  }
}

enum _OptionState { idle, correct, wrong, faded }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (state) {
      _OptionState.idle => (
          AppColors.surface,
          AppColors.textPrimary,
          AppColors.secondary.withValues(alpha: 0.6),
        ),
      _OptionState.correct => (
          AppColors.success,
          Colors.white,
          AppColors.success,
        ),
      _OptionState.wrong => (
          AppColors.error,
          Colors.white,
          AppColors.error,
        ),
      _OptionState.faded => (
          AppColors.surface,
          AppColors.textSecondary,
          AppColors.secondary.withValues(alpha: 0.4),
        ),
    };
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: state == _OptionState.idle ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 1.4),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (state == _OptionState.correct)
                const Icon(Icons.check_circle_rounded, color: Colors.white),
              if (state == _OptionState.wrong)
                const Icon(Icons.close_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _Question {
  _Question({
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });
  final String prompt;
  final List<String> options;
  final int correctIndex;
}
