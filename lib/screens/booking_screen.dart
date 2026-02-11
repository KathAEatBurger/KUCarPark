import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/mock_data.dart';
import '../models/booking.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _plateController = TextEditingController();
  DateTime _selectedTime = DateTime.now();
  int? _selectedSpotIndex;

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = DateTime(
          _selectedTime.year,
          _selectedTime.month,
          _selectedTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _confirmBooking() {
    final plate = _plateController.text;

    if (plate.isEmpty || _selectedSpotIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกทะเบียนและเลือกช่องจอด')),
      );
      return;
    }

    final spot = parkingSpots[_selectedSpotIndex!];

    if (spot.isOccupied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ช่องจอดนี้ไม่ว่าง')),
      );
      return;
    }

    setState(() {
      spot.isOccupied = true;
      spot.plateNumber = plate;
    });

    final newBooking = Booking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      plateNumber: plate,
      entryTime: _selectedTime,
      type: 'daily',
      status: 'active',
    );

    bookings.add(newBooking);
    currentUser!.plateNumber = plate;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('จองสำเร็จ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              color: Colors.black,
              child: Center(
                child: Text(
                  '[ QR CODE SIMULATION ]\nSpot: ${spot.id}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Text('ทะเบียน: $plate'),
            Text('ช่องจอด: ${spot.id}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('จองที่จอดรายวัน')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// ทะเบียนรถ
            TextField(
              controller: _plateController,
              decoration: const InputDecoration(
                labelText: 'เลขทะเบียนรถ',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            /// เวลาเข้าจอด
            ListTile(
              title: const Text('เวลาเข้าจอด'),
              subtitle: Text(
                DateFormat('HH:mm dd/MM/yyyy').format(_selectedTime),
              ),
              trailing: const Icon(Icons.access_time),
              onTap: _selectTime,
            ),

            const SizedBox(height: 20),

            /// เลือกช่องจอด
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'เลือกช่องจอด',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: parkingSpots.length,
                itemBuilder: (context, index) {
                  final spot = parkingSpots[index];
                  final isSelected = _selectedSpotIndex == index;

                  return GestureDetector(
                    onTap: spot.isOccupied
                        ? null
                        : () {
                            setState(() {
                              _selectedSpotIndex = index;
                            });
                          },
                    child: Container(
                      decoration: BoxDecoration(
                        color: spot.isOccupied
                            ? Colors.grey
                            : isSelected
                                ? Colors.green
                                : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isSelected ? Colors.green : Colors.black26,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              spot.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              spot.isOccupied ? 'ไม่ว่าง' : 'ว่าง',
                              style: TextStyle(
                                color: spot.isOccupied
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            /// ปุ่มยืนยัน
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmBooking,
                child: const Text('ยืนยันการจอง'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
