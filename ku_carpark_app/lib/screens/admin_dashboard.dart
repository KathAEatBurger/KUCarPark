import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:ku_carpark_app/screens/place_edit_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          // ✅ Place Management (ส่วนใหม่)
          Text('จัดการสถานที่จอดรถ (Place Management)', 
               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          PlaceManagementWidget(),
          Divider(height: 40),
          
          // จัดการที่จอด (จำลอง Sensor)
          Text('จัดการจำนวนที่จอด (จำลอง Sensor)', 
               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          ZoneManageWidget(),
          Divider(height: 40),
          
          // จัดการรีวิว (Review Audit)
          Text('จัดการรีวิว (Review Audit)', 
               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          ReviewManagementWidget(),
          Divider(height: 40),
          
          // คำขอสมาชิกรายเดือน
          Text('คำขอสมาชิกรายเดือน', 
               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          MonthlyApprovalWidget(),
          Divider(height: 40),
          
          // รายงานปัญหา
          Text('รายงานปัญหา', 
               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          ReportsWidget(),
        ],
      ),
    );
  }
}

// ============================================================
// ✅ PLACE MANAGEMENT - จัดการสถานที่จอดรถ
// ============================================================
class PlaceManagementWidget extends StatefulWidget {
  const PlaceManagementWidget({super.key});

  @override
  State<PlaceManagementWidget> createState() => _PlaceManagementWidgetState();
}

