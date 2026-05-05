import 'package:cloud_firestore/cloud_firestore.dart';

class Deck {
  Deck({
    required this.id,
    required this.userId,
    required this.title,
    required this.language,
    required this.description,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String language;
  final String description;
  final DateTime createdAt;

  factory Deck.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return Deck(
      id: doc.id,
      userId: (data['userId'] ?? '') as String,
      title: (data['title'] ?? '') as String,
      language: (data['language'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestoreCreate() => {
        'userId': userId,
        'title': title,
        'language': language,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toFirestoreUpdate() => {
        'title': title,
        'language': language,
        'description': description,
      };

  Deck copyWith({
    String? title,
    String? language,
    String? description,
  }) =>
      Deck(
        id: id,
        userId: userId,
        title: title ?? this.title,
        language: language ?? this.language,
        description: description ?? this.description,
        createdAt: createdAt,
      );
}
