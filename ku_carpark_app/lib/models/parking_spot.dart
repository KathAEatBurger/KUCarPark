class ParkingSpot {
  String id;
  String zone;
  bool isOccupied;
  String? plateNumber;

  ParkingSpot({
    required this.id,
    required this.zone,
    this.isOccupied = false,
    this.plateNumber,
  });
}