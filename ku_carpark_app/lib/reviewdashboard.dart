import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ku_carpark_app/review.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReviewDashboardPage extends StatefulWidget {
  final String parkingName;
  final LatLng parkingLocation;

  const ReviewDashboardPage({
    super.key,
    required this.parkingName,
    required this.parkingLocation,
  });

  @override
  State<ReviewDashboardPage> createState() => _ReviewDashboardPageState();
}

class _ReviewDashboardPageState extends State<ReviewDashboardPage> {
  double averageRating = 0;
  int totalReviews = 0;
  Map<int, int> ratingCount = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  bool _isLoading = true;
  String? _errorMessage;
  
  // Cache สำหรับเก็บ displayName ของ users
  final Map<String, String> _userDisplayNameCache = {};

  @override
  void initState() {
    super.initState();
    _checkFirestoreConnection();
  }

  Future<void> _checkFirestoreConnection() async {
    try {
      await FirebaseFirestore.instance.collection('reviews').limit(1).get();
      if (mounted) {
        setState(() {
          _errorMessage = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'ไม่สามารถเชื่อมต่อฐานข้อมูล: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ฟังก์ชันดึง displayName จาก users collection
  Future<String> _getUserDisplayName(String userId) async {
    if (_userDisplayNameCache.containsKey(userId)) {
      return _userDisplayNameCache[userId]!;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        String displayName = data['displayName'] ?? '';
        _userDisplayNameCache[userId] = displayName;
        return displayName;
      }
    } catch (e) {
      print('Error fetching user displayName: $e');
    }
    
    return '';
  }

  // ฟังก์ชันแสดงรูปภาพแบบเต็มหน้าจอ
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      'ไม่สามารถโหลดรูปภาพได้',
                      style: TextStyle(color: Colors.grey.shade300),
                    ),
                  ],
                ),
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รีวิว ${widget.parkingName}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReviewPage(
                    parkingName: widget.parkingName,
                    parkingLocation: widget.parkingLocation,
                  ),
                ),
              ).then((_) {
                setState(() {
                  _isLoading = true;
                });
                _checkFirestoreConnection();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _checkFirestoreConnection();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _checkFirestoreConnection();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('parkingName', isEqualTo: widget.parkingName)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('กำลังโหลดข้อมูลรีวิว...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          print('🔥 StreamBuilder Error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 20),
                Text(
                  'เกิดข้อผิดพลาดในการโหลดข้อมูล',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text('ไม่มีข้อมูลรีวิว'),
          );
        }

        final reviews = snapshot.data!.docs;
        print('📊 พบรีวิวทั้งหมด: ${reviews.length} รายการ');

        // คำนวณสถิติ
        if (reviews.isNotEmpty) {
          double sum = 0;
          Map<int, int> tempCount = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
          
          for (var doc in reviews) {
            try {
              int rating = (doc['rating'] ?? 0).toInt();
              sum += rating;
              tempCount[rating] = (tempCount[rating] ?? 0) + 1;
            } catch (e) {
              print('⚠️ Error parsing review: $e');
            }
          }
          
          averageRating = reviews.isEmpty ? 0 : sum / reviews.length;
          totalReviews = reviews.length;
          ratingCount = tempCount;
          
          if (_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            });
          }
        } else {
          averageRating = 0;
          totalReviews = 0;
          ratingCount = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
          
          if (_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            });
          }
        }

        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 100,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 20),
                Text(
                  'ยังไม่มีรีวิวสำหรับ ${widget.parkingName}',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'มาเป็นคนแรกที่เขียนรีวิวกันเถอะ!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewPage(
                          parkingName: widget.parkingName,
                          parkingLocation: widget.parkingLocation,
                        ),
                      ),
                    ).then((_) {
                      setState(() {
                        _isLoading = true;
                      });
                      _checkFirestoreConnection();
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('เขียนรีวิวแรก'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // ส่วนสรุปคะแนน
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.teal.shade50,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 1; i <= 5; i++)
                              Icon(
                                i <= averageRating.round() 
                                    ? Icons.star 
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 24,
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'จาก $totalReviews รีวิว',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 5; i >= 1; i--)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 35,
                                  child: Row(
                                    children: [
                                      Text('$i'),
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      Container(
                                        height: 12,
                                        width: totalReviews > 0 
                                            ? (MediaQuery.of(context).size.width * 0.4 * 
                                               (ratingCount[i]! / totalReviews))
                                            : 0,
                                        decoration: BoxDecoration(
                                          color: i == 5 ? Colors.green :
                                                  i == 4 ? Colors.lightGreen :
                                                  i == 3 ? Colors.amber :
                                                  i == 2 ? Colors.orange :
                                                  Colors.red,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 35,
                                  child: Text(
                                    '${ratingCount[i]}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // หัวข้อรายการรีวิว
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'รีวิวทั้งหมด',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${reviews.length} รายการ',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            // รายการรีวิว
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  var review = reviews[index];
                  
                  // ใช้ data() เพื่อเข้าถึงข้อมูล
                  final Map<String, dynamic> reviewData = review.data() as Map<String, dynamic>;
                  
                  String userEmail = reviewData['userEmail'] ?? 'ผู้ใช้นิรนาม';
                  String userId = reviewData['userId'] ?? '';
                  int rating = (reviewData['rating'] ?? 0).toInt();
                  String reviewText = reviewData['review'] ?? '';
                  
                  // เปลี่ยนจาก priceLevel เป็น price
                  int? price = reviewData['price']; // ราคาเป็นตัวเลข
                  
                  // ดึง URL รูปภาพ (ถ้ามี)
                  List<String> imageUrls = [];
                  if (reviewData.containsKey('imageUrls') && reviewData['imageUrls'] != null) {
                    imageUrls = List<String>.from(reviewData['imageUrls']);
                  }
                  
                  return FutureBuilder<String>(
                    future: _getUserDisplayName(userId),
                    builder: (context, nameSnapshot) {
                      String displayName = nameSnapshot.data ?? '';
                      
                      String reviewerName = displayName.isNotEmpty 
                          ? displayName 
                          : (userEmail.contains('@') 
                              ? userEmail.split('@')[0] 
                              : userEmail);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: รูปโปรไฟล์ + ชื่อ + คะแนน + ราคา
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.teal.shade100,
                                    radius: 20,
                                    child: Text(
                                      reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reviewerName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          userEmail,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            for (int i = 1; i <= 5; i++)
                                              Icon(
                                                i <= rating
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.amber,
                                                size: 18,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // ✅ แสดงราคา (ถ้ามี)
                                  if (price != null && price > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.attach_money,
                                            size: 14,
                                            color: Colors.green,
                                          ),
                                          Text(
                                            '$price',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const Text(
                                            ' บาท/ชม.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // ข้อความรีวิว
                              Text(
                                reviewText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // แสดงรูปภาพ (ถ้ามี)
                              if (imageUrls.isNotEmpty) ...[
                                Container(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: imageUrls.length,
                                    itemBuilder: (context, imgIndex) {
                                      return GestureDetector(
                                        onTap: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => Dialog(
                                              child: Container(
                                                padding: const EdgeInsets.all(10),
                                                child: Stack(
                                                  children: [
                                                    Center(
                                                      child: Image.network(imageUrls[imgIndex]),
                                                    ),
                                                    Positioned(
                                                      top: 0,
                                                      right: 0,
                                                      child: IconButton(
                                                        icon: const Icon(Icons.close),
                                                        onPressed: () => Navigator.pop(context),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              imageUrls[imgIndex],
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey.shade200,
                                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              
                              // วันที่
                              Text(
                                _formatDate(reviewData['createdAt']),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'ไม่ระบุวันที่';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('⚠️ Error formatting date: $e');
      return 'ไม่ระบุวันที่';
    }
  }
}