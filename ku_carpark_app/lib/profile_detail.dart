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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isSaving = false;

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
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _existingImageUrl = data['profileImage']; 
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

      
      if (_image != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_profiles')
            .child('${user.uid}.jpg');
        await ref.putFile(_image!);
        imageUrl = await ref.getDownloadURL();
      }

      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        if (imageUrl != null) 'profileImage': imageUrl,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile Updated Successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
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
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.teal[400],
                          
                          backgroundImage: _image != null
                              ? FileImage(_image!)
                              : (_existingImageUrl != null
                                  ? NetworkImage(_existingImageUrl!)
                                  : null) as ImageProvider?,
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
                  const SizedBox(height: 40),
                  _buildInputField(label: "อีเมล", hint: "example@ku.th", controller: _emailController),
                  const SizedBox(height: 20),
                  _buildInputField(label: "เบอร์โทร", hint: "081-xxx-xxx", controller: _phoneController),
                  const SizedBox(height: 80),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[400],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('SAVE', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'LOGOUT',
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

  Widget _buildInputField({required String label, required String hint, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.blueGrey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}