import 'package:flutter/material.dart';
import 'package:sendit/screens/FavoritesScreen.dart';
import 'package:sendit/screens/ReorderScreen.dart';
import 'package:sendit/screens/home_screen.dart';
import 'package:sendit/screens/profilescreen.dart';
import 'package:sendit/widgets/FloatingCartButton.dart';
import 'themes.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const FavoritesScreen(),
    const ReorderScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Critical for the floating effect (content scrolls behind)
      body: Stack(
        children: [
          // The Page Content
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          // The Floating Cart (Only show on Home, Favorites, Reorder)
          // Ensure it has enough bottom padding to clear the floating navbar if needed
          if (_currentIndex < 3)
            const Positioned(
              bottom: 100, // Adjust this value based on your FloatingCartButton's internal padding
              left: 20,
              right: 20,
              child: FloatingCartButton(),
            ),
          // Note: If FloatingCartButton already contains Positioned,
          // remove the Positioned wrapper above and just use const FloatingCartButton()
          // but verify it doesn't overlap the new higher navbar.
          // Assuming FloatingCartButton handles its own positioning, I will revert to original usage
          // but keep the 'extendBody' in mind.
        ],
      ),
      // Floating Navigation Bar
      bottomNavigationBar: Container(
        height: 80, // Increased height to prevent overflow
        margin: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 10), // Safe margin
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40), // Fully rounded pill shape
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true, // Remove bottom safe area padding to prevent overflow
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white, // Ensure solid background inside the pill
                elevation: 0, // Remove native shadow
                showSelectedLabels: false,
                showUnselectedLabels: false,
                selectedFontSize: 0, // Explicitly set to 0 to remove label space
                unselectedFontSize: 0, // Explicitly set to 0 to remove label space

                // Colors
                selectedItemColor: AppTheme.swiggyOrange,
                unselectedItemColor: Colors.grey.shade400,

                items: [
                  _buildNavItem(Icons.home_outlined, Icons.home_rounded, 'Home', 0),
                  _buildNavItem(Icons.favorite_border_rounded, Icons.favorite_rounded, 'Favorites', 1),
                  _buildNavItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders', 2),
                  _buildNavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Account', 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    // ignore: unused_local_variable
    final bool isSelected = _currentIndex == index;

    return BottomNavigationBarItem(
      icon: Icon(icon, size: 26),
      activeIcon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.swiggyOrange.withOpacity(0.1), // Subtle background for active item
          shape: BoxShape.circle,
        ),
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.swiggyOrange, Color(0xFFFF5722)],
            ).createShader(bounds);
          },
          child: Icon(activeIcon, size: 26, color: Colors.white),
        ),
      ),
      label: label,
    );
  }
}