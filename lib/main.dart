import 'package:flutter/material.dart';
import 'settings_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // ⭐ สำคัญมาก แก้พื้นขาว/ดำใต้ BottomNav

      body: Stack(
        fit: StackFit.expand,
        children: [
          /// 🔹 Background image (เต็มจอจริง)
          Image.asset(
            'assets/images/background.jpg',
            fit: BoxFit.cover,
          ),

          /// 🔹 Top menu
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  Icon(Icons.menu, size: 30, color: Colors.white),
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
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.centerLeft,
              child: const Text(
                "Where are you going?",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          /// 🔹 Bottom card
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "Welcome to CarPark App",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Simply input your destination and get a list of parking spaces available",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 12),
                  Icon(
                    Icons.directions_car,
                    color: Colors.teal,
                    size: 30,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      /// 🔹 Bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white.withOpacity(0.95),
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsPage(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
