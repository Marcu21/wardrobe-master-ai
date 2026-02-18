import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'wardrobe_gallery_screen.dart';
import 'lookbook_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // 1-to-1 Mapping of Screens
  final List<Widget> _screens = const [
    HomeScreen(),            // Index 0
    WardrobeGalleryScreen(), // Index 1
    LookbookScreen(),        // Index 2 (Outfits)
    Center(child: Text('Laundry Screen Coming Soon')), // Index 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const <Widget>[
          // Index 0: Home
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          // Index 1: Wardrobe
          NavigationDestination(
            icon: Icon(Icons.checkroom_outlined),
            selectedIcon: Icon(Icons.checkroom),
            label: 'Wardrobe',
          ),
          // Index 2: Outfits
          NavigationDestination(
            icon: Icon(Icons.accessibility_new_outlined),
            selectedIcon: Icon(Icons.accessibility_new),
            label: 'Outfits',
          ),
          // Index 3: Laundry
          NavigationDestination(
            icon: Icon(Icons.local_laundry_service_outlined),
            selectedIcon: Icon(Icons.local_laundry_service),
            label: 'Laundry',
          ),
        ],
      ),
    );
  }
}
