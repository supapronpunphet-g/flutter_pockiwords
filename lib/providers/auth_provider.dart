import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

enum AuthStatus { loading, signedOut, awaitingVerification, signedIn }

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService, UserService? userService})
      : _authService = authService ?? AuthService(),
        _userService = userService ?? UserService() {
    _sub = _authService.authStateChanges().listen(_handleAuthChange);
  }

  final AuthService _authService;
  final UserService _userService;
  late final StreamSubscription<User?> _sub;
  StreamSubscription<AppUser?>? _userSub;

  AuthStatus _status = AuthStatus.loading;
  User? _firebaseUser;
  AppUser? _appUser;
  String? _errorMessage;
  bool _busy = false;

  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  String? get errorMessage => _errorMessage;
  bool get busy => _busy;
  bool get isSignedIn => _status == AuthStatus.signedIn;

  void _setStatus(AuthStatus next) {
    if (_status == next) return;
    debugPrint('[Auth] status: ${_status.name} → ${next.name}');
    _status = next;
  }

  Future<void> _handleAuthChange(User? user) async {
    debugPrint(
      '[Auth] authStateChanges fired '
      '— user: ${user?.uid ?? 'null'}, verified: ${user?.emailVerified}',
    );
    _firebaseUser = user;
    await _userSub?.cancel();
    _userSub = null;

    if (user == null) {
      _appUser = null;
      _setStatus(AuthStatus.signedOut);
      notifyListeners();
      return;
    }
    //Logic ตัดสินสถานะ
    if (!user.emailVerified) {
      _appUser = null;
      _setStatus(AuthStatus.awaitingVerification);
      notifyListeners();
      return;
    }

    _userSub = _userService.watchUser(user.uid).listen((appUser) {
      _appUser = appUser;
      _setStatus(AuthStatus.signedIn);
      notifyListeners();
    });
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    debugPrint('[Auth] register() requested for $email');
    return _run(() async {
      await _authService.register(
        username: username,
        email: email,
        password: password,
      );
    });
  }

  Future<bool> login({required String email, required String password}) async {
    debugPrint('[Auth] login() requested for $email');
    return _run(() async {
      await _authService.login(email: email, password: password);
    });
  }

  Future<bool> sendVerificationEmail() {
    debugPrint('[Auth] sendVerificationEmail() requested');
    return _run(_authService.sendVerificationEmail);
  }

  /// Forces a Firebase user reload and returns whether the email is now
  /// verified. On verification, manually re-runs the auth-state handler so the
  /// AuthGate flips to signedIn (the User instance does not change identity
  /// on reload, so authStateChanges does not fire on its own).
  Future<bool> refreshVerification() async {
    final verified = await _authService.reloadAndCheckVerified();
    debugPrint('[Auth] refreshVerification() → verified=$verified');
    if (verified) {
      await _handleAuthChange(_authService.currentUser);
    }
    return verified;
  }

  Future<bool> sendPasswordReset(String email) {
    debugPrint('[Auth] sendPasswordReset() requested for $email');
    return _run(() => _authService.sendPasswordReset(email));
  }

  Future<void> logout() async {
    debugPrint('[Auth] logout() requested');
    await _authService.logout();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _busy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _errorMessage = AuthService.describeError(e);
      debugPrint('[Auth] action failed: $_errorMessage');
      return false;
    } finally {
      // Always release the busy state, even if `action` or the catch block
      // threw. This is what guarantees the loading spinner stops.
      _busy = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
