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
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  LatLngBounds? _bounds;
  double _currentZoom = 10.0;
  String _mapType = 'streets';

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
      LatLngBounds? bounds;

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
          final point = LatLng(lat, lng);
          markers.add(
            Marker(
              point: point,
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

          if (bounds == null) {
            bounds = LatLngBounds(point, point);
          } else {
            bounds?.extend(point); // Use null-aware operator
          }
        }
      });

      setState(() {
        _markers = markers;
        _bounds = bounds;
        if (_markers.isNotEmpty && _bounds != null) {
          _mapController.move(_bounds!.center, _currentZoom); // Move to bounds center
        }
      });
    });
  }

  void _onMapTypeChanged(String? value) {
    setState(() {
      _mapType = value!;
    });
  }

  void _onZoomIn() {
    setState(() {
      _currentZoom += 1;
      _mapController.move(_mapController.camera.center, _currentZoom); // Use camera.center
    });
  }

  void _onZoomOut() {
    setState(() {
      _currentZoom -= 1;
      _mapController.move(_mapController.camera.center, _currentZoom); // Use camera.center
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users Live Location")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _bounds?.center ?? LatLng(30.033, 31.233), // Default to Cairo if bounds are null
              initialZoom: _currentZoom,
            ),
            children: [
              TileLayer(
                urlTemplate: _mapType == 'streets'
                    ? "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                    : "https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _onZoomIn,
                  child: Icon(Icons.zoom_in),
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: _onZoomOut,
                  child: Icon(Icons.zoom_out),
                ),
              ],
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: DropdownButton<String>(
              value: _mapType,
              items: [
                DropdownMenuItem(
                  value: 'streets',
                  child: Text('Streets'),
                ),
                DropdownMenuItem(
                  value: 'topo',
                  child: Text('Topographic'),
                ),
              ],
              onChanged: _onMapTypeChanged,
            ),
          ),
        ],
      ),
    );
  }
}