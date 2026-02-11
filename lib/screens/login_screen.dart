import 'package:flutter/material.dart';
import '../utils/mock_data.dart';
import 'home_screen.dart';
import 'admin_dashboard.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  String? _errorMsg;

  void _login() {
    String u = _userController.text;
    String p = _passController.text;

    final foundUser = users.firstWhere(
      (user) => user.username == u && user.password == p,
      orElse: () => users.first,
    );

    if (foundUser.username == u && foundUser.password == p) {
      currentUser = foundUser;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => foundUser.role == 'admin'
              ?  AdminDashboard()
              :  HomeScreen(),
        ),
      );
    } else {
      setState(() => _errorMsg = 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เข้าสู่ระบบ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_parking, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: 'ชื่อผู้ใช้', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'รหัสผ่าน', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            if (_errorMsg != null) Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _login, child: const Text('Login')),
            ),
          ],
        ),
      ),
    );
  }
}