import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Import หน้า Login

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uni Parking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(), // เริ่มต้นที่หน้า Login
      debugShowCheckedModeBanner: false,
    );
  }
}