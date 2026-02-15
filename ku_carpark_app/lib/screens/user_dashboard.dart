import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'daily_parking_screen.dart';
import 'monthly_screen.dart';
import 'parking_status_screen.dart';
import 'report_screen.dart';
import '../home.dart';

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KU Carpark Menu', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        /**actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],**/
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            color: const Color(0xFF38B38D),
            child: const Text(
              "ยินดีต้อนรับสู่ระบบจอดรถ มก. บางเขน",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                
                _MenuCard(
                  title: 'นำทางไปที่จอด', 
                  icon: Icons.directions_car, 
                  color: Colors.teal, 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage()))
                ),
                
                _MenuCard(
                  title: 'จอดรายวัน', 
                  icon: Icons.timer, 
                  color: Colors.orange, 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyParkingScreen()))
                ),
                
                _MenuCard(
                  title: 'สมาชิกรายเดือน', 
                  icon: Icons.card_membership, 
                  color: Colors.green, 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyScreen()))
                ),
                
                _MenuCard(
                  title: 'สถานะที่จอด', 
                  icon: Icons.local_parking, 
                  color: Colors.blue, 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParkingStatusScreen()))
                ),
                
                _MenuCard(
                  title: 'รายงานปัญหา', 
                  icon: Icons.report_problem, 
                  color: Colors.red, 
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()))
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.9), 
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}