import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../utils/constants.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(FirestoreCollections.users).doc(uid);

  Stream<AppUser?> watchUser(String uid) {
    return _userDoc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromFirestore(snap);
    });
  }

  Future<AppUser?> fetchUser(String uid) async {
    final snap = await _userDoc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromFirestore(snap);
  }

  Future<void> updateUsername(String uid, String username) =>
      _userDoc(uid).update({'username': username.trim()});

  /// Update streak based on today's study activity. Streak rules:
  /// - if lastStudyDate is today: no change
  /// - if lastStudyDate is yesterday: streak += 1
  /// - else: streak resets to 1
  /// longestStreak is bumped if exceeded.
  ///
  /// Implemented as a plain get+update (not a transaction) so the write can
  /// queue offline. Firestore transactions hard-fail without a connection,
  /// which is what was leaving streak at 0 for users who studied while the
  /// emulator couldn't reach the backend. The trade-off is theoretical:
  /// concurrent writes from two devices could race and miscount by one.
  Future<void> recordStudyToday(String uid) async {
    debugPrint('[UserService] recordStudyToday for $uid');
    final ref = _userDoc(uid);
    try {
      final snap = await ref.get();
      if (!snap.exists) {
        debugPrint('[UserService] user doc missing — skipping streak bump');
        return;
      }
      final data = snap.data() ?? {};
      final last = (data['lastStudyDate'] as Timestamp?)?.toDate();
      final currentStreak = (data['streak'] ?? 0) as int;
      final longest = (data['longestStreak'] ?? 0) as int;

      final today = _dateOnly(DateTime.now());
      final lastDay = last == null ? null : _dateOnly(last);

      int newStreak;
      if (lastDay == null) {
        newStreak = 1;
      } else if (lastDay == today) {
        newStreak = currentStreak == 0 ? 1 : currentStreak;
      } else if (today.difference(lastDay).inDays == 1) {
        newStreak = currentStreak + 1;
      } else {
        newStreak = 1;
      }
      final newLongest = newStreak > longest ? newStreak : longest;

      debugPrint(
        '[UserService] streak $currentStreak → $newStreak '
        '(longest $longest → $newLongest, lastDay=$lastDay)',
      );

      await ref.update({
        'streak': newStreak,
        'longestStreak': newLongest,
        'lastStudyDate': Timestamp.fromDate(today),
      });
    } catch (e) {
      debugPrint('[UserService] recordStudyToday failed: $e');
    }
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
