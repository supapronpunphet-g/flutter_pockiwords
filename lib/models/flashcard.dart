import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/constants.dart';

class Flashcard {
  Flashcard({
    required this.id,
    required this.userId,
    required this.deckId,
    required this.frontWord,
    required this.backTranslation,
    required this.exampleSentence,
    required this.difficulty,
    required this.isLearned,
    required this.createdAt,
    this.learnedAt,
  });

  final String id;
  final String userId;
  final String deckId;
  final String frontWord;
  final String backTranslation;
  final String exampleSentence;
  final CardDifficulty difficulty;
  final bool isLearned;
  final DateTime createdAt;
  final DateTime? learnedAt;

  /// Best-effort timestamp for sorting "recent activity": learnedAt if we have
  /// it, else createdAt.
  DateTime get activityAt => learnedAt ?? createdAt;

  factory Flashcard.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Flashcard(
      id: doc.id,
      userId: (data['userId'] ?? '') as String,
      deckId: (data['deckId'] ?? '') as String,
      frontWord: (data['frontWord'] ?? '') as String,
      backTranslation: (data['backTranslation'] ?? '') as String,
      exampleSentence: (data['exampleSentence'] ?? '') as String,
      difficulty: CardDifficultyX.fromString(data['difficulty'] as String?),
      isLearned: (data['isLearned'] ?? false) as bool,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      learnedAt: (data['learnedAt'] as Timestamp?)?.toDate(),
    );
  }

  Flashcard copyWith({
    String? frontWord,
    String? backTranslation,
    String? exampleSentence,
    CardDifficulty? difficulty,
    bool? isLearned,
    DateTime? learnedAt,
  }) =>
      Flashcard(
        id: id,
        userId: userId,
        deckId: deckId,
        frontWord: frontWord ?? this.frontWord,
        backTranslation: backTranslation ?? this.backTranslation,
        exampleSentence: exampleSentence ?? this.exampleSentence,
        difficulty: difficulty ?? this.difficulty,
        isLearned: isLearned ?? this.isLearned,
        createdAt: createdAt,
        learnedAt: learnedAt ?? this.learnedAt,
      );
}
