import 'package:flutter/material.dart';
import '../utils/mock_data.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _passController = TextEditingController();
  
  void changePassword() {
    currentUser!.password = _passController.text;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เปลี่ยนรหัสผ่านสำเร็จ')));
    _passController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่า')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('เปลี่ยนรหัสผ่าน', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'รหัสผ่านใหม่')),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: changePassword, child: const Text('บันทึก')))
          ],
        ),
      ),
    );
  }
}