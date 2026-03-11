import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProfileDetailPage extends StatefulWidget {
  const ProfileDetailPage({super.key});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  File? _image;
  String? _existingImageUrl; 
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _displayNameController = TextEditingController(); // ✅ เฉพาะชื่อ
  String? _selectedVehicleType;
  bool _isSaving = false;

  // ✅ ตัวเลือกประเภทรถ
  final List<String> _vehicleTypes = [
    'รถเก๋ง',
    'รถกระบะ',
    'SUV',
    'MPV',
    'รถตู้',
    'รถยนต์ไฟฟ้า (EV)',
    'อื่นๆ',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData(); 
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _displayNameController.text = data['displayName'] ?? user.displayName ?? '';
          _selectedVehicleType = data['vehicleType'];
          _existingImageUrl = data['profileImage']; 
        });
      } else {
        // ถ้ายังไม่มีข้อมูลใน Firestore ใช้จาก Firebase Auth
        setState(() {
          _displayNameController.text = user.displayName ?? '';
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      String? imageUrl = _existingImageUrl; 

      // อัปโหลดรูปภาพใหม่ (ถ้ามี)
      if (_image != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_profiles')
            .child('${user.uid}.jpg');
        await ref.putFile(_image!);
        imageUrl = await ref.getDownloadURL();
      }

      // อัปเดต Display Name ใน Firebase Authentication
      if (_displayNameController.text.isNotEmpty && 
          _displayNameController.text != user.displayName) {
        await user.updateDisplayName(_displayNameController.text);
        await user.reload();
      }

      // ✅ บันทึกข้อมูลใน Firestore (ยังมี email อัตโนมัติ)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email, // ✅ ใช้อีเมลจาก Firebase Auth อัตโนมัติ
        'displayName': _displayNameController.text.trim(),
        'vehicleType': _selectedVehicleType,
        if (imageUrl != null) 'profileImage': imageUrl,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัปเดตโปรไฟล์เรียบร้อย!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
      setState(() => _isSaving = false);
    }
  }

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
                  Navigator.of(context).pushNamedAndRemoveUntil('/sign-in', (route) => false);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('แก้ไขโปรไฟล์', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // รูปโปรไฟล์
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.teal[400],
                          backgroundImage: _getProfileImage(),
                          child: (_image == null && _existingImageUrl == null)
                              ? const Icon(Icons.person, size: 65, color: Colors.white)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                              child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // แสดงอีเมล (แบบอ่านอย่างเดียว ไม่ต้องกรอก)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "อีเมล",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          FirebaseAuth.instance.currentUser?.email ?? 'ไม่ระบุอีเมล',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // ชื่อที่แสดง (Display Name)
                  _buildInputField(
                    label: "ชื่อที่แสดง",
                    hint: "กรุณากรอกชื่อที่ต้องการแสดง",
                    controller: _displayNameController,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  
                  // ประเภทรถ (Dropdown)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ประเภทรถ",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedVehicleType,
                            isExpanded: true,
                            hint: const Text('เลือกประเภทรถ'),
                            icon: const Icon(Icons.arrow_drop_down),
                            items: _vehicleTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getVehicleIcon(type),
                                      size: 18,
                                      color: Colors.teal[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(type),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedVehicleType = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // ปุ่มบันทึก
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'บันทึกการเปลี่ยนแปลง',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ปุ่มออกจากระบบ
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'ออกจากระบบ',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // ฟังก์ชันดึงรูปโปรไฟล์
  ImageProvider? _getProfileImage() {
    if (_image != null) {
      return FileImage(_image!);
    } else if (_existingImageUrl != null) {
      return NetworkImage(_existingImageUrl!);
    }
    return null;
  }

  // ฟังก์ชันสร้าง input field
  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, color: Colors.teal[400]) : null,
            filled: true,
            fillColor: Colors.blueGrey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // ฟังก์ชันกำหนดไอคอนตามประเภทรถ
  IconData _getVehicleIcon(String type) {
    switch (type) {
      case 'รถเก๋ง':
        return Icons.directions_car;
      case 'รถกระบะ':
        return Icons.local_shipping;
      case 'SUV':
        return Icons.map;
      case 'MPV':
        return Icons.airport_shuttle;
      case 'รถตู้':
        return Icons.directions_bus;
      case 'รถยนต์ไฟฟ้า (EV)':
        return Icons.ev_station;
      default:
        return Icons.directions_car;
    }
  }
}