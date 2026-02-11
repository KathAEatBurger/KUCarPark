import 'package:flutter/material.dart';
import '../utils/mock_data.dart';
import '../models/booking.dart';

class PaymentScreen extends StatefulWidget {
  final Booking booking;
  const PaymentScreen({super.key, required this.booking});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  double _price = 0.0;

  @override
  void initState() {
    super.initState();
    _price = calculatePrice(widget.booking);
  }

  void _processPayment() {
    setState(() {
      widget.booking.exitTime = DateTime.now();
      widget.booking.price = _price;
      widget.booking.status = 'completed';
      
      final spotIndex = parkingSpots.indexWhere((s) => s.plateNumber == widget.booking.plateNumber);
      if (spotIndex != -1) {
        parkingSpots[spotIndex].isOccupied = false;
        parkingSpots[spotIndex].plateNumber = null;
      }
    });
    Navigator.popUntil(context, ModalRoute.withName('/'));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ชำระเงิน $_price บาท สำเร็จ')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ชำระเงิน')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ทะเบียน: ${widget.booking.plateNumber}', style: const TextStyle(fontSize: 18)),
            Text('เวลาเข้า: ...'), // Simplified
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ยอดรวม', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text('$_price บาท', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(16)),
                child: const Text('ชำระเงิน', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}