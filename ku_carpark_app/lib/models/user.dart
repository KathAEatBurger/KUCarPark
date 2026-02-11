class User {
  final String username;
  String password; 
  final String role;
  String? plateNumber;
  bool isMonthlyMember;

  User({
    required this.username,
    required this.password,
    required this.role,
    this.plateNumber,
    this.isMonthlyMember = false,
  });
}
