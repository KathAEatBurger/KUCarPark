import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เกี่ยวกับแอปพลิเคชัน"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            
            // ✅ โลโก้แอป
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.shade100,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_parking,
                size: 60,
                color: Colors.teal,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // ✅ ชื่อแอป
            const Text(
              "KU Carpark App",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // ✅ เวอร์ชัน
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: const Text(
                "เวอร์ชัน 1.0.0",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.teal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // ✅ คำอธิบายแอป
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.teal.shade50, Colors.white],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "แอปพลิเคชันสำหรับค้นหาที่จอดรถ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "ในมหาวิทยาลัยเกษตรศาสตร์ บางเขน",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.teal),
                  const SizedBox(height: 16),
                  _buildFeatureRow(Icons.map, "แสดงแผนที่และตำแหน่งที่จอดรถ"),
                  _buildFeatureRow(Icons.star, "รีวิวและให้คะแนนที่จอดรถ"),
                  _buildFeatureRow(Icons.report_problem, "แจ้งปัญหาข้อมูลไม่ถูกต้อง"),
                  _buildFeatureRow(Icons.admin_panel_settings, "ระบบจัดการสำหรับผู้ดูแลระบบ"),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // ✅ ข้อมูลทีมพัฒนา
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ภาควิชาวิทยาการคอมพิวเตอร์",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const Text("คณะวิทยาศาสตร์ มหาวิทยาลัยเกษตรศาสตร์"),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // ✅ ช่องทางติดต่อ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Column(
                children: [
                  const Text(
                    "📞 ติดต่อสอบถาม",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildContactRow(Icons.email, "kucarpark@ku.th"),
                  _buildContactRow(Icons.web, "www.ku.ac.th/carpark"),
                  _buildContactRow(Icons.phone, "02-942-8888 ต่อ 1234"),
                  _buildContactRow(Icons.facebook, "KU Carpark App"),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // ✅ ลิขสิทธิ์
            Text(
              "© 2026 มหาวิทยาลัยเกษตรศาสตร์\nสงวนลิขสิทธิ์",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ Widget แสดงฟีเจอร์
  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.teal.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Colors.teal.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget แสดงรายชื่อผู้พัฒนา
  Widget _buildDeveloperRow(String icon, String name, String role) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.teal.shade100,
            child: const Icon(Icons.person, size: 18, color: Colors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  role,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Widget แสดงช่องทางติดต่อ
  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.teal.shade700),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}