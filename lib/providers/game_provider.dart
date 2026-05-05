import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/game_score.dart';
import '../services/score_service.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';

class GameProvider extends ChangeNotifier {
  GameProvider({ScoreService? scoreService, UserService? userService})
      : _scoreService = scoreService ?? ScoreService(),
        _userService = userService ?? UserService();

  final ScoreService _scoreService;
  final UserService _userService;
  StreamSubscription<List<GameScore>>? _sub;
  String? _userId;

  List<GameScore> _scores = [];
  bool _saving = false;

  List<GameScore> get scores => _scores;
  bool get saving => _saving;

  /// Best score for a given game type (across decks). 0 when no scores yet.
  int bestScore(GameType type) {
    final filtered = _scores.where((s) => s.gameType == type);
    if (filtered.isEmpty) return 0;
    return filtered.map((s) => s.score).reduce((a, b) => a > b ? a : b);
  }

  void bindUser(String? userId) {
    if (_userId == userId) return;
    debugPrint('[GameProvider] bindUser uid=$userId');
    _userId = userId;
    _sub?.cancel();
    _sub = null;
    if (userId == null) {
      _scores = [];
      notifyListeners();
      return;
    }
    _sub = _scoreService.watchUserScores(userId).listen(
      (list) {
        _scores = list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      },
      onError: (Object err) {
        debugPrint('[GameProvider] stream error: $err');
      },
    );
  }

  Future<bool> saveScore({
    required GameType gameType,
    required int score,
    String? deckId,
  }) async {
    final uid = _userId;
    if (uid == null) return false;
    _saving = true;
    notifyListeners();
    try {
      debugPrint(
        '[GameProvider] saveScore game=${gameType.name} score=$score deck=$deckId',
      );
      await _scoreService.saveScore(
        userId: uid,
        gameType: gameType,
        score: score,
        deckId: deckId,
      );
      // Finishing a game counts as studying — bump the streak alongside the
      // score. Fire-and-forget; a streak failure shouldn't fail the score.
      unawaited(_userService.recordStudyToday(uid));
      return true;
    } catch (e) {
      debugPrint('[GameProvider] saveScore failed: $e');
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
