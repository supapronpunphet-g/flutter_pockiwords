import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/deck.dart';
import '../../providers/deck_provider.dart';
import '../../providers/stats_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/deck_card.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/pocki_button.dart';
import '../cards/cards_list_screen.dart';
import 'deck_form_screen.dart';

class DecksListScreen extends StatelessWidget {
  const DecksListScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, Deck deck) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Delete deck?'),
        content: Text(
          'This will permanently remove "${deck.title}" and all its flashcards.',
        ),
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
    if (confirmed != true) return;
    if (!context.mounted) return;
    final ok = await context.read<DeckProvider>().deleteDeck(deck.id);
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? 'Deck deleted' : 'Could not delete deck'),
    ));
  }

  void _openForm(BuildContext context, {Deck? deck}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DeckFormScreen(deck: deck),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeckProvider>();
    final stats = context.watch<StatsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('My Decks')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Deck'),
      ),
      body: SafeArea(
        child: _buildBody(context, provider, stats),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, DeckProvider provider, StatsProvider stats) {
    if (provider.loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (provider.error != null) {
      return EmptyView(
        icon: Icons.error_outline_rounded,
        title: 'Could not load decks',
        message: provider.error,
      );
    }
    if (provider.decks.isEmpty) {
      return EmptyView(
        icon: Icons.collections_bookmark_rounded,
        title: 'No decks yet',
        message: 'Create your first flashcard deck to start learning!',
        action: PockiButton(
          label: 'Create Deck',
          icon: Icons.add_rounded,
          fullWidth: false,
          onPressed: () => _openForm(context),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      // Streams are real-time, so a brief delay is just for visual feedback —
      // the list will already be in sync.
      onRefresh: () => Future<void>.delayed(const Duration(milliseconds: 400)),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          100, // breathing room above FAB
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 0.85,
        ),
        itemCount: provider.decks.length,
        itemBuilder: (_, i) {
          final deck = provider.decks[i];
          // perDeckCounts comes from the user's full card stream — decks
          // with zero cards just don't appear in the map, so default to 0.
          final cardCount = stats.perDeckCounts[deck.id]?.total ?? 0;
          return DeckCard(
            deck: deck,
            cardCount: cardCount,
            onTap: () {
              debugPrint(
                '[DecksList] tapped deck ${deck.id} ("${deck.title}")',
              );
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CardsListScreen(deck: deck),
              ));
            },
            onEdit: () => _openForm(context, deck: deck),
            onDelete: () => _confirmDelete(context, deck),
          );
        },
      ),
    );
  }
}
