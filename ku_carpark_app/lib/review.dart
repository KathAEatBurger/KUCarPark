import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ReviewPage extends StatefulWidget {
  final String parkingName;
  final LatLng parkingLocation;

  const ReviewPage({
    super.key,
    required this.parkingName,
    required this.parkingLocation,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _formKey = GlobalKey<FormState>();
  final _reviewController = TextEditingController();
  final _priceController = TextEditingController(); // เพิ่ม controller สำหรับราคา
  double _rating = 3.0;
  bool _isLoading = false;

  // ลบ _selectedPriceLevel และ _priceLevels ออก

  // สำหรับอัปโหลดรูป
  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  bool _isUploading = false;

  @override
  void dispose() {
    _reviewController.dispose();
    _priceController.dispose(); // dispose controller
    super.dispose();
  }

  // ฟังก์ชันเลือกรูปจากแกลเลอรี
  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        if (_selectedImages.length + pickedFiles.length > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('สามารถอัปโหลดได้สูงสุด 5 รูปเท่านั้น'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        setState(() {
          _selectedImages.addAll(pickedFiles.map((f) => File(f.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการเลือกรูป: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ฟังก์ชันถ่ายรูป
  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
      );

      if (pickedFile != null) {
        if (_selectedImages.length >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('สามารถอัปโหลดได้สูงสุด 5 รูปเท่านั้น'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการถ่ายรูป: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ฟังก์ชันลบรูปที่เลือก
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // ฟังก์ชันอัปโหลดรูปไปยัง Firebase Storage
  Future<List<String>> _uploadImages(String userId) async {
    List<String> imageUrls = [];
    
    for (int i = 0; i < _selectedImages.length; i++) {
      File imageFile = _selectedImages[i];
      
      String fileName = 'reviews/${userId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      
      try {
        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(imageFile);
        String downloadUrl = await ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      } catch (e) {
        print('Error uploading image $i: $e');
      }
    }
    
    return imageUrls;
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนเขียนรีวิว')),
        );
        return;
      }

      // อัปโหลดรูปภาพ (ถ้ามี)
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages(user.uid);
      }

      // เตรียมข้อมูลรีวิว
      Map<String, dynamic> reviewData = {
        'userId': user.uid,
        'userEmail': user.email,
        'displayName': user.displayName ?? '',
        'parkingName': widget.parkingName,
        'parkingLat': widget.parkingLocation.latitude,
        'parkingLng': widget.parkingLocation.longitude,
        'rating': _rating,
        'review': _reviewController.text,
        'price': _priceController.text.isNotEmpty 
            ? int.tryParse(_priceController.text) ?? 0 
            : null, // ✅ เก็บราคาเป็นตัวเลข
        'createdAt': FieldValue.serverTimestamp(),
      };

      // เพิ่มรูปภาพถ้ามี
      if (imageUrls.isNotEmpty) {
        reviewData['imageUrls'] = imageUrls;
      }

      // บันทึกลง Firestore
      await FirebaseFirestore.instance.collection('reviews').add(reviewData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ขอบคุณสำหรับรีวิวของคุณ'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รีวิว ${widget.parkingName}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    _isUploading 
                        ? 'กำลังอัปโหลดรูปภาพ...' 
                        : 'กำลังส่งรีวิว...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ให้คะแนน
                    const Text(
                      'ให้คะแนน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int i = 1; i <= 5; i++)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _rating = i.toDouble();
                                });
                              },
                              icon: Icon(
                                i <= _rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 40,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // เปลี่ยนจากระดับราคาเป็นช่องกรอกราคา
                    const Text(
                      'ราคาค่าจอด (บาท/ชั่วโมง)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'เช่น 20, 30, 40',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (int.tryParse(value) == null) {
                            return 'กรุณากรอกตัวเลขเท่านั้น';
                          }
                          if (int.parse(value) <= 0) {
                            return 'กรุณากรอกราคามากกว่า 0';
                          }
                        }
                        return null; // ไม่บังคับกรอก
                      },
                    ),
                    const SizedBox(height: 20),

                    // อัปโหลดรูปภาพ
                    const Text(
                      'เพิ่มรูปภาพ (ไม่บังคับ)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ถ่ายภาพทางเข้า, สภาพช่องจอด หรือตารางค่าบริการ',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    
                    // ปุ่มเลือกรูป
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickImages,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('เลือกรูปจากแกลเลอรี'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _takePhoto,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('ถ่ายรูป'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // แสดงรูปที่เลือก
                    if (_selectedImages.isNotEmpty)
                      Container(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedImages[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 10),
                    
                    // จำนวนรูปที่เลือก
                    if (_selectedImages.isNotEmpty)
                      Text(
                        'เลือก ${_selectedImages.length} รูป (สูงสุด 5 รูป)',
                        style: TextStyle(
                          color: Colors.teal.shade700,
                          fontSize: 12,
                        ),
                      ),
                    
                    const SizedBox(height: 20),

                    // เขียนรีวิว
                    const Text(
                      'เขียนรีวิว',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _reviewController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'แบ่งปันประสบการณ์ที่จอดรถของคุณ...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณาเขียนรีวิว';
                        }
                        if (value.length < 10) {
                          return 'กรุณาเขียนรีวิวอย่างน้อย 10 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    // ปุ่มส่งรีวิว
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'ส่งรีวิว',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}