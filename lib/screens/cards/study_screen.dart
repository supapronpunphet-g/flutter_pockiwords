import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../providers/favorites_provider.dart';
import '../../services/card_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../widgets/flip_card.dart';
import '../../widgets/pocki_button.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({
    super.key,
    required this.deck,
    required this.cards,
    required this.userId,
  });

  final Deck deck;
  final List<Flashcard> cards;
  final String userId;

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final _pageController = PageController();
  final _cardService = CardService();
  final _userService = UserService();
  late final List<Flashcard> _cards = List.of(widget.cards);
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Streak hook: count today as a study day. Idempotent for same day.
    _userService.recordStudyToday(widget.userId);
    // Mark the first card as learned right away — viewing through cards is
    // what fills the deck progress bar, so the moment a card is on screen we
    // count it. Subsequent cards are marked from PageView.onPageChanged.
    if (_cards.isNotEmpty) _markLearnedAt(0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markLearnedAt(int i) async {
    if (i < 0 || i >= _cards.length) return;
    final card = _cards[i];
    if (card.isLearned) return;
    // Optimistically reflect the new state locally so the UI doesn't wait on
    // the network round-trip; Firestore catches up via the deck's stream.
    setState(() {
      _cards[i] =
          card.copyWith(isLearned: true, learnedAt: DateTime.now());
    });
    try {
      await _cardService.setLearned(
        deckId: widget.deck.id,
        cardId: card.id,
        value: true,
      );
    } catch (e) {
      debugPrint('[StudyScreen] setLearned failed: $e');
    }
  }

  void _next() {
    if (_index >= _cards.length - 1) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  void _previous() {
    if (_index == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.deck.title)),
        body: const Center(child: Text('No cards to study yet.')),
      );
    }

    final favs = context.watch<FavoritesProvider>();
    final card = _cards[_index];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Text(
                '${_index + 1} / ${_cards.length}',
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
                  value: (_index + 1) / _cards.length,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.5),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _cards.length,
                onPageChanged: (i) {
                  setState(() => _index = i);
                  _markLearnedAt(i);
                },
                itemBuilder: (_, i) => _StudyCard(card: _cards[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: PockiOutlineButton(
                      label: 'Previous',
                      icon: Icons.chevron_left_rounded,
                      onPressed: _index == 0 ? null : _previous,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _FavoriteToggle(
                    isFavorite: favs.isFavorite(card.id),
                    onPressed: () => favs.toggleFavorite(card),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PockiButton(
                      label: 'Next',
                      icon: Icons.chevron_right_rounded,
                      onPressed:
                          _index == _cards.length - 1 ? null : _next,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                'Tap the card to flip · swipe ← → to navigate',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteToggle extends StatelessWidget {
  const _FavoriteToggle({required this.isFavorite, required this.onPressed});

  final bool isFavorite;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isFavorite
            ? Colors.amber.withValues(alpha: 0.15)
            : AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: isFavorite ? Colors.amber : AppColors.primary,
          width: 1.4,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isFavorite ? Colors.amber : AppColors.primaryDark,
              size: 24,
              semanticLabel:
                  isFavorite ? 'Remove from favorites' : 'Add to favorites',
            ),
          ),
        ),
      ),
    );
  }
}

class _StudyCard extends StatelessWidget {
  const _StudyCard({required this.card});
  final Flashcard card;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: FlipCard(
        front: _FaceFront(card: card),
        back: _FaceBack(card: card),
      ),
    );
  }
}

class _FaceFront extends StatelessWidget {
  const _FaceFront({required this.card});
  final Flashcard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                card.difficulty.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            const Spacer(),
            Text(
              card.frontWord,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_rounded,
                    color: Colors.white70, size: 18),
                SizedBox(width: 6),
                Text(
                  'Tap to flip',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FaceBack extends StatelessWidget {
  const _FaceBack({required this.card});
  final Flashcard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Translation',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              card.backTranslation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (card.exampleSentence.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_quote_rounded,
                        color: AppColors.primaryDark),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        card.exampleSentence,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
