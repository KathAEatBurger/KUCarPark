class Booking {
  String id;
  String plateNumber;
  DateTime entryTime;
  DateTime? exitTime;
  double? price;
  String type; // 'daily' or 'monthly'
  String status; // 'active', 'completed', 'pending_payment'
  String? slipImagePath;

  Booking({
    required this.id,
    required this.plateNumber,
    required this.entryTime,
    this.exitTime,
    this.price,
    required this.type,
    required this.status,
    this.slipImagePath,
  });
}