import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/flashcard.dart';
import '../utils/constants.dart';

class CardService {
  CardService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Subcollection reference: `decks/{deckId}/cards`.
  CollectionReference<Map<String, dynamic>> _cards(String deckId) => _firestore
      .collection(FirestoreCollections.decks)
      .doc(deckId)
      .collection(FirestoreCollections.cards);

  /// Watch every card belonging to a single deck.
  ///
  /// Note: we deliberately do NOT add `.orderBy('createdAt', descending: true)`
  /// here — Firestore would still serve the query, but we sort in Dart so
  /// missing serverTimestamps (just-created cards) don't get pushed to the
  /// bottom of the list during the round-trip.
  Stream<List<Flashcard>> watchCards(String deckId) {
    return _cards(deckId)
        .snapshots()
        .map((snap) => snap.docs.map(Flashcard.fromFirestore).toList());
  }

  Future<String> createCard({
    required String userId,
    required String deckId,
    required String frontWord,
    required String backTranslation,
    required String exampleSentence,
    required CardDifficulty difficulty,
  }) async {
    debugPrint(
      '[CardService] createCard → decks/$deckId/cards (userId=$userId, '
      'front="$frontWord")',
    );
    try {
      final ref = await _cards(deckId).add({
        // userId is denormalized so the collectionGroup query above can scope
        // results without having to look up each parent deck.
        'userId': userId,
        'deckId': deckId,
        'frontWord': frontWord.trim(),
        'backTranslation': backTranslation.trim(),
        'exampleSentence': exampleSentence.trim(),
        'difficulty': difficulty.name,
        'isLearned': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[CardService] createCard success id=${ref.id}');
      return ref.id;
    } catch (e, st) {
      // Surface the cause — most often this is PERMISSION_DENIED when
      // Firestore rules don't cover the new decks/{deckId}/cards path.
      debugPrint('[CardService] createCard FAILED: $e\n$st');
      rethrow;
    }
  }

  Future<void> updateCard({
    required String deckId,
    required String cardId,
    required String frontWord,
    required String backTranslation,
    required String exampleSentence,
    required CardDifficulty difficulty,
  }) {
    return _cards(deckId).doc(cardId).update({
      'frontWord': frontWord.trim(),
      'backTranslation': backTranslation.trim(),
      'exampleSentence': exampleSentence.trim(),
      'difficulty': difficulty.name,
    });
  }

  Future<void> deleteCard({
    required String deckId,
    required String cardId,
  }) =>
      _cards(deckId).doc(cardId).delete();

  /// Stamp a card as learned (or un-learned). Used by the study screen when
  /// the user taps "Next" on a card — viewing through to the next one counts
  /// as learning it, which is what makes the deck progress bar fill up.
  Future<void> setLearned({
    required String deckId,
    required String cardId,
    required bool value,
  }) {
    return _cards(deckId).doc(cardId).update({
      'isLearned': value,
      if (value) 'learnedAt': FieldValue.serverTimestamp(),
    });
  }
}
