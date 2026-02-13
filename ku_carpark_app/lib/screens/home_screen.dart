import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/mock_data.dart';
import '../models/booking.dart';

import 'login_screen.dart';
import 'monthly_payment_screen.dart';
import 'booking_screen.dart';
import 'status_screen.dart';
import 'report_screen.dart';
import 'settings_screen.dart';
import 'payment_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    Booking? myActiveBooking;

    try {
      myActiveBooking = bookings.firstWhere(
        (b) =>
            b.plateNumber == currentUser!.plateNumber &&
            b.status == 'active',
      );
    } catch (e) {
      myActiveBooking = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้าหลัก'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              currentUser = null;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สวัสดี, ${currentUser!.username}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            /// สมาชิกรายเดือน
            Card(
              child: ListTile(
                leading: const Icon(Icons.card_membership),
                title: const Text('สมาชิกรายเดือน'),
                subtitle: Text(
                  currentUser!.isMonthlyMember
                      ? 'สถานะ: สมาชิก'
                      : 'สถานะ: ไม่ใช่สมาชิก',
                ),
                trailing: currentUser!.isMonthlyMember
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MonthlyPaymentScreen(),
                            ),
                          );
                        },
                        child: const Text('สมัคร/ต่ออายุ'),
                      ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'เมนู',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                /// ⭐ แก้ตรงนี้
                _buildMenuCard(
                  Icons.local_parking,
                  'จองที่จอดรายวัน',
                  Colors.blue,
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BookingScreen(),
                      ),
                    );
                    setState(() {}); // ⭐ รีเฟรช HomeScreen
                  },
                ),
                _buildMenuCard(
                  Icons.map,
                  'สถานะที่จอด',
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StatusScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  Icons.report_problem,
                  'รายงานปัญหา',
                  Colors.orange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ReportScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  Icons.settings,
                  'ตั้งค่า',
                  Colors.grey,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// กำลังจอดอยู่
            if (myActiveBooking != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.timer, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'กำลังจอดอยู่',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('ทะเบียน: ${myActiveBooking!.plateNumber}'),
                    Text(
                      'เวลาเข้า: ${DateFormat('HH:mm').format(
                        myActiveBooking/**!**/.entryTime,
                      )}',
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(
                                booking: myActiveBooking!,
                              ),
                            ),
                          );
                        },
                        child: const Text('ออกจากที่จอด / ชำระเงิน'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
