import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../utils/constants.dart';

/// Tracks whether Firestore is currently reachable.
///
/// Subscribes to the signed-in user's profile doc with
/// `includeMetadataChanges: true` and watches `isFromCache`. When the SDK
/// can't reach the backend, snapshots come from local cache and the flag
/// flips to true; when it reconnects, the flag flips back. We pick the user
/// doc because it's small, always exists once a user is signed in, and is
/// already part of the read path.
///
/// Flips are debounced so brief network blips don't flash the banner.
class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  String? _userId;
  bool _isOffline = false;
  Timer? _debounce;

  bool get isOffline => _isOffline;

  void bindUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _sub?.cancel();
    _sub = null;
    _debounce?.cancel();

    if (userId == null) {
      _setOffline(false);
      return;
    }

    _sub = FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(userId)
        .snapshots(includeMetadataChanges: true)
        .listen(
      (snap) => _scheduleFlip(snap.metadata.isFromCache),
      onError: (Object err) {
        debugPrint('[Connectivity] user doc stream error: $err');
        _scheduleFlip(true);
      },
    );
  }

  void _scheduleFlip(bool fromCache) {
    _debounce?.cancel();
    // 2s debounce — long enough to skip transient blips during reconnect,
    // short enough that the user actually sees the banner if they're truly
    // offline.
    _debounce = Timer(const Duration(seconds: 2), () {
      _setOffline(fromCache);
    });
  }

  void _setOffline(bool value) {
    if (_isOffline == value) return;
    _isOffline = value;
    debugPrint('[Connectivity] isOffline → $_isOffline');
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _debounce?.cancel();
    super.dispose();
  }
}
