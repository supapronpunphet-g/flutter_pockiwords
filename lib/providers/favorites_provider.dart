import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/flashcard.dart';
import '../services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider({FavoritesService? favoritesService})
      : _favoritesService = favoritesService ?? FavoritesService();

  final FavoritesService _favoritesService;
  StreamSubscription<List<Flashcard>>? _sub;
  String? _userId;

  List<Flashcard> _favorites = [];
  Set<String> _favoriteCardIds = const {};
  bool _loading = false;
  String? _error;
  String _query = '';

  List<Flashcard> get favorites => _favorites;

  /// IDs of cards the signed-in user has favorited. Other screens use this
  /// to decide whether to show a filled or outlined star next to a card.
  Set<String> get favoriteCardIds => _favoriteCardIds;

  bool isFavorite(String cardId) => _favoriteCardIds.contains(cardId);

  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  int get count => _favorites.length;

  List<Flashcard> get filteredFavorites {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _favorites;
    return _favorites
        .where((c) =>
            c.frontWord.toLowerCase().contains(q) ||
            c.backTranslation.toLowerCase().contains(q) ||
            c.exampleSentence.toLowerCase().contains(q))
        .toList();
  }

  void bindUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _sub?.cancel();
    _sub = null;

    if (userId == null) {
      _favorites = [];
      _favoriteCardIds = const {};
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    _sub = _favoritesService.watchFavoritesForUser(userId).listen(
      (list) {
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _favorites = list;
        _favoriteCardIds = list.map((c) => c.id).toSet();
        _loading = false;
        notifyListeners();
      },
      onError: (Object err) {
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

  /// Add the card to favorites if it isn't, or remove it if it is.
  /// The Firestore listener will update local state — we don't optimistically
  /// mutate `_favoriteCardIds` so the UI never disagrees with what's saved.
  Future<void> toggleFavorite(Flashcard card) async {
    if (_favoriteCardIds.contains(card.id)) {
      await _favoritesService.removeFavorite(
        userId: card.userId,
        cardId: card.id,
      );
    } else {
      await _favoritesService.addFavorite(card);
    }
  }

  Future<void> removeFavorite(Flashcard card) =>
      _favoritesService.removeFavorite(userId: card.userId, cardId: card.id);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
