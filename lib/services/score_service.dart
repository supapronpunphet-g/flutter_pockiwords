import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/game_score.dart';
import '../utils/constants.dart';

class ScoreService {
  ScoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _scores =>
      _firestore.collection(FirestoreCollections.scores);

  Future<String> saveScore({
    required String userId,
    required GameType gameType,
    required int score,
    String? deckId,
  }) async {
    final ref = await _scores.add({
      'userId': userId,
      'gameType': gameType.name,
      'score': score,
      'deckId': ?deckId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// All scores for a user. We omit orderBy to avoid composite-index needs;
  /// caller can sort in Dart.
  Stream<List<GameScore>> watchUserScores(String userId) {
    return _scores
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map(GameScore.fromFirestore).toList());
  }
}
