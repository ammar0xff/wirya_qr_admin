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
    _fetchLiveLocations();
  }

  void _fetchLiveLocations() {
    _usersRef.onValue.listen((event) {
      if (event.snapshot.value == null) {
        setState(() => _markers.clear());
        return;
      }

      final users = Map<String, dynamic>.from(event.snapshot.value as Map);
      final markers = <Marker>[];

      users.forEach((key, value) {
        if (value["current_location"] == null) return;

        final location = value["current_location"];

        final double? lat = location["latitude"] is double
            ? location["latitude"]
            : double.tryParse(location["latitude"].toString());

        final double? lng = location["longitude"] is double
            ? location["longitude"]
            : double.tryParse(location["longitude"].toString());

        if (lat != null && lng != null) {
          markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 80.0,
              height: 80.0,
              child: Column(
                children: [
                  Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                  Container(
                    padding: EdgeInsets.all(2),
                    color: Colors.white,
                    child: Text(
                      key,
                      style: TextStyle(color: Colors.black, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      });

      setState(() {
        _markers = markers;
        if (_markers.isNotEmpty) _mapCenter = _markers.first.point;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users Live Location")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: _mapCenter, // Use `initialCenter` instead of `center`
          initialZoom: 10.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: _markers, // No need for `.toList()` as it's already a list
          ),
        ],
      ),
    );
  }
}