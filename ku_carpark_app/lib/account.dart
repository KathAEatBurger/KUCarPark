import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  // ✅ Form สำหรับเปลี่ยนอีเมล
  final _emailFormKey = GlobalKey<FormState>();
  final _emailCurrentPasswordController = TextEditingController();
  final _newEmailController = TextEditingController();
  
  // ✅ Form สำหรับเปลี่ยนรหัสผ่าน
  final _passwordFormKey = GlobalKey<FormState>();
  final _passwordCurrentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  // ✅ เปลี่ยนอีเมล (ใช้ verifyBeforeUpdateEmail)
  Future<void> _changeEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Re-authenticate ก่อนเปลี่ยนอีเมล
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _emailCurrentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // ใช้ verifyBeforeUpdateEmail
      await user.verifyBeforeUpdateEmail(_newEmailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ส่งลิงก์ยืนยันไปยังอีเมลใหม่เรียบร้อย กรุณาตรวจสอบอีเมลและยืนยัน'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        
        // ล้างฟอร์มอีเมล
        _emailCurrentPasswordController.clear();
        _newEmailController.clear();
      }
    } on FirebaseAuthException catch (e) {
      String message = 'เกิดข้อผิดพลาด';
      if (e.code == 'wrong-password') {
        message = 'รหัสผ่านไม่ถูกต้อง';
      } else if (e.code == 'email-already-in-use') {
        message = 'อีเมลนี้มีผู้ใช้งานแล้ว';
      } else if (e.code == 'invalid-email') {
        message = 'รูปแบบอีเมลไม่ถูกต้อง';
      } else if (e.code == 'requires-recent-login') {
        message = 'กรุณาออกจากระบบแล้วเข้าสู่ระบบใหม่อีกครั้ง';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ เปลี่ยนรหัสผ่าน
  Future<void> _changePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Re-authenticate ก่อนเปลี่ยนรหัสผ่าน
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordCurrentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // เปลี่ยนรหัสผ่าน
      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เปลี่ยนรหัสผ่านเรียบร้อย'),
            backgroundColor: Colors.green,
          ),
        );
        
        // ล้างฟอร์มรหัสผ่าน
        _passwordCurrentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } on FirebaseAuthException catch (e) {
      String message = 'เกิดข้อผิดพลาด';
      if (e.code == 'wrong-password') {
        message = 'รหัสผ่านปัจจุบันไม่ถูกต้อง';
      } else if (e.code == 'weak-password') {
        message = 'รหัสผ่านใหม่ต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
      } else if (e.code == 'requires-recent-login') {
        message = 'กรุณาออกจากระบบแล้วเข้าสู่ระบบใหม่อีกครั้ง';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // Email form
    _emailCurrentPasswordController.dispose();
    _newEmailController.dispose();
    
    // Password form
    _passwordCurrentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("จัดการบัญชีผู้ใช้"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ ข้อมูลผู้ใช้ปัจจุบัน
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ข้อมูลปัจจุบัน",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.email, "อีเมล", user?.email ?? '-'),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // ✅ เปลี่ยนอีเมล (แยกฟอร์ม)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _emailFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "เปลี่ยนอีเมล",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "ระบบจะส่งลิงก์ยืนยันไปยังอีเมลใหม่",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            
                            // รหัสผ่านปัจจุบัน (สำหรับยืนยันตัวตน)
                            TextFormField(
                              controller: _emailCurrentPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: "รหัสผ่านปัจจุบัน",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.lock),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณากรอกรหัสผ่านปัจจุบัน';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            
                            // อีเมลใหม่
                            TextFormField(
                              controller: _newEmailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: "อีเมลใหม่",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.email),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณากรอกอีเมลใหม่';
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'รูปแบบอีเมลไม่ถูกต้อง';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _changeEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("เปลี่ยนอีเมล"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // ✅ เปลี่ยนรหัสผ่าน (แยกฟอร์ม)
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _passwordFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "เปลี่ยนรหัสผ่าน",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // รหัสผ่านปัจจุบัน
                            TextFormField(
                              controller: _passwordCurrentPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: "รหัสผ่านปัจจุบัน",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.lock),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณากรอกรหัสผ่านปัจจุบัน';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            
                            // รหัสผ่านใหม่
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: "รหัสผ่านใหม่",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณากรอกรหัสผ่านใหม่';
                                }
                                if (value.length < 6) {
                                  return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            
                            // ยืนยันรหัสผ่านใหม่
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: "ยืนยันรหัสผ่านใหม่",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณายืนยันรหัสผ่านใหม่';
                                }
                                if (value != _newPasswordController.text) {
                                  return 'รหัสผ่านไม่ตรงกัน';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _changePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text("เปลี่ยนรหัสผ่าน"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // ✅ ข้อควรระวัง
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "หลังจากเปลี่ยนอีเมลหรือรหัสผ่านแล้ว ระบบจะให้คุณเข้าสู่ระบบใหม่อีกครั้งในการใช้งานครั้งต่อไป",
                            style: TextStyle(color: Colors.orange.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color color = Colors.black}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.teal),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}