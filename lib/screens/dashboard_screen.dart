import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _listenForTaskCompletion();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _listenForTaskCompletion() {
    _usersRef.onChildChanged.listen((event) {
      if (event.snapshot.value != null && event.snapshot.value is Map) {
        Map<dynamic, dynamic> userData = event.snapshot.value as Map<dynamic, dynamic>;
        String userId = event.snapshot.key!;
        Map<dynamic, dynamic> tasks = userData['tasks'] ?? {};
        tasks.forEach((taskId, taskData) {
          if (taskData['done'] == true) {
            _showNotification(taskData['name'], userId);
          }
        });
      }
    });
  }

void _showNotification(String taskName, String userId) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'task_channel',
    'Task Notifications',
    channelDescription: 'Channel for task notifications',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  await _flutterLocalNotificationsPlugin.show(
    0, // id
    'Task Completed', // title
    'Task "$taskName" assigned to $userId is completed.', // body
    platformChannelSpecifics, // notificationDetails
    payload: 'task_completed', // payload
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _usersRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return Center(child: Text("No users found."));
                  }
                  Map<dynamic, dynamic> users = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  List<Widget> taskWidgets = [];
                  users.forEach((userId, userData) {
                    Map<dynamic, dynamic> tasks = userData['tasks'] ?? {};
                    tasks.forEach((taskId, taskData) {
                      if (taskData['done'] != true) {
                        taskWidgets.add(
                          ListTile(
                            title: Text(taskData['name']),
                            subtitle: Text("User: $userId\nNumber: ${taskData['number']}\nData: ${taskData['data']}"),
                          ),
                        );
                      }
                    });
                  });
                  return ListView(
                    children: taskWidgets,
                  );
                },
              ),
            ),
            // Add other monitoring information here
            // For example, you can add a summary of the number of tasks, users, etc.
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Monitoring Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            StreamBuilder<DatabaseEvent>(
              stream: _usersRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return Center(child: Text("No data found."));
                }
                Map<dynamic, dynamic> users = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                int totalTasks = 0;
                int undoneTasks = 0;
                users.forEach((userId, userData) {
                  Map<dynamic, dynamic> tasks = userData['tasks'] ?? {};
                  totalTasks += tasks.length;
                  tasks.forEach((taskId, taskData) {
                    if (taskData['done'] != true) {
                      undoneTasks++;
                    }
                  });
                });
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Users: ${users.length}"),
                    Text("Total Tasks: $totalTasks"),
                    Text("Undone Tasks: $undoneTasks"),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
