import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/flashcard.dart';
import '../providers/deck_provider.dart';
import '../providers/favorites_provider.dart';
import '../utils/constants.dart';
import '../widgets/loading_view.dart';
import 'cards/cards_list_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openDeck(Flashcard card) {
    final deck = context.read<DeckProvider>().deckById(card.deckId);
    if (deck == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CardsListScreen(deck: deck),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final favs = context.watch<FavoritesProvider>();
    final decks = context.watch<DeckProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: favs.setQuery,
                decoration: InputDecoration(
                  hintText: 'Search favorites…',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.primary),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            favs.setQuery('');
                          },
                        ),
                ),
              ),
            ),
            Expanded(child: _buildList(favs, decks)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(FavoritesProvider favs, DeckProvider decks) {
    if (favs.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (favs.error != null) {
      return EmptyView(
        icon: Icons.error_outline_rounded,
        title: 'Could not load favorites',
        message: favs.error,
      );
    }
    if (favs.favorites.isEmpty) {
      return const EmptyView(
        icon: Icons.star_outline_rounded,
        title: 'No favorites yet',
        message: 'Tap the star on a flashcard to save it here.',
      );
    }
    final filtered = favs.filteredFavorites;
    if (filtered.isEmpty) {
      return const EmptyView(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'Try a different search term.',
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => Future<void>.delayed(const Duration(milliseconds: 400)),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.lg,
        ),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, i) {
          final card = filtered[i];
          final deckTitle =
              decks.deckById(card.deckId)?.title ?? 'Unknown deck';
          return _FavoriteTile(
            card: card,
            deckTitle: deckTitle,
            onTap: () => _openDeck(card),
            onRemove: () => favs.removeFavorite(card),
          );
        },
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.card,
    required this.deckTitle,
    required this.onTap,
    required this.onRemove,
  });

  final Flashcard card;
  final String deckTitle;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.6),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded,
                    color: Colors.amber, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      card.frontWord,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      card.backTranslation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.collections_bookmark_rounded,
                          size: 12,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            deckTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: 'Remove from favorites',
                icon: const Icon(Icons.star_rounded, color: Colors.amber),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
