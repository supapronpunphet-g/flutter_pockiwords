import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/deck.dart';
import '../models/flashcard.dart';
import '../services/card_service.dart';
import '../services/deck_service.dart';

typedef DeckCounts = ({int total, int learned});

/// Aggregates user-wide card stats for the home dashboard.
///
/// Implementation: watch the user's decks, then for every deck open a
/// subscription on its `cards` subcollection. Aggregate into per-deck maps.
///
/// We deliberately avoid `collectionGroup('cards')` because it requires
/// an explicit single-field index on `userId` plus a `match /{path=**}/cards`
/// security rule — both of which silently break the dashboard when missing.
/// Per-deck queries reuse the exact same path the deck-detail screen uses,
/// so if cards work in a deck they'll show up in the dashboard too.
class StatsProvider extends ChangeNotifier {
  StatsProvider({CardService? cardService, DeckService? deckService})
      : _cardService = cardService ?? CardService(),
        _deckService = deckService ?? DeckService();

  final CardService _cardService;
  final DeckService _deckService;

  StreamSubscription<List<Deck>>? _deckSub;
  final Map<String, StreamSubscription<List<Flashcard>>> _cardSubs = {};
  final Map<String, List<Flashcard>> _cardsByDeck = {};

  String? _userId;
  bool _loading = false;
  String? _error;

  bool get loading => _loading;
  String? get error => _error;

  List<Flashcard> get allCards =>
      _cardsByDeck.values.expand((c) => c).toList(growable: false);

  int get totalCards => allCards.length;
  int get learnedCards => allCards.where((c) => c.isLearned).length;
  double get learnedRatio => totalCards == 0 ? 0 : learnedCards / totalCards;

  int get learnedToday {
    final today = _dateOnly(DateTime.now());
    return allCards
        .where((c) =>
            c.isLearned &&
            c.learnedAt != null &&
            _dateOnly(c.learnedAt!) == today)
        .length;
  }

  Map<String, DeckCounts> get perDeckCounts {
    return _cardsByDeck.map((deckId, cards) => MapEntry(
          deckId,
          (
            total: cards.length,
            learned: cards.where((c) => c.isLearned).length,
          ),
        ));
  }

  /// Most recently learned cards across all decks. Falls back to createdAt
  /// for cards that pre-date the learnedAt field.
  List<Flashcard> recentLearnedCards({int limit = 5}) {
    final learned = allCards.where((c) => c.isLearned).toList()
      ..sort((a, b) => b.activityAt.compareTo(a.activityAt));
    if (learned.length <= limit) return learned;
    return learned.sublist(0, limit);
  }

  void bindUser(String? userId) {
    if (_userId == userId) return;
    debugPrint('[StatsProvider] bindUser uid=$userId');
    _userId = userId;
    _cancelAll();

    if (userId == null) {
      _loading = false;
      _error = null;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    _deckSub = _deckService.watchDecks(userId).listen(
      _onDecks,
      onError: (Object err) {
        debugPrint('[StatsProvider] decks stream error: $err');
        _error = err.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  void _onDecks(List<Deck> decks) {
    final newIds = decks.map((d) => d.id).toSet();
    final currentIds = _cardSubs.keys.toSet();

    // Drop subscriptions for decks the user just deleted.
    for (final id in currentIds.difference(newIds)) {
      _cardSubs[id]?.cancel();
      _cardSubs.remove(id);
      _cardsByDeck.remove(id);
    }

    // Subscribe to cards in decks we haven't seen yet.
    for (final id in newIds.difference(currentIds)) {
      _cardSubs[id] = _cardService.watchCards(id).listen(
        (cards) {
          _cardsByDeck[id] = cards;
          _loading = false;
          debugPrint(
            '[StatsProvider] deck $id → ${cards.length} cards '
            '(total now $totalCards)',
          );
          notifyListeners();
        },
        onError: (Object err) {
          // One bad subcollection shouldn't break the whole dashboard.
          // Other decks keep flowing through.
          debugPrint('[StatsProvider] cards stream error deck=$id: $err');
        },
      );
    }

    if (decks.isEmpty) _loading = false;
    notifyListeners();
  }

  void _cancelAll() {
    _deckSub?.cancel();
    _deckSub = null;
    for (final sub in _cardSubs.values) {
      sub.cancel();
    }
    _cardSubs.clear();
    _cardsByDeck.clear();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }
}
