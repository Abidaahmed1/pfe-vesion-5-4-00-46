import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../data/providers/navigation_provider.dart';
import 'dashboard_tab.dart';
import 'inventory_list_tab.dart';
import 'barcode_scanner_screen.dart';
import 'profile_tab.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final List<Widget> _pages = [
    const DashboardTab(),
    const InventoryListTab(),
    const BarcodeScannerScreen(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0D9488);
    final nav = Provider.of<NavigationProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: PageView(
        controller: nav.pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          // Sync with nav provider
        },
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: const Color(0xFFE2E8F0), width: 1)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: nav.currentIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          onTap: (navIndex) => nav.setTab(navIndex),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: primaryColor,
          unselectedItemColor: const Color(0xFF94A3B8), // Slate 400
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            height: 1.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
          items: [
            _buildNavItem(
              Icons.dashboard_outlined,
              Icons.dashboard_rounded,
              "Accueil",
              0,
              nav.currentIndex,
            ),
            _buildNavItem(
              Icons.inventory_2_outlined,
              Icons.inventory_2_rounded,
              "Inventaires",
              1,
              nav.currentIndex,
            ),
            _buildNavItem(
              Icons.qr_code_scanner_rounded,
              Icons.qr_code_scanner_rounded,
              "Scanner",
              2,
              nav.currentIndex,
            ),
            _buildNavItem(
              Icons.person_outline_rounded,
              Icons.person_rounded,
              "Profil",
              3,
              nav.currentIndex,
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
    int current,
  ) {
    final isSelected = current == index;
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Icon(isSelected ? activeIcon : icon, size: 24),
      ),
      label: label,
    );
  }
}
