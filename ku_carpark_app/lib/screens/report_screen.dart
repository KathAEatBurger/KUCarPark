import 'package:flutter/material.dart';
import '../utils/mock_data.dart';
import '../models/report.dart';


class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('รายงานปัญหา')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'รายละเอียดปัญหา', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  reports.add(Report(id: DateTime.now().toString(), description: controller.text, timestamp: DateTime.now(), status: 'submitted'));
                  controller.clear();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งรายงานเรียบร้อย')));
                },
                child: const Text('ส่งรายงาน'),
              ),
            )
          ],
        ),
      ),
    );
  }
}