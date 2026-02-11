import 'package:flutter/material.dart';
import '../utils/mock_data.dart';
import '../models/booking.dart';

class MonthlyPaymentScreen extends StatelessWidget {
  const MonthlyPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิกรายเดือน')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('อัตราค่าสมาชิก: 500 บาท/เดือน', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Container(height: 200, decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)), child: const Center(child: Text('ปุ่มอัปโหลด Slip จำลอง'))),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  bookings.add(Booking(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    plateNumber: currentUser!.plateNumber ?? 'Unknown',
                    entryTime: DateTime.now(),
                    type: 'monthly',
                    status: 'pending_payment',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งสลิปแล้ว รอแอดมินตรวจสอบ')));
                  Navigator.pop(context);
                },
                child: const Text('ส่งหลักฐานการโอนเงิน'),
              ),
            )
          ],
        ),
      ),
    );
  }
}