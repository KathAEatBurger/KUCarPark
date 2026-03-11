import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportScreen extends StatefulWidget {
  final String? placeId;
  final String? placeName;

  const ReportScreen({
    super.key,
    this.placeId,
    this.placeName,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedIssueType = 'ทั่วไป';
  String? _selectedPlaceId;
  String? _selectedPlaceName;
  
  bool _isLoading = false;
  bool _isLoadingPlaces = true;
  
  final List<String> _issueTypes = [
    'ทั่วไป',
    'ข้อมูลราคาผิด',
    'ที่จอดปิดแล้ว',
    'พิกัดไม่ตรง',
    'ข้อมูลไม่ถูกต้อง',
    'รูปภาพไม่ตรง',
    'อื่นๆ',
  ];

  List<Map<String, dynamic>> _places = [];

  @override
  void initState() {
    super.initState();
    _loadPlaces();
    
    if (widget.placeId != null) {
      _selectedPlaceId = widget.placeId;
      _selectedPlaceName = widget.placeName;
    }
  }

  Future<void> _loadPlaces() async {
    setState(() => _isLoadingPlaces = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('zones')
          .orderBy('name')
          .get();
      
      _places = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? 'ไม่ระบุชื่อ',
          'address': data['address'] ?? '',
        };
      }).toList();
      
      if (_selectedPlaceId == null && _places.isNotEmpty) {
        _selectedPlaceId = _places.first['id'] as String;
        _selectedPlaceName = _places.first['name'] as String;
      }
    } catch (e) {
      print('Error loading places: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถโหลดรายการสถานที่: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingPlaces = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _sendReport() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedPlaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกสถานที่ที่ต้องการรายงาน'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเข้าสู่ระบบก่อนส่งรายงาน'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      String userEmail = user.email ?? 'ไม่ระบุอีเมล';
      String displayName = user.displayName ?? userEmail.split('@')[0];

      Map<String, dynamic> reportData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'issueType': _selectedIssueType,
        'userEmail': userEmail,
        'userName': displayName,
        'userId': user.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'placeId': _selectedPlaceId,
        'placeName': _selectedPlaceName,
      };

      await FirebaseFirestore.instance
          .collection('reports')
          .add(reportData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ส่งรายงานปัญหาเรียบร้อย\nเราจะตรวจสอบและแก้ไขโดยเร็ว'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงานปัญหา'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'แจ้งปัญหาเกี่ยวกับข้อมูลที่จอดรถ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ทีมงานจะตรวจสอบและแก้ไขข้อมูลให้ถูกต้องโดยเร็วที่สุด',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    const SizedBox(height: 20),

                    // Dropdown สำหรับเลือกสถานที่
                    const Text('เลือกสถานที่ *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    _isLoadingPlaces
                        ? const Center(child: CircularProgressIndicator())
                        : _places.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(16),
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
                                        'ไม่มีข้อมูลสถานที่ในระบบ กรุณาเพิ่มสถานที่ก่อน',
                                        style: TextStyle(color: Colors.orange.shade700),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedPlaceId,
                                    isExpanded: true,
                                    hint: const Text('กรุณาเลือกสถานที่'),
                                    items: _places.map<DropdownMenuItem<String>>((place) {
                                      return DropdownMenuItem<String>(
                                        value: place['id'] as String,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              place['name'] as String,
                                              style: const TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                            if (place['address'] != null && (place['address'] as String).isNotEmpty)
                                              Text(
                                                place['address'] as String,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? value) {
                                      setState(() {
                                        _selectedPlaceId = value;
                                        if (value != null) {
                                          final selected = _places.firstWhere(
                                            (p) => p['id'] == value,
                                            orElse: () => {'id': '', 'name': 'ไม่ระบุ', 'address': ''},
                                          );
                                          _selectedPlaceName = selected['name'] as String;
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                    
                    const SizedBox(height: 20),

                    // เลือกประเภทปัญหา
                    const Text('ประเภทปัญหา *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedIssueType,
                          isExpanded: true,
                          items: _issueTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Row(
                                children: [
                                  Icon(
                                    _getIssueTypeIcon(type),
                                    size: 18,
                                    color: _getIssueTypeColor(type),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(type),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            setState(() {
                              _selectedIssueType = value!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // หัวข้อปัญหา
                    const Text('หัวข้อปัญหา *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'เช่น ราคาที่จอดไม่ถูกต้อง, สถานที่ปิดแล้ว',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกหัวข้อปัญหา';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // รายละเอียดปัญหา
                    const Text('รายละเอียด *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'กรุณาอธิบายปัญหาให้ละเอียด เพื่อให้ทีมงานเข้าใจและแก้ไขได้ถูกต้อง',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.description),
                        ),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกรายละเอียดปัญหา';
                        }
                        if (value.length < 10) {
                          return 'กรุณากรอกรายละเอียดอย่างน้อย 10 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ตัวอย่างข้อมูลที่ควรแจ้ง
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📌 ตัวอย่างข้อมูลที่เป็นประโยชน์:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildExampleItem('💰', 'ราคาที่ถูกต้องควรเป็นเท่าไหร่'),
                          _buildExampleItem('📍', 'พิกัดที่ถูกต้อง (ถ้าทราบ)'),
                          _buildExampleItem('📸', 'แนบรูปภาพประกอบ (เร็วๆ นี้)'),
                          _buildExampleItem('ℹ️', 'แหล่งที่มาของข้อมูล'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ปุ่มส่งรายงาน
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _sendReport,
                        icon: const Icon(Icons.send),
                        label: const Text(
                          'ส่งรายงานปัญหา',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Center(
                      child: Text(
                        'ทีมงานจะตรวจสอบและดำเนินการโดยเร็ว',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildExampleItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade700))),
        ],
      ),
    );
  }

  IconData _getIssueTypeIcon(String type) {
    switch (type) {
      case 'ทั่วไป':
        return Icons.report_problem;
      case 'ข้อมูลราคาผิด':
        return Icons.attach_money;
      case 'ที่จอดปิดแล้ว':
        return Icons.block;
      case 'พิกัดไม่ตรง':
        return Icons.pin_drop;
      case 'ข้อมูลไม่ถูกต้อง':
        return Icons.error_outline;
      case 'รูปภาพไม่ตรง':
        return Icons.image_not_supported;
      default:
        return Icons.report_problem;
    }
  }

  Color _getIssueTypeColor(String type) {
    switch (type) {
      case 'ทั่วไป':
        return Colors.teal;
      case 'ข้อมูลราคาผิด':
        return Colors.red;
      case 'ที่จอดปิดแล้ว':
        return Colors.purple;
      case 'พิกัดไม่ตรง':
        return Colors.blue;
      case 'ข้อมูลไม่ถูกต้อง':
        return Colors.orange;
      case 'รูปภาพไม่ตรง':
        return Colors.brown;
      default:
        return Colors.teal;
    }
  }
}