import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  AppUser({
    required this.uid,
    required this.username,
    required this.email,
    required this.streak,
    required this.longestStreak,
    required this.createdAt,
    this.lastStudyDate,
  });

  final String uid;
  final String username;
  final String email;
  final int streak;
  final int longestStreak;
  final DateTime createdAt;
  final DateTime? lastStudyDate;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AppUser(
      uid: doc.id,
      username: (data['username'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      streak: (data['streak'] ?? 0) as int,
      longestStreak: (data['longestStreak'] ?? 0) as int,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastStudyDate: (data['lastStudyDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'username': username,
        'email': email,
        'streak': streak,
        'longestStreak': longestStreak,
        'createdAt': Timestamp.fromDate(createdAt),
        if (lastStudyDate != null)
          'lastStudyDate': Timestamp.fromDate(lastStudyDate!),
      };

  AppUser copyWith({
    String? username,
    int? streak,
    int? longestStreak,
    DateTime? lastStudyDate,
  }) =>
      AppUser(
        uid: uid,
        username: username ?? this.username,
        email: email,
        streak: streak ?? this.streak,
        longestStreak: longestStreak ?? this.longestStreak,
        createdAt: createdAt,
        lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      );
}
