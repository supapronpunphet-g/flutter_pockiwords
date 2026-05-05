import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/deck.dart';
import '../models/flashcard.dart';
import '../providers/auth_provider.dart';
import '../providers/deck_provider.dart';
import '../providers/stats_provider.dart';
import '../utils/constants.dart';
import '../widgets/deck_progress_row.dart';
import '../widgets/stat_tile.dart';
import 'cards/cards_list_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final decks = context.watch<DeckProvider>();
    final stats = context.watch<StatsProvider>();
    final user = auth.appUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PockiWords'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _GreetingHeader(
              username: user?.username,
              streak: user?.streak ?? 0,
              learnedToday: stats.learnedToday,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    value: '${decks.decks.length}',
                    label: 'Decks',
                    icon: Icons.collections_bookmark_rounded,
                    color: AppColors.primary,
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: StatTile(
                    value: '${stats.totalCards}',
                    label: 'Cards',
                    icon: Icons.style_rounded,
                    color: const Color(0xFF8FD9C0),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: 80.ms)
                      .slideY(begin: 0.2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: StatTile(
                    value: '${stats.learnedCards}',
                    label: 'Learned',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFFA1ABDC),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: 160.ms)
                      .slideY(begin: 0.2),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _StreakBigCard(
                    label: 'Current Streak',
                    value: '${user?.streak ?? 0}',
                    icon: Icons.local_fire_department_rounded,
                    gradient: const [Color(0xFFFFB199), Color(0xFFFF7E5F)],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StreakBigCard(
                    label: 'Longest Streak',
                    value: '${user?.longestStreak ?? 0}',
                    icon: Icons.emoji_events_rounded,
                    gradient: const [Color(0xFFFFD86F), Color(0xFFFFA45C)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SectionHeader(
              icon: Icons.bar_chart_rounded,
              title: 'Deck Progress',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildDeckProgress(context, decks.decks, stats),
            const SizedBox(height: AppSpacing.lg),
            const _SectionHeader(
              icon: Icons.history_rounded,
              title: 'Recent Activity',
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildRecentActivity(context, stats, decks),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckProgress(
      BuildContext context, List<Deck> decks, StatsProvider stats) {
    if (decks.isEmpty) {
      return _EmptyHint(
        icon: Icons.collections_bookmark_rounded,
        text: 'No decks yet — create one from the Decks tab!',
      );
    }
    final counts = stats.perDeckCounts;
    return Column(
      children: [
        for (final deck in decks)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: DeckProgressRow(
              deck: deck,
              total: counts[deck.id]?.total ?? 0,
              learned: counts[deck.id]?.learned ?? 0,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => CardsListScreen(deck: deck),
                ));
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context, StatsProvider stats,
      DeckProvider decks) {
    final recents = stats.recentLearnedCards();
    if (recents.isEmpty) {
      return _EmptyHint(
        icon: Icons.school_rounded,
        text: 'Start studying — learned cards will appear here.',
      );
    }
    return Column(
      children: [
        for (final card in recents)
          _RecentActivityRow(
            card: card,
            deckTitle: decks.deckById(card.deckId)?.title ?? '—',
          ),
      ],
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.username,
    required this.streak,
    required this.learnedToday,
  });

  final String? username;
  final int streak;
  final int learnedToday;

  @override
  Widget build(BuildContext context) {
    final name = (username == null || username!.isEmpty) ? 'friend' : username!;
    final headline = streak > 0
        ? 'Day $streak of your streak 🔥'
        : 'Start your streak today! 🌱';
    final subline = learnedToday > 0
        ? "You've learned $learnedToday card${learnedToday == 1 ? '' : 's'} today 💖"
        : 'Tap a deck to start studying.';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $name! 🌸',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  headline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Text('🐰', style: TextStyle(fontSize: 56)),
        ],
      ),
    );
  }
}

class _StreakBigCard extends StatelessWidget {
  const _StreakBigCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryDark, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  const _RecentActivityRow({required this.card, required this.deckTitle});
  final Flashcard card;
  final String deckTitle;

  String get _relativeTime {
    final now = DateTime.now();
    final diff = now.difference(card.activityAt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      TextSpan(text: card.frontWord),
                      const TextSpan(
                        text: '  →  ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextSpan(
                        text: card.backTranslation,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$deckTitle · $_relativeTime',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
