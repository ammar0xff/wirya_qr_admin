import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'firebase_options.dart';
import 'profile_edit_screen.dart';
import 'qr_display_screen.dart';
import 'users_management_screen.dart';
import 'users_live_location_screen.dart';
import 'about_screen.dart';
import 'dashboard_screen.dart';
import './screens/tasks_screen.dart'; // Import the TasksScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(SupervisorApp());
}

class SupervisorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LockCheckScreen(),
    );
  }
}

class LockCheckScreen extends StatefulWidget {
  @override
  _LockCheckScreenState createState() => _LockCheckScreenState();
}

class _LockCheckScreenState extends State<LockCheckScreen> {
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  void _checkLockStatus() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref();
    DatabaseEvent event = await ref.once();
    if (event.snapshot.value != null && event.snapshot.value is Map) {
      Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _isLocked = data['locked'] ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return Scaffold(
        body: Center(
          child: Text(
            'Locked by the developer due to uncompleted payments',
            style: TextStyle(fontSize: 20, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return MainScreen();
    }
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    UsersManagementScreen(),
    UsersLiveLocationScreen(),
    TasksScreen(), // Add the TasksScreen to the list of screens
    AboutScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wirya QR Admin'),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Locations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'About',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

class QRGeneratorScreen extends StatefulWidget {
  @override
  _QRGeneratorScreenState createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  String? generatedQR;
  String? errorMessage;
  File? qrImageFile;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void generateQR() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      setState(() {
        errorMessage = "Name and Phone fields cannot be empty.";
      });
      return;
    }
    try {
      String id = const Uuid().v4();
      Map<String, dynamic> profile = {
        "id": id,
        "name": _nameController.text,
        "location": _locationController.text,
        "phone": _phoneController.text,
        "category": _categoryController.text,
        "timestamp": ServerValue.timestamp,
      };

      await FirebaseDatabase.instance.ref("profiles").child(id).set(profile);
      setState(() {
        generatedQR = id;
        errorMessage = null;
        qrImageFile = null;
      });
      await _generateQrImage(id, _nameController.text);
    } catch (e) {
      setState(() {
        errorMessage = "Failed to generate QR code: $e";
      });
    }
  }

  Future<void> _generateQrImage(String data, String profileName) async {
    final qrValidationResult = QrValidator.validate(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );
    if (qrValidationResult.status == QrValidationStatus.valid) {
      final qrCode = qrValidationResult.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: true,
      );
      final picData = await painter.toImageData(300);
      final directory = await getDownloadsDirectory(); // Get the Downloads directory
      final file = await File('${directory!.path}/${profileName}_qr_code.png').create();
      await file.writeAsBytes(picData!.buffer.asUint8List());

      setState(() {
        qrImageFile = file;
      });
    }
  }

  void deleteProfile(String id) async {
    try {
      await FirebaseDatabase.instance.ref("profiles").child(id).remove();
      setState(() {
        if (generatedQR == id) generatedQR = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to delete profile: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Code Generator")),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.qr_code_rounded, color: Colors.white, size: 50), // أيقونة كبيرة
                  SizedBox(height: 10),
                  Text(
                    'Wirya Admin',
                    style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Manage Users & QR Codes',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.qr_code),
              title: Text('QR Code Generator'),
              onTap: () {
                Navigator.pop(context); // هذا يغلق الـ Drawer حتى لو كنت بنفس الشاشة
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Users Management'),
              onTap: () {
                Navigator.pop(context); // لإغلاق الـ Drawer قبل الانتقال
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UsersManagementScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text('Users Live Location'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UsersLiveLocationScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('About'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: "Location")),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Phone"), keyboardType: TextInputType.phone),
            TextField(controller: _categoryController, decoration: const InputDecoration(labelText: "Category")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: generateQR, child: const Text("Generate QR Code")),
            const SizedBox(height: 20),
            if (qrImageFile != null)
              Image.file(qrImageFile!),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: FirebaseDatabase.instance.ref("profiles").onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text("No profiles found."));
                  }
                  Map<dynamic, dynamic> profiles = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  return ListView(
                    children: profiles.entries.map((entry) {
                      return ListTile(
                        title: Text(entry.value["name"] ?? "No Name"),
                        subtitle: Text(entry.value["phone"] ?? "No Phone"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.qr_code, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QRDisplayScreen(data: entry.key, name: entry.value["name"]),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileEditScreen(profileId: entry.key, profileData: entry.value),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteProfile(entry.key),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
