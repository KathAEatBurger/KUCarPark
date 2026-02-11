import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/parking_spot.dart';
import '../models/booking.dart';
import '../models/report.dart';

// --- Mock Database (จำลองฐานข้อมูล) ---
List<User> users = [
  User(username: 'admin', password: '1234', role: 'admin'),
  User(username: 'user', password: '1234', role: 'user'),
];

List<ParkingSpot> parkingSpots = List.generate(
  10,
  (index) => ParkingSpot(id: 'A-${index + 1}', zone: 'Zone A'),
);

List<Booking> bookings = [];
List<Report> reports = [];
User? currentUser;

// --- Helper Function (คำนวณราคา) ---
double calculatePrice(Booking booking) {
  if (booking.exitTime == null) return 0.0;
  int hours = booking.exitTime!.difference(booking.entryTime).inHours;
  if (hours < 1) hours = 1; // คิดขั้นต่ำ 1 ชม.
  return hours * 20.0; // 20 บาท/ชม.
}