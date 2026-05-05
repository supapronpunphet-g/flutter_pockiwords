import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/constants.dart';

class GameScore {
  GameScore({
    required this.id,
    required this.userId,
    required this.gameType,
    required this.score,
    required this.deckId,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final GameType gameType;
  final int score;
  final String? deckId;
  final DateTime createdAt;

  factory GameScore.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return GameScore(
      id: doc.id,
      userId: (data['userId'] ?? '') as String,
      gameType: GameType.values.firstWhere(
        (g) => g.name == data['gameType'],
        orElse: () => GameType.multipleChoice,
      ),
      score: (data['score'] ?? 0) as int,
      deckId: data['deckId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
