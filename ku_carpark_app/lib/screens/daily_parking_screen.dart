import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- เพิ่ม Import นี้

class DailyParkingScreen extends StatefulWidget {
  const DailyParkingScreen({super.key});

  @override
  State<DailyParkingScreen> createState() => _DailyParkingScreenState();
}

class _DailyParkingScreenState extends State<DailyParkingScreen> {
  final _plateController = TextEditingController();
  DateTime _entryTime = DateTime.now();
  bool _isParked = false;
  String? _currentBookingId;

  // --- State สำหรับเลือกโซนและช่องจอด ---
  List<QueryDocumentSnapshot> _zones = [];
  String? _selectedZoneId;
  String? _selectedZoneName;
  int? _selectedZoneTotal;
  int? _selectedSpot;
  List<int> _occupiedSpots = [];
  // --------------------------------

  @override
  void initState() {
    super.initState();
    _fetchZones();
    _checkActiveSession(); // <--- เพิ่ม: ตรวจสอบการจอดค้างเมื่อเปิดแอพ
  }

  Future<void> _fetchZones() async {
    final snapshot = await FirebaseFirestore.instance.collection('zones').get();
    setState(() {
      _zones = snapshot.docs;
    });
  }

  // --- เพิ่มฟังก์ชันนี้: ค้นหา Session ที่ยังไม่จ่ายเงิน ---
  Future<void> _checkActiveSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('daily_bookings')
          .where('userId', isEqualTo: user.uid) // ค้นหาของ User คนนี้
          .where('status', isEqualTo: 'active') // ที่ยังจอดอยู่
          .limit(1) // เอาแค่อันล่าสุด
          .get();

      if (snapshot.docs.isNotEmpty) {
        // --- เจอการจอดค้างไว้! กู้คืนสถานะ ---
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        
        setState(() {
          _isParked = true;
          _currentBookingId = doc.id;
          _plateController.text = data['plate'];
          _entryTime = (data['entryTime'] as Timestamp).toDate();
          
          // อาจจะเลือกโซนกลับมาเพื่อ UI แต่ไม่จำเป็นต่อการจ่ายเงิน
          _selectedZoneId = data['zoneId'];
        });
        
        // แจ้งเตือน User
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('พบการจอดค้างไว้ กรุณาชำระเงิน')),
          );
        }
      }
    } catch (e) {
      print('Error checking session: $e');
    }
  }
  // ----------------------------------------------

  Future<void> _startParking() async {
    if (_plateController.text.isEmpty || _selectedZoneId == null || _selectedSpot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกทะเบียน, เลือกโซน และเลือกช่องจอด')),
      );
      return;
    }

    // --- แก้ตรงนี้: เพิ่ม userId เพื่อให้ค้นหาคืนได้ ---
    final docRef = await FirebaseFirestore.instance.collection('daily_bookings').add({
      'userId': FirebaseAuth.instance.currentUser!.uid, // <--- เพิ่มบรรทัดนี้
      'plate': _plateController.text,
      'entryTime': _entryTime,
      'status': 'active',
      'zoneId': _selectedZoneId,
      'zoneName': _selectedZoneName,
      'spotNumber': _selectedSpot,
    });

    setState(() {
      _isParked = true;
      _currentBookingId = docRef.id;
    });
  }

  Future<void> _exitAndPay() async {
    if (_currentBookingId == null) return;
    final doc = await FirebaseFirestore.instance.collection('daily_bookings').doc(_currentBookingId).get();
    final data = doc.data() as Map<String, dynamic>;
    final entryTime = (data['entryTime'] as Timestamp).toDate();
    final exitTime = DateTime.now();
    final duration = exitTime.difference(entryTime).inMinutes;
    
    double price = (duration / 60 * 10).ceilToDouble();
    if (price < 10) price = 10;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('สรุปค่าจอดรถ'),
        content: Text('โซน: ${data['zoneName']}\nช่องที่: ${data['spotNumber']}\nเวลาที่จอด: $duration นาที\nยอดชำระ: $price บาท'),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('daily_bookings').doc(_currentBookingId).update({
                'status': 'paid', // เปลี่ยนเป็น paid จะทำให้ไม่แสดงใน active อีกต่อไป
                'exitTime': exitTime,
                'price': price
              });
              Navigator.pop(context);
              setState(() {
                _isParked = false;
                _currentBookingId = null;
                _selectedSpot = null;
                _plateController.clear();
              });
            },
            child: const Text('ชำระเงิน (จบรอบ)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จอดรถรายวัน')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (!_isParked) ...[
                TextField(controller: _plateController, decoration: const InputDecoration(labelText: 'ทะเบียนรถ')),
                const SizedBox(height: 10),

                ListTile(
                  title: const Text('เวลาเข้าจอด'),
                  subtitle: Text(DateFormat('HH:mm dd/MM/yyyy').format(_entryTime)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (picked != null) {
                        final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                        if (time != null) {
                          setState(() => _entryTime = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute));
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'เลือกโซนจอดรถ'),
                  value: _selectedZoneId,
                  items: _zones.map((zoneDoc) {
                    final data = zoneDoc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: zoneDoc.id,
                      child: Text('${data['name']} (ว่าง: ${data['available']})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    final selectedDoc = _zones.firstWhere((doc) => doc.id == value);
                    final data = selectedDoc.data() as Map<String, dynamic>;
                    
                    setState(() {
                      _selectedZoneId = value;
                      _selectedZoneName = data['name'];
                      _selectedZoneTotal = data['total'];
                      _selectedSpot = null;
                    });
                  },
                ),
                const SizedBox(height: 20),

                if (_selectedZoneId != null) ...[
                  const Text('เลือกช่องจอด:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('daily_bookings')
                        .where('status', isEqualTo: 'active')
                        .where('zoneId', isEqualTo: _selectedZoneId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      
                      _occupiedSpots = snapshot.data!.docs
                          .map((doc) => (doc.data() as Map<String, dynamic>)['spotNumber'] as int)
                          .toList();

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _selectedZoneTotal ?? 0,
                        itemBuilder: (context, index) {
                          final spotNumber = index + 1;
                          final isOccupied = _occupiedSpots.contains(spotNumber);

                          return InkWell(
                            onTap: isOccupied
                                ? null
                                : () {
                                    setState(() {
                                      _selectedSpot = spotNumber;
                                    });
                                  },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isOccupied 
                                    ? Colors.red.shade200 
                                    : (_selectedSpot == spotNumber 
                                        ? Colors.blue 
                                        : Colors.green.shade200),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isOccupied 
                                      ? Colors.red 
                                      : (_selectedSpot == spotNumber ? Colors.blue : Colors.green),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$spotNumber',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isOccupied ? Colors.red.shade800 : Colors.green.shade800,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                ElevatedButton.icon(
                  icon: const Icon(Icons.local_parking),
                  label: const Text('เข้าจอดรถ (แสดง QR)'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: _selectedSpot != null ? Colors.blue : Colors.grey,
                  ),
                  onPressed: _startParking,
                ),
              ] else ...[
                const Text('กำลังจอดอยู่...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                  child: QrImageView(data: _currentBookingId ?? '000', version: QrVersions.auto, size: 200.0),
                ),
                const SizedBox(height: 20),
                const Text('แสดง QR Code นี้แก่เจ้าหน้าที่'),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  icon: const Icon(Icons.exit_to_app),
                  label: const Text('ออกจากที่จอด / ชำระเงิน'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
                  onPressed: _exitAndPay,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}