import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ku_carpark_app/settings_page.dart';
import 'screens/user_dashboard.dart';
import 'screens/admin_dashboard.dart';

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

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _addParkingMarkers();
  }

  Future<void> _checkPermission() async {

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  void _drawRoute(LatLng destination) async {

    Position position = await Geolocator.getCurrentPosition();

    LatLng start = LatLng(position.latitude, position.longitude);

    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: "YOUR_API_KEY",
      request: PolylineRequest(
        origin: PointLatLng(start.latitude, start.longitude),
        destination: PointLatLng(destination.latitude, destination.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {

      List<LatLng> route = [];

      for (var point in result.points) {
        route.add(LatLng(point.latitude, point.longitude));
      }

      setState(() {

        _polylines.clear();

        _polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            points: route,
            width: 5,
            color: Colors.teal,
          ),
        );
      });
    }
  }

  void _showParkingDetail(String title, LatLng position) {

    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(position, 17),
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {

        return Container(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [

              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 15),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
                onPressed: () {
                  _drawRoute(position);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.directions),
                label: const Text("Directions"),
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _addParkingMarkers() {

    _markers = {

      Marker(
        markerId: const MarkerId("p1"),
        position: const LatLng(13.842856, 100.571058),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure),
        onTap: () => _showParkingDetail(
            "อาคารจอดรถงามวงศ์วาน 1",
            const LatLng(13.842856, 100.571058)),
      ),

      Marker(
        markerId: const MarkerId("p2"),
        position: const LatLng(13.843583, 100.569965),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure),
        onTap: () => _showParkingDetail(
            "อาคารจอดรถงามวงศ์วาน 2",
            const LatLng(13.843583, 100.569965)),
      ),

      Marker(
        markerId: const MarkerId("p3"),
        position: const LatLng(13.851207, 100.564357),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure),
        onTap: () => _showParkingDetail(
            "อาคารจอดรถวิภาวดี",
            const LatLng(13.851207, 100.564357)),
      ),

      Marker(
        markerId: const MarkerId("p4"),
        position: const LatLng(13.854373, 100.570236),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure),
        onTap: () => _showParkingDetail(
            "อาคารจอดรถบางเขน",
            const LatLng(13.854373, 100.570236)),
      ),
    };
  }

  void _onItemTapped(int index) async {

    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {

        String role = doc.get("role");

        Widget page;

        if (role == "admin") {
          page = const AdminDashboard();
        } else {
          page = const UserDashboard();
        }

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        ).then((_) {

          setState(() {
            _selectedIndex = 0;
          });
        });
      }
    }

    if (index == 2) {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingsPage(),
        ),
      ).then((_) {

        setState(() {
          _selectedIndex = 0;
        });
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
            initialCameraPosition:
            CameraPosition(target: _center, zoom: 15),
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
          ),

          Positioned(
            top: 60,
            left: 20,
            right: 20,

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                  )
                ],
              ),

              child: const TextField(
                decoration: InputDecoration(
                  hintText: "Where are you going to?",
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(

        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,

        items: const [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: "",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "",
          ),
        ],
      ),

      floatingActionButton: Padding(

        padding: const EdgeInsets.only(bottom: 70),

        child: FloatingActionButton(

          backgroundColor: Colors.teal,

          onPressed: () async {

            Position position =
            await Geolocator.getCurrentPosition();

            mapController.animateCamera(

              CameraUpdate.newLatLngZoom(
                LatLng(position.latitude, position.longitude),
                16,
              ),
            );
          },

          child: const Icon(Icons.my_location),
        ),
      ),

      floatingActionButtonLocation:
      FloatingActionButtonLocation.endFloat,
    );
  }
}