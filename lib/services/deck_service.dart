import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/deck.dart';
import '../utils/constants.dart';

class DeckService {
  DeckService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _decks =>
      _firestore.collection(FirestoreCollections.decks);

  CollectionReference<Map<String, dynamic>> get _favorites =>
      _firestore.collection(FirestoreCollections.favorites);

  Stream<List<Deck>> watchDecks(String userId) {
    return _decks
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(Deck.fromFirestore).toList());
  }

  Future<String> createDeck({
    required String userId,
    required String title,
    required String language,
    required String description,
  }) async {
    final ref = await _decks.add({
      'userId': userId,
      'title': title.trim(),
      'language': language.trim(),
      'description': description.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateDeck({
    required String deckId,
    required String title,
    required String language,
    required String description,
  }) {
    return _decks.doc(deckId).update({
      'title': title.trim(),
      'language': language.trim(),
      'description': description.trim(),
    });
  }

  /// Deletes the deck, every card in its subcollection, and any favorites
  /// pointing at those cards. Done in a single batch so a partial failure
  /// can't leave dangling favorites pointing at cards that no longer exist.
  Future<void> deleteDeck({
    required String userId,
    required String deckId,
  }) async {
    final cardSnap = await _decks
        .doc(deckId)
        .collection(FirestoreCollections.cards)
        .get();
    final favSnap = await _favorites
        .where('userId', isEqualTo: userId)
        .where('deckId', isEqualTo: deckId)
        .get();

    final batch = _firestore.batch();
    for (final doc in cardSnap.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in favSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_decks.doc(deckId));
    await batch.commit();
  }
}
