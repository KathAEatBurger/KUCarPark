import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ku_carpark_app/about.dart'; // เพิ่ม import หน้า about

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // ฟังก์ชันแสดง Dialog ยืนยันการออกจากระบบ
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("ยืนยันการออกจากระบบ"),
          content: const Text("คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?"),
          actions: [
            TextButton(
              child: const Text("ยกเลิก"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("ออกจากระบบ", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamedAndRemoveUntil('/sign-in', (route) => false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันแสดง Dialog ยืนยันการลบบัญชี
  void _showDeleteAccountDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "ลบบัญชีผู้ใช้",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "การลบบัญชีจะส่งผลดังนี้:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("• ข้อมูลโปรไฟล์ทั้งหมดจะถูกลบ"),
              const Text("• รีวิวที่คุณเขียนจะถูกลบ"),
              const Text("• รายงานปัญหาที่คุณแจ้งจะถูกลบ"),
              const Text("• ไม่สามารถกู้คืนข้อมูลได้"),
              const SizedBox(height: 16),
              const Text(
                "หากคุณแน่ใจ กรุณากรอกรหัสผ่านเพื่อยืนยัน",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "รหัสผ่าน",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("ยกเลิก"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              onPressed: () async {
                if (passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("กรุณากรอกรหัสผ่าน"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // แสดง loading
                Navigator.pop(context); // ปิด dialog
                _showLoadingDialog(context);

                try {
                  // 1. ลบข้อมูลใน Firestore
                  if (user != null) {
                    // ลบข้อมูล users
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .delete();

                    // ลบรีวิวที่ผู้ใช้เขียน
                    final reviews = await FirebaseFirestore.instance
                        .collection('reviews')
                        .where('userId', isEqualTo: user.uid)
                        .get();
                    
                    for (var review in reviews.docs) {
                      await review.reference.delete();
                    }

                    // ลบรายงานที่ผู้ใช้แจ้ง
                    final reports = await FirebaseFirestore.instance
                        .collection('reports')
                        .where('userId', isEqualTo: user.uid)
                        .get();
                    
                    for (var report in reports.docs) {
                      await report.reference.delete();
                    }

                    // 2. Re-authenticate ผู้ใช้ก่อนลบ
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: passwordController.text,
                    );

                    await user.reauthenticateWithCredential(credential);

                    // 3. ลบบัญชี Firebase Auth
                    await user.delete();

                    if (context.mounted) {
                      Navigator.pop(context); // ปิด loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("ลบบัญชีเรียบร้อย"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      // กลับไปหน้า Login
                      Navigator.of(context).pushNamedAndRemoveUntil('/sign-in', (route) => false);
                    }
                  }
                } on FirebaseAuthException catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // ปิด loading
                    
                    String errorMessage = "เกิดข้อผิดพลาด";
                    if (e.code == 'wrong-password') {
                      errorMessage = "รหัสผ่านไม่ถูกต้อง";
                    } else if (e.code == 'requires-recent-login') {
                      errorMessage = "กรุณาออกจากระบบแล้วเข้าสู่ระบบใหม่อีกครั้งก่อนลบบัญชี";
                    }
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // ปิด loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("เกิดข้อผิดพลาด: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("ลบบัญชี"),
            ),
          ],
        );
      },
    );
  }

  // ฟังก์ชันแสดง loading dialog
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ตั้งค่า"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // ✅ เกี่ยวกับแอปพลิเคชัน - เพิ่ม onTap
          ListTile(
            leading: const Icon(Icons.info, color: Colors.teal),
            title: const Text("เกี่ยวกับแอปพลิเคชัน"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16), // ลูกศร
            onTap: () {
              // ✅ ไปที่หน้า about.dart
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
          const Divider(),
          
          // ✅ ปุ่ม Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              "ออกจากระบบ",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () => _showLogoutDialog(context),
          ),
          const Divider(),
          
          // ปุ่ม Delete Account
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              "ลบบัญชีผู้ใช้",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            subtitle: const Text("ข้อมูลทั้งหมดจะถูกลบ ไม่สามารถกู้คืนได้"),
            onTap: () => _showDeleteAccountDialog(context),
          ),
          const Divider(),
        ],
      ),
    );
  }
}