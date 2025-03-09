import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskNumberController = TextEditingController();
  final TextEditingController _taskDataController = TextEditingController();
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');
  String? _selectedUserId;

  void _addTask() async {
    if (_selectedUserId == null || _taskNameController.text.isEmpty || _taskNumberController.text.isEmpty || _taskDataController.text.isEmpty) {
      return;
    }

    try {
      String taskId = _usersRef.child(_selectedUserId!).child('tasks').push().key!;
      Map<String, dynamic> task = {
        "data": _taskDataController.text,
        "name": _taskNameController.text,
        "number": int.parse(_taskNumberController.text),
        "done": false,
      };

      await _usersRef.child(_selectedUserId!).child('tasks').child(taskId).set(task);
      _taskNameController.clear();
      _taskNumberController.clear();
      _taskDataController.clear();
    } catch (e) {
      print("Failed to add task: $e");
    }
  }

  void _deleteTask(String userId, String taskId) async {
    try {
      await _usersRef.child(userId).child('tasks').child(taskId).remove();
    } catch (e) {
      print("Failed to delete task: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks Management'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Assigned to:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            StreamBuilder<DatabaseEvent>(
              stream: _usersRef.onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return Center(child: Text("No users found."));
                }
                Map<dynamic, dynamic> users = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                return DropdownButton<String>(
                  hint: Text("Select User"),
                  value: _selectedUserId,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedUserId = newValue;
                    });
                  },
                  items: users.keys.map<DropdownMenuItem<String>>((dynamic key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(key),
                    );
                  }).toList(),
                );
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: _taskNameController,
              decoration: InputDecoration(
                labelText: "Task Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _taskNumberController,
              decoration: InputDecoration(
                labelText: "Task Number",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _taskDataController,
              decoration: InputDecoration(
                labelText: "Task Data",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _addTask,
                child: Text("Add Task"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ),
            SizedBox(height: 20),
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
                  return ListView(
                    children: users.entries.map((entry) {
                      Map<dynamic, dynamic> tasks = entry.value['tasks'] ?? {};
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        child: ExpansionTile(
                          title: Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold)),
                          children: tasks.entries.map((taskEntry) {
                            Map<dynamic, dynamic> task = taskEntry.value;
                            return ListTile(
                              title: Text(task['name']),
                              subtitle: Text("Number: ${task['number']}\nData: ${task['data']}"),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteTask(entry.key, taskEntry.key),
                              ),
                            );
                          }).toList(),
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
