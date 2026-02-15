import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('จัดการจำนวนที่จอด (จำลอง Sensor)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          ZoneManageWidget(),
          Divider(height: 40),
          Text('คำขอสมาชิกรายเดือน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          MonthlyApprovalWidget(),
        ],
      ),
    );
  }
}

class ZoneManageWidget extends StatelessWidget {
  const ZoneManageWidget({super.key});

  Future<void> _updateSpot(String docId, int newAvailable, int total) async {
    if (newAvailable < 0) newAvailable = 0;
    if (newAvailable > total) newAvailable = total;
    await FirebaseFirestore.instance.collection('zones').doc(docId).update({'available': newAvailable});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('zones').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final zones = snapshot.data!.docs;
        return Column(
          children: zones.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final total = data['total'] ?? 0;
            final available = data['available'] ?? 0;
            return Card(
              child: ListTile(
                title: Text('โซน: ${data['name']}'),
                subtitle: Text('ว่าง: $available / $total'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.remove), onPressed: () => _updateSpot(doc.id, available - 1, total)),
                    IconButton(icon: const Icon(Icons.add), onPressed: () => _updateSpot(doc.id, available + 1, total)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class MonthlyApprovalWidget extends StatelessWidget {
  const MonthlyApprovalWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('monthly_requests').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Text('ไม่มีคำขอรออนุมัติ');
        final requests = snapshot.data!.docs;
        if (requests.isEmpty) return const Text('ไม่มีคำขอรออนุมัติ');
        return Column(
          children: requests.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text('ทะเบียน: ${data['plate']}'),
                subtitle: Text('เวลา: ${data['timestamp'].toDate()}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _updateStatus(doc.id, 'approved')),
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _updateStatus(doc.id, 'rejected')),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('monthly_requests').doc(id).update({'status': status});
  }
}