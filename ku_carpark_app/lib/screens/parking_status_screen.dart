import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingStatusScreen extends StatelessWidget {
  const ParkingStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สถานะที่จอด')),
      body: StreamBuilder<QuerySnapshot>(
        // 1. ดึงข้อมูลโซนทั้งหมดมาก่อน
        stream: FirebaseFirestore.instance.collection('zones').snapshots(),
        builder: (context, zoneSnapshot) {
          if (!zoneSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final zones = zoneSnapshot.data!.docs;

          return ListView.builder(
            itemCount: zones.length,
            itemBuilder: (context, index) {
              final zoneDoc = zones[index];
              final zoneData = zoneDoc.data() as Map<String, dynamic>;
              
              final zoneId = zoneDoc.id;         // ID ของโซน
              final zoneName = zoneData['name']; // ชื่อโซน
              final total = zoneData['total'] ?? 0; // จำนวนทั้งหมด

              // 2. สำหรับแต่ละโซน ให้ดึงข้อมูลการจองที่กำลัง active อยู่
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('daily_bookings')
                    .where('zoneId', isEqualTo: zoneId) // เฉพาะโซนนี้
                    .where('status', isEqualTo: 'active') // เฉพาะที่จอดอยู่
                    .snapshots(),
                builder: (context, bookingSnapshot) {
                  // นับจำนวนคนที่จองอยู่จริง
                  int occupiedCount = 0;
                  if (bookingSnapshot.hasData) {
                    occupiedCount = bookingSnapshot.data!.docs.length;
                  }

                  // คำนวณจำนวนว่าง
                  int available = total - occupiedCount;
                  if (available < 0) available = 0; // กันกรณีค่าติดลบ
                  
                  final isFull = available == 0;

                  return Card(
                    color: isFull ? Colors.red.shade100 : Colors.green.shade100,
                    child: ListTile(
                      leading: Icon(
                        Icons.local_parking,
                        color: isFull ? Colors.red : Colors.green,
                        size: 40,
                      ),
                      title: Text(
                        zoneName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'ว่าง: $available / $total คัน',
                        style: TextStyle(
                          color: isFull ? Colors.red.shade900 : Colors.green.shade900,
                        ),
                      ),
                      trailing: Text(
                        isFull ? 'เต็ม' : 'ว่าง',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isFull ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}