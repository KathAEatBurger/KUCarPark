import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

class MonthlyScreen extends StatefulWidget {
  const MonthlyScreen({super.key});

  @override
  State<MonthlyScreen> createState() => _MonthlyScreenState();
}

class _MonthlyScreenState extends State<MonthlyScreen> {
  final _plateController = TextEditingController();
  File? _imageFile;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) _imageFile = File(pickedFile.path);
    });
  }

  Future<void> _submitRequest() async {
    if (_plateController.text.isEmpty || _imageFile == null) return;

    try {
      final fileName = 'slips/${DateTime.now().millisecondsSinceEpoch}.png';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(_imageFile!);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('monthly_requests').add({
        'plate': _plateController.text,
        'slipUrl': url,
        'timestamp': DateTime.now(),
        'status': 'pending',
        'userId': FirebaseAuth.instance.currentUser?.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ส่งคำขอเรียบร้อย')));
      setState(() {
        _plateController.clear();
        _imageFile = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิกรายเดือน')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _plateController, decoration: const InputDecoration(labelText: 'เลขทะเบียนรถ')),
            const SizedBox(height: 20),
            _imageFile == null
                ? ElevatedButton(onPressed: _pickImage, child: const Text('อัปโหลดสลิปโอนเงิน'))
                : Column(
                    children: [
                      Image.file(_imageFile!, height: 200),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: _pickImage, child: const Text('เปลี่ยนรูปภาพ')),
                    ],
                  ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _submitRequest, child: const Text('ส่งคำขอสมาชิก')),
            ),
          ],
        ),
      ),
    );
  }
}