import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/deck.dart';
import '../services/deck_service.dart';

class DeckProvider extends ChangeNotifier {
  DeckProvider({DeckService? deckService})
      : _deckService = deckService ?? DeckService();

  final DeckService _deckService;
  StreamSubscription<List<Deck>>? _sub;
  String? _userId;

  List<Deck> _decks = [];
  bool _loading = false;
  String? _error;

  List<Deck> get decks => _decks;
  bool get loading => _loading;
  String? get error => _error;
  String? get userId => _userId;

  /// Subscribe to the current user's decks. Pass null on logout to clear.
  void bindUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _sub?.cancel();
    _sub = null;

    if (userId == null) {
      _decks = [];
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    _sub = _deckService.watchDecks(userId).listen(
      (list) {
        _decks = list;
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

  Future<bool> createDeck({
    required String title,
    required String language,
    required String description,
  }) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      await _deckService.createDeck(
        userId: uid,
        title: title,
        language: language,
        description: description,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDeck({
    required String deckId,
    required String title,
    required String language,
    required String description,
  }) async {
    try {
      await _deckService.updateDeck(
        deckId: deckId,
        title: title,
        language: language,
        description: description,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDeck(String deckId) async {
    final uid = _userId;
    if (uid == null) return false;
    try {
      await _deckService.deleteDeck(userId: uid, deckId: deckId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Deck? deckById(String id) {
    for (final d in _decks) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
