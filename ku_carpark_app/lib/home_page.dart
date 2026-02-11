import 'package:flutter/material.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: Stack(
        fit: StackFit.expand,
        children: [
          /// 🔹 Map Background
          Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
          ),

          /// 🔹 Top menu
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Icon(Icons.menu, size: 30, color: Colors.black87),
                  Icon(Icons.notifications_none,
                      size: 28, color: Colors.black87),
                ],
              ),
            ),
          ),

          /// 🔹 Search box
          Positioned(
            top: 90,
            left: 20,
            right: 20,
            child: Container(
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xfff1f3f6),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 10),
                  Text(
                    "Where are you going?",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          /// 🔹 Welcome card
          Positioned(
            bottom: 150,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xfff1f3f6),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "Welcome to CarPark App",
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Simply input your destination and get a list of parking spaces available",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 18),
                  Icon(
                    Icons.directions_car,
                    color: Colors.teal,
                    size: 32,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      /// 🔹 Floating button (center)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        elevation: 6,
        onPressed: () {},
        child: const Icon(Icons.navigation, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      /// 🔹 Bottom bar with notch
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 10,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home, color: Colors.grey),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.access_time, color: Colors.grey),
                onPressed: () {},
              ),
              const SizedBox(width: 40), // space for FAB
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsPage(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
