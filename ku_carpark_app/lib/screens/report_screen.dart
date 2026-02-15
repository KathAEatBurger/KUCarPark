import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _issueController = TextEditingController();

  Future<void> _sendReport() async {
    if (_issueController.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('reports').add({
      'description': _issueController.text,
      'timestamp': DateTime.now(),
      'userId': FirebaseAuth.instance.currentUser?.uid,
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งรายงานปัญหาเรียบร้อย')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายงานปัญหา')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _issueController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'รายละเอียดปัญหา',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _sendReport, child: const Text('ส่งรายงาน')),
            ),
          ],
        ),
      ),
    );
  }
}