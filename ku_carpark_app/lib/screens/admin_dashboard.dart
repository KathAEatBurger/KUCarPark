import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/mock_data.dart';
//import '../models/booking.dart';
import 'login_screen.dart';
import '../models/parking_spot.dart';



class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  void _updateSpots(int change) {
    if (parkingSpots.length + change < 0) return;
    if (change > 0) {
      int nextId = parkingSpots.length + 1;
      parkingSpots.add(ParkingSpot(id: 'A-$nextId', zone: 'Zone A'));
    } else {
      if (parkingSpots.last.isOccupied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่สามารถลบล็อกที่มีรถจอดได้')));
        return;
      }
      parkingSpots.removeLast();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pendingBookings = bookings.where((b) => b.status == 'pending_payment').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.red,
        actions: [
           IconButton(icon: const Icon(Icons.logout), onPressed: () { currentUser = null; Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())); })
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('จัดการที่จอดรถ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Row(children: [
              IconButton(onPressed: () => _updateSpots(-1), icon: const Icon(Icons.remove)),
              Text('จำนวนปัจจุบัน: ${parkingSpots.length}', style: const TextStyle(fontSize: 18)),
              IconButton(onPressed: () => _updateSpots(1), icon: const Icon(Icons.add)),
            ]),
            const Divider(height: 30),
            const Text('ตรวจสอบสมาชิกรายเดือน', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (pendingBookings.isEmpty) const Text('ไม่มีรายการรอตรวจสอบ'),
            ...pendingBookings.map((b) => Card(
              child: ListTile(
                title: Text('ทะเบียน: ${b.plateNumber}'),
                subtitle: Text('ส่งเมื่อ: ${DateFormat('HH:mm').format(b.entryTime)}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () {
                    setState(() {
                      b.status = 'completed';
                      final u = users.firstWhere((u) => u.plateNumber == b.plateNumber, orElse: () => users.last);
                      u.isMonthlyMember = true;
                    });
                  }),
                  IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () { setState(() { b.status = 'rejected'; }); }),
                ]),
              ),
            )),
            const Divider(height: 30),
            const Text('รายงานปัญหาจากผู้ใช้', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (reports.isEmpty) const Text('ไม่มีรายงานปัญหา'),
            ...reports.map((r) => Card(child: ListTile(title: Text(r.description), subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(r.timestamp)), trailing: Chip(label: Text(r.status))))),
          ],
        ),
      ),
    );
  }
}