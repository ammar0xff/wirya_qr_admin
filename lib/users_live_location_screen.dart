import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // Ensure this import
import 'package:firebase_database/firebase_database.dart';

class UsersLiveLocationScreen extends StatefulWidget {
  @override
  _UsersLiveLocationScreenState createState() => _UsersLiveLocationScreenState();
}

class _UsersLiveLocationScreenState extends State<UsersLiveLocationScreen> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref("users");
  GoogleMapController? _mapController;
  Map<String, Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _usersRef.onValue.listen((event) {
      final users = event.snapshot.value as Map<dynamic, dynamic>;
      final markers = <String, Marker>{};
      users.forEach((key, value) {
        final location = value["current_location"];
        if (location["latitude"] != "" && location["longitude"] != "") {
          final lat = double.parse(location["latitude"]);
          final lng = double.parse(location["longitude"]);
          final marker = Marker(
            markerId: MarkerId(key),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: key),
          );
          markers[key] = marker;
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
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(0, 0),
          zoom: 2,
        ),
        markers: _markers.values.toSet(),
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
