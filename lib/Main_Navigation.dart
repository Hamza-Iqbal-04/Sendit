import 'package:flutter/material.dart';
import 'package:sendit/screens/FavoritesScreen.dart';
import 'package:sendit/screens/ReorderScreen.dart';
import 'package:sendit/screens/home_screen.dart';
import 'package:sendit/screens/profilescreen.dart'; // Ensure this points to your ProfileScreen
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
    const ProfileScreen(), // Changed from Settings to Profile for better UX
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The Page Content
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),

          // The Floating Cart (Only show on Home, Favorites, Reorder)
          // Hide on Profile (index 3)
          if (_currentIndex < 3)
            const FloatingCartButton(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1), // Crisp top border
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04), // Softer, more modern shadow
              blurRadius: 10,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: Theme(
          // Remove splash effect for a cleaner feel
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            // Colors
            selectedItemColor: AppTheme.swiggyOrange,
            unselectedItemColor: const Color(0xFF9E9E9E), // Lighter grey for modern look
            // Fonts
            selectedFontSize: 11,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2, height: 1.5),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.2, height: 1.5),
            elevation: 0,
            items: [
              _buildNavItem(Icons.home_outlined, Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.favorite_border_rounded, Icons.favorite_rounded, 'Favorites', 1),
              _buildNavItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders', 2),
              _buildNavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Account', 3),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, IconData activeIcon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Icon(icon, size: 24),
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.swiggyOrange, Color(0xFFFF5722)], // Subtle gradient for active icon
            ).createShader(bounds);
          },
          child: Icon(activeIcon, size: 24, color: Colors.white), // Color is ignored by ShaderMask but required
        ),
      ),
      label: label,
    );
  }
}