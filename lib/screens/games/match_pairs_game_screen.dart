import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../providers/game_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/game_result_view.dart';

class MatchPairsGameScreen extends StatefulWidget {
  const MatchPairsGameScreen({
    super.key,
    required this.deck,
    required this.cards,
  });

  final Deck deck;
  final List<Flashcard> cards;

  @override
  State<MatchPairsGameScreen> createState() => _MatchPairsGameScreenState();
}

class _MatchPairsGameScreenState extends State<MatchPairsGameScreen> {
  static const _maxPairs = 6;
  late List<Flashcard> _round;
  late List<_Side> _left;
  late List<_Side> _right;
  String? _selectedLeftId;
  int _correct = 0;
  int _wrong = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _setupRound();
  }

  void _setupRound() {
    final pool = List<Flashcard>.from(widget.cards)..shuffle(Random());
    _round = pool.take(min(_maxPairs, pool.length)).toList();
    _left = _round
        .map((c) => _Side(pairId: c.id, text: c.frontWord))
        .toList()
      ..shuffle(Random());
    _right = _round
        .map((c) => _Side(pairId: c.id, text: c.backTranslation))
        .toList()
      ..shuffle(Random());
    _selectedLeftId = null;
    _correct = 0;
    _wrong = 0;
    _finished = false;
  }

  void _onLeftTap(_Side s) {
    if (s.matched) return;
    setState(() {
      // Tapping the same left tile again deselects it (toggle UX).
      _selectedLeftId = (_selectedLeftId == s.pairId) ? null : s.pairId;
    });
  }

  void _onRightTap(_Side r) {
    if (r.matched) return;
    final leftId = _selectedLeftId;
    if (leftId == null) return;

    if (leftId == r.pairId) {
      setState(() {
        _left.firstWhere((e) => e.pairId == leftId).matched = true;
        r.matched = true;
        _selectedLeftId = null;
        _correct += 1;
        if (_left.every((e) => e.matched)) _finishGame();
      });
    } else {
      // Clear the left selection IMMEDIATELY so a quick second tap on
      // another right tile during the 350ms flash doesn't accidentally
      // re-evaluate against a stale leftId.
      setState(() {
        r.flashWrong = true;
        _wrong += 1;
        _selectedLeftId = null;
      });
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() => r.flashWrong = false);
      });
    }
  }

  Future<void> _finishGame() async {
    setState(() => _finished = true);
    // score: pairs solved minus penalty for wrong attempts (floor at 0)
    final score = (_correct * 10 - _wrong * 2).clamp(0, 1 << 30);
    await context.read<GameProvider>().saveScore(
          gameType: GameType.matchPairs,
          score: score,
          deckId: widget.deck.id,
        );
  }

  void _playAgain() {
    setState(_setupRound);
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      final score = (_correct * 10 - _wrong * 2).clamp(0, 1 << 30);
      return GameResultView(
        gameType: GameType.matchPairs,
        score: score,
        subtitle: 'Pairs matched: $_correct · Wrong attempts: $_wrong',
        onPlayAgain: _playAgain,
        onDone: () => Navigator.of(context).pop(),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Pairs'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Text(
                '$_correct / ${_round.length}',
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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _Column(
                  items: _left,
                  selectedId: _selectedLeftId,
                  side: _ColumnSide.left,
                  onTap: _onLeftTap,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _Column(
                  items: _right,
                  selectedId: null,
                  side: _ColumnSide.right,
                  onTap: _onRightTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Side {
  _Side({required this.pairId, required this.text});
  final String pairId;
  final String text;
  bool matched = false;
  bool flashWrong = false;
}

enum _ColumnSide { left, right }

class _Column extends StatelessWidget {
  const _Column({
    required this.items,
    required this.selectedId,
    required this.side,
    required this.onTap,
  });

  final List<_Side> items;
  final String? selectedId;
  final _ColumnSide side;
  final ValueChanged<_Side> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final item in items)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _Tile(
                item: item,
                side: side,
                selected: item.pairId == selectedId,
                onTap: () => onTap(item),
              ),
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.item,
    required this.side,
    required this.selected,
    required this.onTap,
  });

  final _Side item;
  final _ColumnSide side;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final base = side == _ColumnSide.left
        ? AppColors.primary
        : AppColors.accentAlt;
    Color bg;
    if (item.matched) {
      bg = AppColors.success.withValues(alpha: 0.85);
    } else if (item.flashWrong) {
      bg = AppColors.error.withValues(alpha: 0.85);
    } else if (selected) {
      bg = base;
    } else {
      bg = base.withValues(alpha: 0.25);
    }
    final fg = (item.matched || item.flashWrong || selected)
        ? Colors.white
        : AppColors.textPrimary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          if (selected || item.matched)
            BoxShadow(
              color: bg.withValues(alpha: 0.45),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.matched ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: Text(
                item.text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
