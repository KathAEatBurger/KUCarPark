import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlaceEditScreen extends StatefulWidget {
  final String placeId;
  final Map<String, dynamic> initialData;

  const PlaceEditScreen({
    super.key,
    required this.placeId,
    required this.initialData,
  });

  @override
  State<PlaceEditScreen> createState() => _PlaceEditScreenState();
}

class _PlaceEditScreenState extends State<PlaceEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _priceController;
  late TextEditingController _totalController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  
  bool _isLoading = false;
  bool _isArchived = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing data
    _nameController = TextEditingController(text: widget.initialData['name'] ?? '');
    _latController = TextEditingController(text: widget.initialData['latitude']?.toString() ?? '');
    _lngController = TextEditingController(text: widget.initialData['longitude']?.toString() ?? '');
    _priceController = TextEditingController(text: widget.initialData['price']?.toString() ?? '');
    _totalController = TextEditingController(text: widget.initialData['total']?.toString() ?? '');
    _addressController = TextEditingController(text: widget.initialData['address'] ?? '');
    _descriptionController = TextEditingController(text: widget.initialData['description'] ?? '');
    
    _isArchived = widget.initialData['isArchived'] ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _priceController.dispose();
    _totalController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('zones').doc(widget.placeId).update({
        'name': _nameController.text,
        'latitude': double.parse(_latController.text),
        'longitude': double.parse(_lngController.text),
        'price': int.parse(_priceController.text),
        'total': int.parse(_totalController.text),
        'address': _addressController.text,
        'description': _descriptionController.text,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': FirebaseAuth.instance.currentUser?.email,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกการเปลี่ยนแปลงเรียบร้อย'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // ส่งค่ากลับว่าแก้ไขสำเร็จ
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

  Future<void> _toggleArchive() async {
    final newStatus = !_isArchived;
    final action = newStatus ? 'Archive' : 'ยกเลิก Archive';
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ยืนยันการ$action'),
        content: Text('ต้องการ${action}สถานที่นี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: newStatus ? Colors.orange : Colors.green,
            ),
            child: Text(newStatus ? 'Archive' : 'ยกเลิก Archive'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('zones').doc(widget.placeId).update({
          'isArchived': newStatus,
          'archivedAt': newStatus ? FieldValue.serverTimestamp() : null,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() => _isArchived = newStatus);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${action}เรียบร้อย'),
              backgroundColor: newStatus ? Colors.orange : Colors.green,
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
      }
    }
  }

  Future<void> _deletePlace() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบสถานที่ "${_nameController.text}" ใช่หรือไม่?\n\nการลบนี้ไม่สามารถกู้คืนได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      
      try {
        await FirebaseFirestore.instance.collection('zones').doc(widget.placeId).delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ลบ "${_nameController.text}" เรียบร้อย'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขสถานที่จอดรถ'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // Archive Toggle Button
          IconButton(
            icon: Icon(
              _isArchived ? Icons.unarchive : Icons.archive,
              color: _isArchived ? Colors.orange : Colors.white,
            ),
            onPressed: _toggleArchive,
            tooltip: _isArchived ? 'ยกเลิก Archive' : 'Archive',
          ),
          // Delete Button
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deletePlace,
            tooltip: 'ลบสถานที่',
          ),
        ],
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
                    // สถานะ Archive
                    if (_isArchived)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.archive, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'สถานที่นี้ถูก Archive แล้ว จะไม่แสดงในแอพของผู้ใช้',
                                style: TextStyle(color: Colors.orange.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ชื่อสถานที่
                    const Text('ชื่อสถานที่ *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'กรุณากรอกชื่อสถานที่',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.local_parking),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'กรุณากรอกชื่อสถานที่';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // พิกัด (Lat, Lng)
                    const Text('พิกัด *', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            decoration: InputDecoration(
                              labelText: 'ละติจูด',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.pin_drop),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกละติจูด';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _lngController,
                            decoration: InputDecoration(
                              labelText: 'ลองจิจูด',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.pin_drop),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณากรอกลองจิจูด';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ราคาและจำนวนที่จอด
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ราคา/ชม. (บาท) *', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _priceController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.attach_money),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'กรุณากรอกราคา';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('จำนวนที่จอด *', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _totalController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  prefixIcon: const Icon(Icons.local_parking),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'กรุณากรอกจำนวนที่จอด';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ที่อยู่
                    const Text('ที่อยู่', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: 'กรุณากรอกที่อยู่ (ถ้ามี)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // รายละเอียดเพิ่มเติม
                    const Text('รายละเอียดเพิ่มเติม', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'กรุณากรอกรายละเอียดเพิ่มเติม (ถ้ามี)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // Metadata
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ข้อมูลระบบ', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (widget.initialData['createdAt'] != null)
                            _buildInfoRow('สร้างเมื่อ', _formatDate(widget.initialData['createdAt'])),
                          if (widget.initialData['updatedAt'] != null)
                            _buildInfoRow('แก้ไขล่าสุด', _formatDate(widget.initialData['updatedAt'])),
                          if (widget.initialData['updatedBy'] != null)
                            _buildInfoRow('โดย', widget.initialData['updatedBy']),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: const Icon(Icons.save),
                        label: const Text('บันทึกการเปลี่ยนแปลง'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '-';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '-';
    }
  }
}