class _PlaceManagementWidgetState extends State<PlaceManagementWidget> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'ทั้งหมด'; // ทั้งหมด, ข้อมูลครบ, ข้อมูลไม่ครบ
  
  final List<String> _filterOptions = ['ทั้งหมด', 'ข้อมูลครบ', 'ข้อมูลไม่ครบ'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ✅ Search & Filter Bar
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'ค้นหาที่จอดรถด้วยชื่อ...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 10),
              
              // Filter Row
              Row(
                children: [
                  const Text(
                    'กรองตาม:  ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  // ใช้ Expanded เพื่อให้ chips สามารถห่อบรรทัดได้
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _filterOptions.map((option) => ChoiceChip(
                        label: Text(option),
                        selected: _filterStatus == option,
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = option;
                          });
                        },
                        selectedColor: Colors.teal.shade100,
                        backgroundColor: Colors.grey.shade100,
                        labelStyle: TextStyle(
                          color: _filterStatus == option ? Colors.teal.shade700 : Colors.grey.shade700,
                          fontWeight: _filterStatus == option ? FontWeight.bold : FontWeight.normal,
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        
        // ✅ Add New Place Button
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _showAddPlaceDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('เพิ่มสถานที่ใหม่'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 15),
        
        // ✅ Places List
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('zones') // หรือ collection ที่เก็บข้อมูลที่จอด
              .orderBy('name')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade300),
                    const SizedBox(height: 10),
                    Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Icon(Icons.local_parking, size: 50, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    Text(
                      'ไม่มีข้อมูลสถานที่จอดรถ',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }

            // กรองข้อมูลตาม search และ filter
            final allPlaces = snapshot.data!.docs;
            final filteredPlaces = allPlaces.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              
              // Search filter
              if (_searchQuery.isNotEmpty && !name.contains(_searchQuery)) {
                return false;
              }
              
              // Status filter
              if (_filterStatus != 'ทั้งหมด') {
                final hasAllFields = _checkCompleteData(data);
                if (_filterStatus == 'ข้อมูลครบ' && !hasAllFields) return false;
                if (_filterStatus == 'ข้อมูลไม่ครบ' && hasAllFields) return false;
              }
              
              return true;
            }).toList();

            return Column(
              children: [
                // Summary
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'พบ ${filteredPlaces.length} รายการ',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'ทั้งหมด ${allPlaces.length} รายการ',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                
                // Places Table
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          color: Colors.teal.shade100,
                          child: const Row(
                            children: [
                              SizedBox(width: 150, child: Text('ชื่อสถานที่', style: TextStyle(fontWeight: FontWeight.bold))),
                              SizedBox(width: 100, child: Text('พิกัด', style: TextStyle(fontWeight: FontWeight.bold))),
                              SizedBox(width: 80, child: Text('ราคา/ชม.', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                              SizedBox(width: 80, child: Text('จำนวนที่จอด', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                              SizedBox(width: 80, child: Text('สถานะ', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                              SizedBox(width: 160, child: Text('การจัดการ', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                            ],
                          ),
                        ),
                        // Table Rows
                        ...filteredPlaces.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final placeId = doc.id;
                          final name = data['name'] ?? 'ไม่ระบุ';
                          final lat = data['latitude']?.toStringAsFixed(4) ?? '-';
                          final lng = data['longitude']?.toStringAsFixed(4) ?? '-';
                          final price = data['price']?.toString() ?? '0';
                          final totalSpots = data['total']?.toString() ?? '0';
                          final isComplete = _checkCompleteData(data);
                          
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            child: Row(
                              children: [
                                // ชื่อสถานที่
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                // พิกัด
                                SizedBox(
                                  width: 100,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('lat: $lat', style: const TextStyle(fontSize: 10)),
                                      Text('lng: $lng', style: const TextStyle(fontSize: 10)),
                                    ],
                                  ),
                                ),
                                // ราคา/ชม.
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    '$price บาท',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                // จำนวนที่จอด
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    totalSpots,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                // สถานะ
                                SizedBox(
                                  width: 80,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isComplete ? Colors.green.shade100 : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isComplete ? 'ข้อมูลครบ' : 'ไม่ครบ',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: isComplete ? Colors.green.shade700 : Colors.orange.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                // ✅ Actions: Edit, Delete, Archive
                                SizedBox(
                                  width: 160,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showEditPlaceDialog(context, placeId, data),
                                        tooltip: 'แก้ไข',
                                        iconSize: 20,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deletePlace(context, placeId, name),
                                        tooltip: 'ลบ',
                                        iconSize: 20,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.archive, color: Colors.orange),
                                        onPressed: () => _archivePlace(context, placeId, name),
                                        tooltip: 'Archive',
                                        iconSize: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // เช็คว่าข้อมูลครบถ้วนหรือไม่
  bool _checkCompleteData(Map<String, dynamic> data) {
    return data['name'] != null && 
           data['name'].toString().isNotEmpty &&
           data['latitude'] != null &&
           data['longitude'] != null &&
           data['price'] != null &&
           data['total'] != null;
  }

  // ✅ Show Add Place Dialog
  void _showAddPlaceDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final latController = TextEditingController();
    final lngController = TextEditingController();
    final priceController = TextEditingController();
    final totalController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มสถานที่จอดรถใหม่'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อสถานที่ *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกชื่อ' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: latController,
                        decoration: const InputDecoration(
                          labelText: 'ละติจูด *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกละติจูด' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: lngController,
                        decoration: const InputDecoration(
                          labelText: 'ลองจิจูด *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกลองจิจูด' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'ราคา/ชม. (บาท) *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกราคา' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: totalController,
                        decoration: const InputDecoration(
                          labelText: 'จำนวนที่จอด *',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกจำนวน' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await FirebaseFirestore.instance.collection('zones').add({
                    'name': nameController.text,
                    'latitude': double.parse(latController.text),
                    'longitude': double.parse(lngController.text),
                    'price': int.parse(priceController.text),
                    'total': int.parse(totalController.text),
                    'available': int.parse(totalController.text), // เริ่มต้นเท่ากับ total
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('เพิ่มสถานที่เรียบร้อย'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาด: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            child: const Text('เพิ่ม'),
          ),
        ],
      ),
    );
  }

  // ✅ Show Edit Place Dialog
  void _showEditPlaceDialog(BuildContext context, String placeId, Map<String, dynamic> currentData) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: currentData['name'] ?? '');
    final latController = TextEditingController(text: currentData['latitude']?.toString() ?? '');
    final lngController = TextEditingController(text: currentData['longitude']?.toString() ?? '');
    final priceController = TextEditingController(text: currentData['price']?.toString() ?? '');
    final totalController = TextEditingController(text: currentData['total']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขข้อมูลสถานที่'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อสถานที่',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกชื่อ' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: latController,
                        decoration: const InputDecoration(
                          labelText: 'ละติจูด',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกละติจูด' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: lngController,
                        decoration: const InputDecoration(
                          labelText: 'ลองจิจูด',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกลองจิจูด' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'ราคา/ชม. (บาท)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกราคา' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: totalController,
                        decoration: const InputDecoration(
                          labelText: 'จำนวนที่จอด',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty ?? true ? 'กรุณากรอกจำนวน' : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await FirebaseFirestore.instance.collection('zones').doc(placeId).update({
                    'name': nameController.text,
                    'latitude': double.parse(latController.text),
                    'longitude': double.parse(lngController.text),
                    'price': int.parse(priceController.text),
                    'total': int.parse(totalController.text),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('แก้ไขข้อมูลเรียบร้อย'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เกิดข้อผิดพลาด: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  // ✅ Delete Place
  Future<void> _deletePlace(BuildContext context, String placeId, String placeName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบสถานที่ "$placeName" ใช่หรือไม่?\n\nการลบนี้ไม่สามารถกู้คืนได้'),
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
      try {
        await FirebaseFirestore.instance.collection('zones').doc(placeId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ลบ "$placeName" เรียบร้อย'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
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

  // ✅ Archive Place (ซ่อนหรือเปลี่ยนสถานะ)
  Future<void> _archivePlace(BuildContext context, String placeId, String placeName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการ Archive'),
        content: Text('ต้องการ Archive สถานที่ "$placeName" ใช่หรือไม่?\n\nสถานที่จะไม่แสดงในแอพของผู้ใช้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('zones').doc(placeId).update({
          'isArchived': true,
          'archivedAt': FieldValue.serverTimestamp(),
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Archive "$placeName" เรียบร้อย'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
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
}

// ✅ ส่วนจัดการรีวิวสำหรับ Admin
class ReviewManagementWidget extends StatelessWidget {
  const ReviewManagementWidget({super.key});

  Future<void> _deleteReview(BuildContext context, String reviewId, String userEmail) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบรีวิว'),
        content: Text('ต้องการลบรีวิวของผู้ใช้ $userEmail ใช่หรือไม่?\n\nการลบนี้ไม่สามารถกู้คืนได้'),
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
      try {
        await FirebaseFirestore.instance.collection('reviews').doc(reviewId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ลบรีวิวเรียบร้อย'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(50) // แสดง 50 รายการล่าสุด
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade300),
                const SizedBox(height: 10),
                Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined, size: 50, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                Text(
                  'ยังไม่มีรีวิว',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        final reviews = snapshot.data!.docs;
        
        return Column(
          children: [
            // สรุปจำนวนรีวิว
            Container(
              padding: const EdgeInsets.all(15),
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'รีวิวทั้งหมด: ${reviews.length}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  // คะแนนเฉลี่ย
                  FutureBuilder<double>(
                    future: _calculateAverageRating(),
                    builder: (context, avgSnapshot) {
                      if (avgSnapshot.hasData) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                avgSnapshot.data!.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ],
              ),
            ),

            // ✅ Recent Reviews Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.grey.shade200,
                      child: const Row(
                        children: [
                          SizedBox(width: 200, child: Text('ผู้รีวิว', style: TextStyle(fontWeight: FontWeight.bold))),
                          SizedBox(width: 250, child: Text('ข้อความ', style: TextStyle(fontWeight: FontWeight.bold))),
                          SizedBox(width: 80, child: Text('คะแนน', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          SizedBox(width: 100, child: Text('วันที่', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          SizedBox(width: 80, child: Text('จัดการ', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    // Table Rows
                    ...reviews.map((review) {
                      final data = review.data() as Map<String, dynamic>;
                      
                      String userEmail = data['userEmail'] ?? 'ไม่ระบุ';
                      String displayName = userEmail.contains('@') 
                          ? userEmail.split('@')[0] 
                          : userEmail;
                      String reviewText = data['review'] ?? '';
                      String reviewTextShort = reviewText.length > 35 
                          ? '${reviewText.substring(0, 35)}...' 
                          : reviewText;
                      int rating = (data['rating'] ?? 0).toInt();
                      String date = _formatDateShort(data['createdAt']);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          children: [
                            // ผู้รีวิว
                            SizedBox(
                              width: 200,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    userEmail,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // ข้อความรีวิว
                            SizedBox(
                              width: 250,
                              child: Text(
                                reviewTextShort,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            // คะแนน
                            SizedBox(
                              width: 80,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getRatingColor(rating),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$rating',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            // วันที่
                            SizedBox(
                              width: 100,
                              child: Text(
                                date,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            // ✅ Quick Actions - ปุ่มลบ
                            SizedBox(
                              width: 80,
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deleteReview(context, review.id, userEmail),
                                  tooltip: 'ลบรีวิว',
                                  iconSize: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<double> _calculateAverageRating() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('reviews').get();
      if (snapshot.docs.isEmpty) return 0;
      
      double sum = 0;
      for (var doc in snapshot.docs) {
        sum += (doc['rating'] ?? 0).toDouble();
      }
      return sum / snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5: return Colors.green;
      case 4: return Colors.lightGreen;
      case 3: return Colors.amber;
      case 2: return Colors.orange;
      case 1: return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatDateShort(dynamic timestamp) {
    if (timestamp == null) return '-';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '-';
    }
  }
}

class ZoneManageWidget extends StatelessWidget {
  const ZoneManageWidget({super.key});

  Future<void> _updateSpot(String docId, int newAvailable, int total) async {
    if (newAvailable < 0) newAvailable = 0;
    if (newAvailable > total) newAvailable = total;
    await FirebaseFirestore.instance.collection('zones').doc(docId).update({'available': newAvailable});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('zones').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final zones = snapshot.data!.docs;
        return Column(
          children: zones.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final total = data['total'] ?? 0;
            final available = data['available'] ?? 0;
            return Card(
              child: ListTile(
                title: Text('โซน: ${data['name']}'),
                subtitle: Text('ว่าง: $available / $total'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.remove), onPressed: () => _updateSpot(doc.id, available - 1, total)),
                    IconButton(icon: const Icon(Icons.add), onPressed: () => _updateSpot(doc.id, available + 1, total)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class MonthlyApprovalWidget extends StatelessWidget {
  const MonthlyApprovalWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('monthly_requests').where('status', isEqualTo: 'pending').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Text('ไม่มีคำขอรออนุมัติ');
        final requests = snapshot.data!.docs;
        if (requests.isEmpty) return const Text('ไม่มีคำขอรออนุมัติ');
        return Column(
          children: requests.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text('ทะเบียน: ${data['plate']}'),
                subtitle: Text('เวลา: ${_formatDate(data['timestamp'])}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _updateStatus(doc.id, 'approved')),
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _updateStatus(doc.id, 'rejected')),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _updateStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('monthly_requests').doc(id).update({'status': status});
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'ไม่ระบุเวลา';
    try {
      final date = (timestamp as Timestamp).toDate();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return 'ไม่ระบุเวลา';
    }
  }
}

// ============================================================
// ✅ REPORTS WIDGET - จัดการรายงานปัญหา (พร้อม Direct Link)
// ============================================================
class ReportsWidget extends StatefulWidget {
  const ReportsWidget({super.key});

  @override
  State<ReportsWidget> createState() => _ReportsWidgetState();
}

class _ReportsWidgetState extends State<ReportsWidget> {
  String _selectedFilter = 'pending'; // pending, all, resolved
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Tabs
        Container(
          margin: const EdgeInsets.only(bottom: 15),
          child: Row(
            children: [
              _buildFilterChip('รอดำเนินการ', 'pending', Colors.orange),
              const SizedBox(width: 8),
              _buildFilterChip('ทั้งหมด', 'all', Colors.blue),
              const SizedBox(width: 8),
              _buildFilterChip('แก้ไขแล้ว', 'resolved', Colors.green),
            ],
          ),
        ),
        
        // Reports List
        StreamBuilder<QuerySnapshot>(
          stream: _getReportsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 50, color: Colors.red.shade300),
                    const SizedBox(height: 10),
                    Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.report_problem, size: 60, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      _selectedFilter == 'pending' 
                          ? 'ไม่มีรายงานที่รอดำเนินการ'
                          : 'ไม่มีรายงานปัญหา',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            final reports = snapshot.data!.docs;
            
            return Column(
              children: reports.map((doc) {
                final report = doc.data() as Map<String, dynamic>;
                final reportId = doc.id;
                
                return _buildReportCard(context, reportId, report);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // Filter Chip
  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // Stream ตาม filter
  Stream<QuerySnapshot> _getReportsStream() {
    Query query = FirebaseFirestore.instance.collection('reports');
    
    if (_selectedFilter != 'all') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }
    
    return query.orderBy('createdAt', descending: true).snapshots();
  }

  // ✅ Report Card พร้อม Direct Link
  Widget _buildReportCard(BuildContext context, String reportId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    final issueType = data['issueType'] ?? 'ทั่วไป';
    final placeId = data['placeId']; // ต้องมี field นี้ใน reports collection
    final placeName = data['placeName'] ?? 'ไม่ระบุสถานที่';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and issue type
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 16,
                        color: _getStatusColor(status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getStatusText(status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getIssueTypeColor(issueType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    issueType,
                    style: TextStyle(
                      color: _getIssueTypeColor(issueType),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Title
            Text(
              data['title'] ?? 'ไม่มีหัวข้อ',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Text(
              data['description'] ?? 'ไม่มีรายละเอียด',
              style: TextStyle(color: Colors.grey.shade700, height: 1.5),
            ),
            
            const SizedBox(height: 12),
            
            // Reporter info
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  data['userEmail'] ?? 'ไม่ระบุ',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  _formatDate(data['createdAt']),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // ✅ Direct Link to Place (แสดงเฉพาะเมื่อมี placeId)
            if (placeId != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.teal.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'สถานที่เกี่ยวข้อง:',
                          style: TextStyle(
                            color: Colors.teal.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            placeName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToEditPlace(context, placeId, placeName),
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('แก้ไขสถานที่'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Status Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status != 'resolved')
                  ElevatedButton.icon(
                    onPressed: () => _markAsResolved(reportId),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('แก้ไขเรียบร้อย'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteReport(context, reportId),
                  tooltip: 'ลบรายงาน',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ฟังก์ชันนำทางไปหน้า Edit Place
  void _navigateToEditPlace(BuildContext context, String placeId, String placeName) {
    // แสดง loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // ดึงข้อมูลสถานที่จาก Firestore
    FirebaseFirestore.instance
        .collection('zones')
        .doc(placeId)
        .get()
        .then((doc) {
          // ปิด loading dialog
          Navigator.pop(context);

          if (doc.exists && context.mounted) {
            final data = doc.data() as Map<String, dynamic>;
            
            // ไปหน้า Edit Place โดยตรง
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaceEditScreen(
                  placeId: placeId,
                  initialData: data,
                ),
              ),
            ).then((updated) {
              if (updated == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('อัปเดตข้อมูลเรียบร้อย'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            });
          } else {
            // แจ้ง error ถ้าไม่พบสถานที่
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ไม่พบข้อมูลสถานที่ "$placeName" ในระบบ'),
                backgroundColor: Colors.red,
              ),
            );
          }
        })
        .catchError((error) {
          // ปิด loading dialog
          Navigator.pop(context);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เกิดข้อผิดพลาด: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
  }

  // Issue Type Colors
  Color _getIssueTypeColor(String type) {
    switch (type) {
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
      case 'ทั่วไป':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  // Status Text
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'รอดำเนินการ';
      case 'in_progress':
        return 'กำลังดำเนินการ';
      case 'resolved':
        return 'แก้ไขแล้ว';
      default:
        return 'ไม่ระบุ';
    }
  }

  // Status Color
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Status Icon
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_outlined;
      case 'in_progress':
        return Icons.autorenew;
      case 'resolved':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  // Mark as Resolved
  Future<void> _markAsResolved(String reportId) async {
    await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': FirebaseAuth.instance.currentUser?.email,
    });
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เปลี่ยนสถานะเป็นแก้ไขเรียบร้อย'),
          backgroundColor: Colors.green,
        ),
      );
      
      // รีเฟรช filter อัตโนมัติ (ไม่จำเป็น เพราะ StreamBuilder จะอัปเดตเอง)
      // แต่ถ้าต้องการให้กลับไปที่ filter "pending" ทันที
      setState(() {
        _selectedFilter = 'pending'; // กลับไปดูรายการที่รอดำเนินการ
      });
    }
  }

  // Delete Report
  Future<void> _deleteReport(BuildContext context, String reportId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: const Text('ต้องการลบรายงานนี้ใช่หรือไม่?'),
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
      await FirebaseFirestore.instance.collection('reports').doc(reportId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบรายงานเรียบร้อย'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'ไม่ระบุเวลา';
    try {
      final date = (timestamp as Timestamp).toDate();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return 'ไม่ระบุเวลา';
    }
  }
}