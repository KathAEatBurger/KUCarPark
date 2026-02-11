import 'package:flutter/material.dart';
import '../utils/mock_data.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สถานะที่จอด')),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.5),
        itemCount: parkingSpots.length,
        itemBuilder: (context, index) {
          final spot = parkingSpots[index];
          return Card(
            color: spot.isOccupied ? Colors.red[100] : Colors.green[100],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(spot.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 5),
                Text(spot.isOccupied ? 'ไม่ว่าง' : 'ว่าง', style: TextStyle(color: spot.isOccupied ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                if (spot.isOccupied) Text(spot.plateNumber ?? '', style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}