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

  @override
  void initState() {
    super.initState();
    _usersRef.onValue.listen((event) {
      final users = event.snapshot.value as Map<dynamic, dynamic>;
      final markers = <Marker>[];
      users.forEach((key, value) {
        final location = value["current_location"];
        if (location["latitude"] != "" && location["longitude"] != "") {
          final lat = double.parse(location["latitude"]);
          final lng = double.parse(location["longitude"]);
          final marker = Marker(
            point: LatLng(lat, lng),
            width: 80.0,
            height: 80.0,
            builder: (ctx) => Icon(Icons.location_on, color: Colors.red, size: 40),
          );
          markers.add(marker);
        }
      });
      setState(() {
        _markers = markers;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users Live Location")),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(0, 0),
          zoom: 2.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: _markers,
          ),
        ],
      ),
    );
  }
}
