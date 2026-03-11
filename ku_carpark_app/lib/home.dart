import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ku_carpark_app/profile_detail.dart';
import 'package:ku_carpark_app/review.dart';
import 'package:ku_carpark_app/settings_page.dart';
import 'package:ku_carpark_app/account.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/user_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'reviewdashboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(13.8476, 100.5696);
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // สำหรับค้นหา
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isSearching = false;
  
  LatLng? _currentP; 

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _getCurrentLocation();
    _addParkingMarkers();
    
    // เพิ่ม listener สำหรับการค้นหา
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // เมื่อพิมพ์ค้นหา
  void _onSearchChanged() {
    if (_searchController.text.length > 1) {
      _searchZones(_searchController.text);
    } else {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  // ค้นหาสถานที่จาก Firestore
  Future<void> _searchZones(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      // ค้นหาจากชื่อสถานที่ (ตัวพิมพ์เล็ก-ใหญ่ไม่สน)
      final snapshot = await FirebaseFirestore.instance
          .collection('zones')
          .orderBy('name')
          .get();

      final results = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('Error searching zones: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // เมื่อเลือกสถานที่จากผลการค้นหา
  void _onSelectSearchResult(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'ไม่ระบุชื่อ';
    final lat = data['latitude'] ?? 13.8476;
    final lng = data['longitude'] ?? 100.5696;
    final position = LatLng(lat, lng);

    // ซ่อนคีย์บอร์ด
    FocusScope.of(context).unfocus();
    
    // เคลียร์ผลการค้นหา
    setState(() {
      _searchResults = [];
      _searchController.clear();
    });

    // ซูมไปยังสถานที่ที่เลือก
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(position, 17.0),
    );

    // แสดง Bottom Sheet
    _showParkingDetailSheet(name, position);
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
    setState(() {
      _currentP = LatLng(position.latitude, position.longitude);
    });
  }

  void _drawRoute(LatLng destination) async {
    Position position = await Geolocator.getCurrentPosition();
    LatLng startPoint = LatLng(position.latitude, position.longitude);

    PolylinePoints polylinePoints = PolylinePoints();
    
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: "AIzaSyCFMrCbuVOw7r-OYJxVzUrheJ4jPBUy51I",
      request: PolylineRequest(
        origin: PointLatLng(startPoint.latitude, startPoint.longitude),
        destination: PointLatLng(destination.latitude, destination.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoordinates = [];
      
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route_real'),
            points: polylineCoordinates,
            color: Colors.teal,
            width: 5,
          ),
        );
      });
    }
  }

  void _navigateToReviewDashboard(String parkingName, LatLng position) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewDashboardPage(
          parkingName: parkingName,
          parkingLocation: position,
        ),
      ),
    );
  }

  void _showParkingDetailSheet(String title, LatLng position) {
    mapController.animateCamera(CameraUpdate.newLatLngZoom(position, 17.0));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, 
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, 
              height: 5, 
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))
            ),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _drawRoute(position);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.directions, color: Colors.white),
                    label: const Text("Directions", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  ),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToReviewDashboard(title, position);
                    },
                    icon: const Icon(Icons.rate_review, color: Colors.white),
                    label: const Text("Review", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addParkingMarkers() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('parking_1'),
          position: const LatLng(13.842856383968316, 100.57105828220901),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          onTap: () => _showParkingDetailSheet('อาคารจอดรถงามวงศ์วาน 1', const LatLng(13.842856383968316, 100.57105828220901)),
        ),
      );

      _markers.add(
        Marker(
          markerId: const MarkerId('parking_2'),
          position: const LatLng(13.843583792405912, 100.56996585767205),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          onTap: () => _showParkingDetailSheet('อาคารจอดรถงามวงศ์วาน 2', const LatLng(13.843583792405912, 100.56996585767205)),
        ),
      );

      _markers.add(
        Marker(
          markerId: const MarkerId('parking_3'),
          position: const LatLng(13.85120701562238, 100.56435727002017),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          onTap: () => _showParkingDetailSheet('อาคารจอดรถวิภาวดี', const LatLng(13.85120701562238, 100.56435727002017)),
        ),
      );

      _markers.add(
        Marker(
          markerId: const MarkerId('parking_4'),
          position: const LatLng(13.854373879445383, 100.57023668227706),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          onTap: () => _showParkingDetailSheet('อาคารจอดรถบางเขน', const LatLng(13.854373879445383, 100.57023668227706)),
        ),
      );
    });
  }

  Future<void> _checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
  }

  void _onItemTapped(int index) async {
    setState(() { _selectedIndex = index; });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AccountPage()),
      ).then((_) {
        setState(() { _selectedIndex = 0; });
      });
    }
    
    if (index == 2) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        String role = doc.get('role');

        Widget targetPage;
        if (role == 'admin') {
          targetPage = const AdminDashboard();
        } else {
          targetPage = const UserDashboard();
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => targetPage),
          ).then((_) {
            setState(() { _selectedIndex = 0; });
          });
        }
      }
    }

    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SettingsPage()),
      ).then((_) {
        setState(() { _selectedIndex = 0; });
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: 15.0),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
          ),
          
          // Header
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.menu, color: Colors.black),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileDetailPage()),
                    );
                  },
                  child: CircleAvatar(
                    backgroundColor: Colors.teal[400],
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Positioned(
            top: 110,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'ค้นหาที่จอดรถ...',
                      border: InputBorder.none,
                      icon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchResults = [];
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                
                // แสดงผลการค้นหา
                if (_searchResults.isNotEmpty || _isSearching)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                    ),
                    child: _isSearching
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final doc = _searchResults[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final name = data['name'] ?? 'ไม่ระบุชื่อ';
                              final address = data['address'] ?? '';
                              final price = data['price'] ?? 0;
                              
                              return ListTile(
                                leading: const Icon(Icons.local_parking, color: Colors.teal),
                                title: Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                subtitle: address.isNotEmpty
                                    ? Text(address, maxLines: 1, overflow: TextOverflow.ellipsis)
                                    : Text('ราคา $price บาท/ชั่วโมง'),
                                onTap: () => _onSelectSearchResult(doc),
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.email), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () async {
          Position position = await Geolocator.getCurrentPosition();
          mapController.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 16.0)
          );
        },
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}