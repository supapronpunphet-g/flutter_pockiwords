import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../models/flashcard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/card_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/flashcard_list_tile.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/pocki_button.dart';
import '../games/games_hub_screen.dart';
import 'card_form_screen.dart';
import 'study_screen.dart';

class CardsListScreen extends StatelessWidget {
  const CardsListScreen({super.key, required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CardProvider>(
      create: (_) => CardProvider(),
      child: _CardsListBody(deck: deck),
    );
  }
}

class _CardsListBody extends StatefulWidget {
  const _CardsListBody({required this.deck});
  final Deck deck;

  @override
  State<_CardsListBody> createState() => _CardsListBodyState();
}

class _CardsListBodyState extends State<_CardsListBody> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    debugPrint(
      '[CardsList] mounted for deck ${widget.deck.id} ("${widget.deck.title}")',
    );
    // Defer bindContext to the next frame so notifyListeners doesn't fire
    // while descendant widgets are still building. bindContext itself
    // de-dupes by (userId, deckId) so re-running is harmless.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = context.read<AuthProvider>().firebaseUser?.uid;
      if (uid != null) {
        context.read<CardProvider>().bindContext(
              userId: uid,
              deckId: widget.deck.id,
            );
      } else {
        debugPrint('[CardsList] no auth uid — skipping bindContext');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(Flashcard card) async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = context.read<CardProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Delete card?'),
        content: Text('"${card.frontWord}" will be removed permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await provider.deleteCard(card.id);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(success ? 'Card deleted' : 'Could not delete card'),
    ));
  }

  void _openForm({Flashcard? card}) {
    final provider = context.read<CardProvider>();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: CardFormScreen(card: card),
      ),
    ));
  }

  void _startStudy() {
    final provider = context.read<CardProvider>();
    final auth = context.read<AuthProvider>();
    final uid = auth.firebaseUser?.uid;
    if (uid == null) return;
    final cards = provider.cards;
    if (cards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some cards first!')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => StudyScreen(
        deck: widget.deck,
        cards: cards,
        userId: uid,
      ),
    ));
  }

  void _openGames() {
    final provider = context.read<CardProvider>();
    debugPrint(
      '[CardsList] open games hub for deck ${widget.deck.id} '
      '(${provider.cards.length} cards)',
    );
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GamesHubScreen(
        deck: widget.deck,
        cards: provider.cards,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardProvider>();
    final favs = context.watch<FavoritesProvider>();
    final hasCards = provider.cards.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(widget.deck.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Card'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Big Study + Games entry-points live in the body (not the
            // app bar) so they're impossible to miss once a deck has cards.
            // Hidden when the deck is empty — there's nothing to study yet.
            if (hasCards)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: PockiButton(
                        label: 'Study Mode',
                        icon: Icons.school_rounded,
                        onPressed: _startStudy,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: PockiOutlineButton(
                        label: 'Games',
                        icon: Icons.videogame_asset_rounded,
                        onPressed: _openGames,
                      ),
                    ),
                  ],
                ),
              ),
            if (hasCards)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.style_rounded,
                      size: 14,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${provider.cards.length} '
                      '${provider.cards.length == 1 ? "card" : "cards"}'
                      ' · ${provider.learnedCount} learned',
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            _SearchBar(
              controller: _searchController,
              onChanged: provider.setQuery,
              favoritesOnly: provider.favoritesOnly,
              onFavoritesToggle: () =>
                  provider.setFavoritesOnly(!provider.favoritesOnly),
            ),
            Expanded(child: _buildList(provider, favs)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(CardProvider provider, FavoritesProvider favs) {
    if (provider.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (provider.error != null) {
      return EmptyView(
        icon: Icons.error_outline_rounded,
        title: 'Could not load cards',
        message: provider.error,
      );
    }
    final filtered =
        provider.applyFilters(favoriteCardIds: favs.favoriteCardIds);
    if (provider.cards.isEmpty) {
      return EmptyView(
        icon: Icons.style_rounded,
        title: 'No cards yet',
        message: 'Add your first card to start learning!',
        action: PockiButton(
          label: 'Add Card',
          icon: Icons.add_rounded,
          fullWidth: false,
          onPressed: () => _openForm(),
        ),
      );
    }
    if (filtered.isEmpty) {
      return const EmptyView(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'Try a different search or clear the favorites filter.',
      );
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => Future<void>.delayed(const Duration(milliseconds: 400)),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          100, // FAB breathing room
        ),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) {
          final card = filtered[i];
          return FlashcardListTile(
            card: card,
            isFavorite: favs.isFavorite(card.id),
            onTap: () => _openForm(card: card),
            onEdit: () => _openForm(card: card),
            onDelete: () => _confirmDelete(card),
            onToggleFavorite: () => favs.toggleFavorite(card),
          );
        },
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.favoritesOnly,
    required this.onFavoritesToggle,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool favoritesOnly;
  final VoidCallback onFavoritesToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search cards…',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Material(
            color: favoritesOnly
                ? AppColors.primary
                : AppColors.secondary.withValues(alpha: 0.5),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onFavoritesToggle,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  favoritesOnly ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: favoritesOnly ? Colors.white : AppColors.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
