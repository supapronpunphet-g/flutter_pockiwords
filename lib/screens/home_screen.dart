import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../widgets/offline_banner.dart';
import 'decks/decks_list_screen.dart';
import 'favorites_screen.dart';
import 'home_dashboard_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  static const _tabs = <Widget>[
    HomeDashboardScreen(),
    DecksListScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      // Stack the offline banner just above the nav bar so it's visible on
      // every tab without conflicting with each tab's own AppBar.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OfflineBanner(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.secondary.withValues(alpha: 0.7),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.collections_bookmark_rounded),
                label: 'Decks',
              ),
              NavigationDestination(
                icon: Icon(Icons.star_rounded),
                label: 'Favorites',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
