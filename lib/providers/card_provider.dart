import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/flashcard.dart';
import '../services/card_service.dart';
import '../utils/constants.dart';

class CardProvider extends ChangeNotifier {
  CardProvider({CardService? cardService})
      : _cardService = cardService ?? CardService();

  final CardService _cardService;
  StreamSubscription<List<Flashcard>>? _sub;
  String? _userId;
  String? _deckId;

  List<Flashcard> _cards = [];
  bool _loading = false;
  String? _error;
  String _query = '';
  bool _favoritesOnly = false;

  List<Flashcard> get cards => _cards;
  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  bool get favoritesOnly => _favoritesOnly;
  int get learnedCount => _cards.where((c) => c.isLearned).length;
  int get totalCount => _cards.length;
  String? get deckId => _deckId;

  /// Apply the current text + favorites filter against the loaded cards.
  /// Favorite state lives in [FavoritesProvider], so the screen passes
  /// it in here rather than this provider trying to know about it.
  List<Flashcard> applyFilters({required Set<String> favoriteCardIds}) {
    Iterable<Flashcard> list = _cards;
    if (_favoritesOnly) {
      list = list.where((c) => favoriteCardIds.contains(c.id));
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) =>
          c.frontWord.toLowerCase().contains(q) ||
          c.backTranslation.toLowerCase().contains(q) ||
          c.exampleSentence.toLowerCase().contains(q));
    }
    return list.toList();
  }

  void bindContext({required String userId, required String deckId}) {
    if (_userId == userId && _deckId == deckId) return;
    debugPrint(
      '[CardProvider] bindContext userId=$userId deckId=$deckId',
    );
    _userId = userId;
    _deckId = deckId;
    _sub?.cancel();
    _sub = null;

    _loading = true;
    _error = null;
    notifyListeners();

    _sub = _cardService.watchCards(deckId).listen(
      (list) {
        // Sort newest-first in memory — the Firestore query intentionally
        // omits orderBy() so newly-created cards (with pending server
        // timestamps) don't temporarily land at the bottom.
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _cards = list;
        _loading = false;
        debugPrint('[CardProvider] received ${list.length} cards');
        notifyListeners();
      },
      onError: (Object err) {
        debugPrint('[CardProvider] stream error: $err');
        _error = err.toString();
        _loading = false;
        notifyListeners();
      },
    );
  }

  void setQuery(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void setFavoritesOnly(bool value) {
    if (_favoritesOnly == value) return;
    _favoritesOnly = value;
    notifyListeners();
  }

  Future<bool> createCard({
    required String frontWord,
    required String backTranslation,
    required String exampleSentence,
    required CardDifficulty difficulty,
  }) async {
    final uid = _userId;
    final did = _deckId;
    if (uid == null || did == null) {
      _error = 'No active deck. Please reopen the deck and try again.';
      debugPrint(
        '[CardProvider] createCard aborted — uid=$uid deckId=$did',
      );
      notifyListeners();
      return false;
    }
    try {
      await _cardService.createCard(
        userId: uid,
        deckId: did,
        frontWord: frontWord,
        backTranslation: backTranslation,
        exampleSentence: exampleSentence,
        difficulty: difficulty,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('[CardProvider] createCard error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCard({
    required String cardId,
    required String frontWord,
    required String backTranslation,
    required String exampleSentence,
    required CardDifficulty difficulty,
  }) async {
    final did = _deckId;
    if (did == null) return false;
    try {
      await _cardService.updateCard(
        deckId: did,
        cardId: cardId,
        frontWord: frontWord,
        backTranslation: backTranslation,
        exampleSentence: exampleSentence,
        difficulty: difficulty,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCard(String cardId) async {
    final did = _deckId;
    if (did == null) return false;
    try {
      await _cardService.deleteCard(deckId: did, cardId: cardId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
