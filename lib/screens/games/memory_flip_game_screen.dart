import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../providers/game_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/game_result_view.dart';

class MemoryFlipGameScreen extends StatefulWidget {
  const MemoryFlipGameScreen({
    super.key,
    required this.deck,
    required this.cards,
  });

  final Deck deck;
  final List<Flashcard> cards;

  @override
  State<MemoryFlipGameScreen> createState() => _MemoryFlipGameScreenState();
}

class _MemoryFlipGameScreenState extends State<MemoryFlipGameScreen> {
  static const _maxPairs = 6;
  late List<_Tile> _tiles;
  _Tile? _firstFlip;
  bool _busy = false;
  int _moves = 0;
  int _matchedPairs = 0;
  late DateTime _started;
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    final pool = List<Flashcard>.from(widget.cards)..shuffle(Random());
    final picks = pool.take(min(_maxPairs, pool.length)).toList();
    _tiles = [
      for (final c in picks) ...[
        _Tile(pairId: c.id, text: c.frontWord, isFront: true),
        _Tile(pairId: c.id, text: c.backTranslation, isFront: false),
      ]
    ]..shuffle(Random());
    _firstFlip = null;
    _busy = false;
    _moves = 0;
    _matchedPairs = 0;
    _finished = false;
    _started = DateTime.now();
    _elapsed = Duration.zero;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(_started));
    });
  }

  void _onTileTap(_Tile t) {
    if (_busy || t.matched || t.flipped) return;
    setState(() => t.flipped = true);
    final first = _firstFlip;
    if (first == null) {
      _firstFlip = t;
      return;
    }
    setState(() => _moves += 1);
    if (first.pairId == t.pairId && first.isFront != t.isFront) {
      // match
      setState(() {
        first.matched = true;
        t.matched = true;
        _firstFlip = null;
        _matchedPairs += 1;
        if (_matchedPairs == _tiles.length ~/ 2) _finishGame();
      });
    } else {
      _busy = true;
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          first.flipped = false;
          t.flipped = false;
          _firstFlip = null;
          _busy = false;
        });
      });
    }
  }

  Future<void> _finishGame() async {
    _ticker?.cancel();
    setState(() => _finished = true);
    final pairs = _tiles.length ~/ 2;
    // score = (perfect_moves baseline / actual moves) * 100, clamped
    final score = ((pairs / max(_moves, pairs)) * 100).round();
    await context.read<GameProvider>().saveScore(
          gameType: GameType.memoryFlip,
          score: score,
          deckId: widget.deck.id,
        );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      final pairs = _tiles.length ~/ 2;
      final score = ((pairs / max(_moves, pairs)) * 100).round();
      return GameResultView(
        gameType: GameType.memoryFlip,
        score: score,
        subtitle: 'Solved in $_moves moves · ${_fmt(_elapsed)}',
        onPlayAgain: () => setState(_setup),
        onDone: () => Navigator.of(context).pop(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Flip'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Text(
                'Moves $_moves · ${_fmt(_elapsed)}',
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
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.85,
            ),
            itemCount: _tiles.length,
            itemBuilder: (_, i) => _MemoryTile(
              tile: _tiles[i],
              onTap: () => _onTileTap(_tiles[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tile {
  _Tile({required this.pairId, required this.text, required this.isFront});
  final String pairId;
  final String text;
  final bool isFront;
  bool flipped = false;
  bool matched = false;
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.tile, required this.onTap});
  final _Tile tile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showFace = tile.flipped || tile.matched;
    final List<Color> back = const [
      AppColors.secondary,
      AppColors.primary,
    ];
    final List<Color> face = tile.isFront
        ? const [Color(0xFFFFB199), Color(0xFFFF7E5F)]
        : const [Color(0xFFC7CEEA), Color(0xFFA1ABDC)];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: showFace ? face : back,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: tile.matched
            ? Border.all(color: AppColors.success, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: tile.matched ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Center(
              child: showFace
                  ? Text(
                      tile.text,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    )
                  : const Text('🐰',
                      style: TextStyle(fontSize: 28)),
            ),
          ),
        ),
      ),
    );
  }
}
