import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';

class UsersLiveLocationScreen extends StatefulWidget {
  @override
  _UsersLiveLocationScreenState createState() => _UsersLiveLocationScreenState();
}

class _UsersLiveLocationScreenState extends State<UsersLiveLocationScreen> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref("users");
  List<Marker> _markers = [];
  LatLng _mapCenter = LatLng(30.033, 31.233); // Default: Cairo

  @override
  void initState() {
    super.initState();
    _usersRef.onValue.listen((event) {
      if (event.snapshot.value == null) return; // Check if users exist

      final users = event.snapshot.value as Map<dynamic, dynamic>;
      final markers = <Marker>[];

      users.forEach((key, value) {
        if (value["current_location"] == null) return; // Check if location exists
        final location = value["current_location"];
        
        final lat = location["latitude"] is double
            ? location["latitude"]
            : double.tryParse(location["latitude"].toString());

        final lng = location["longitude"] is double
            ? location["longitude"]
            : double.tryParse(location["longitude"].toString());

        if (lat != null && lng != null) {
          final marker = Marker(
            point: LatLng(lat, lng),
            width: 50.0,
            height: 50.0,
            child: const Icon(Icons.location_on, color: Colors.red, size: 40), // استخدم child بدلاً من builder
          );
          markers.add(marker);
        }
      });

      if (markers.isNotEmpty) {
        setState(() {
          _markers = markers;
          _mapCenter = _markers.first.point; // Center the map on the first user
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users Live Location")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _mapCenter, // Use initialCenter instead of center
          initialZoom: 10.0, // Use initialZoom instead of zoom
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: _markers, // Corrected MarkerLayer usage
          ),
        ],
      ),
    );
  }
}