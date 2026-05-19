import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_app/theme/app_colors.dart';
import 'home/home_screen.dart';
import 'add_clothing/add_clothing_screen.dart';
import 'wardrobe_gallery/wardrobe_gallery_screen.dart';
import 'lookbook/lookbook_screen.dart';
import 'laundry/laundry_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    WardrobeGalleryScreen(),
    LookbookScreen(),
    LaundryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: _buildBottomBar(),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddClothingScreen()),
              ),
              backgroundColor: Colors.black87,
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.white, size: 22),
            )
          : null,
    );
  }

  Widget _buildBottomBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: kGlass,
            border: Border(
              top: BorderSide(
                color: Colors.black.withOpacity(0.06),
                width: 0.5,
              ),
            ),
          ),
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                _buildNavItem(
                  1,
                  Icons.checkroom_outlined,
                  Icons.checkroom,
                  'Wardrobe',
                ),
                _buildNavItem(
                  2,
                  Icons.accessibility_new_outlined,
                  Icons.accessibility_new,
                  'Outfits',
                ),
                _buildNavItem(
                  3,
                  Icons.local_laundry_service_outlined,
                  Icons.local_laundry_service,
                  'Laundry',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedIndex = index),
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.black.withOpacity(0.06)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? Colors.black87 : Colors.black38,
                size: isSelected ? 25 : 23,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black87 : Colors.black38,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                letterSpacing: isSelected ? -0.2 : 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
