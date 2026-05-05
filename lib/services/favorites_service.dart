import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/flashcard.dart';
import '../utils/constants.dart';

/// Source-of-truth for which cards a user has favorited.
///
/// Stored as flat `favorites/{userId}_{cardId}` docs (not a subcollection),
/// so we can stream every favorite for a user with a single `where(userId)`
/// query and the favorites screen doesn't need to join against the cards
/// subcollection. Each doc snapshots the card text so favorites still render
/// nicely if the original card has since been deleted or edited.
class FavoritesService {
  FavoritesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _favorites =>
      _firestore.collection(FirestoreCollections.favorites);

  // Composite id keeps add/remove idempotent and sidesteps duplicates.
  String _docId(String userId, String cardId) => '${userId}_$cardId';

  Stream<List<Flashcard>> watchFavoritesForUser(String userId) {
    return _favorites
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  Future<void> addFavorite(Flashcard card) {
    return _favorites.doc(_docId(card.userId, card.id)).set({
      'userId': card.userId,
      'deckId': card.deckId,
      'cardId': card.id,
      'frontWord': card.frontWord,
      'backTranslation': card.backTranslation,
      'exampleSentence': card.exampleSentence,
      'difficulty': card.difficulty.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite({
    required String userId,
    required String cardId,
  }) =>
      _favorites.doc(_docId(userId, cardId)).delete();

  /// Re-hydrate a Flashcard from a favorite doc. We use the original
  /// `cardId` as the Flashcard's id so callers can match it back against
  /// cards in a deck (e.g. for the toggle state).
  Flashcard _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Flashcard(
      id: (data['cardId'] ?? '') as String,
      userId: (data['userId'] ?? '') as String,
      deckId: (data['deckId'] ?? '') as String,
      frontWord: (data['frontWord'] ?? '') as String,
      backTranslation: (data['backTranslation'] ?? '') as String,
      exampleSentence: (data['exampleSentence'] ?? '') as String,
      difficulty: CardDifficultyX.fromString(data['difficulty'] as String?),
      isLearned: false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
