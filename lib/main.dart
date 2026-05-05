
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/deck_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/game_provider.dart';
import 'providers/stats_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Status bar / nav bar styling — dark icons on the soft pink background,
  // so the system UI looks intentional on Android instead of muddy default.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFFFFF5F7),
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PockiWordsApp());
}

class PockiWordsApp extends StatelessWidget {
  const PockiWordsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Each ProxyProvider's update() runs synchronously during build.
        // Calling bindUser inline triggers notifyListeners during build →
        // crashes with "Failed assertion: '!_dirty'". Defer to the next frame.
        // bindUser itself is idempotent (guards on userId), so multiple
        // post-frame calls are harmless.
        _bindToAuth<DeckProvider>(
          () => DeckProvider(),
          (p, uid) => p.bindUser(uid),
        ),
        _bindToAuth<FavoritesProvider>(
          () => FavoritesProvider(),
          (p, uid) => p.bindUser(uid),
        ),
        _bindToAuth<StatsProvider>(
          () => StatsProvider(),
          (p, uid) => p.bindUser(uid),
        ),
        _bindToAuth<GameProvider>(
          () => GameProvider(),
          (p, uid) => p.bindUser(uid),
        ),
        _bindToAuth<ConnectivityProvider>(
          () => ConnectivityProvider(),
          (p, uid) => p.bindUser(uid),
        ),
      ],
      child: MaterialApp(
        title: 'PockiWords',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AuthGate(),
      ),
    );
  }
}

/// Helper that mirrors a ChangeNotifier's lifecycle to the signed-in user,
/// while deferring bindUser to the next frame so notifyListeners doesn't
/// fire mid-build.
ChangeNotifierProxyProvider<AuthProvider, T>
    _bindToAuth<T extends ChangeNotifier>(
  T Function() create,
  void Function(T provider, String? userId) bind,
) {
  return ChangeNotifierProxyProvider<AuthProvider, T>(
    create: (_) => create(),
    update: (_, auth, prev) {
      final p = prev ?? create();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        bind(p, auth.firebaseUser?.uid);
      });
      return p;
    },
  );
}

