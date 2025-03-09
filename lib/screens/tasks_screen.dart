import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskNumberController = TextEditingController();
  final TextEditingController _taskDataController = TextEditingController();
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');

  void _addTask(String userId) async {
    if (_taskNameController.text.isEmpty || _taskNumberController.text.isEmpty || _taskDataController.text.isEmpty) {
      return;
    }

    try {
      String taskId = _usersRef.child(userId).child('tasks').push().key!;
      Task task = Task(
        data: _taskDataController.text,
        name: _taskNameController.text,
        number: int.parse(_taskNumberController.text),
      );

      await _usersRef.child(userId).child('tasks').child(taskId).set(task.toJson());
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
          children: [
            TextField(
              controller: _taskNameController,
              decoration: InputDecoration(labelText: "Task Name"),
            ),
            TextField(
              controller: _taskNumberController,
              decoration: InputDecoration(labelText: "Task Number"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _taskDataController,
              decoration: InputDecoration(labelText: "Task Data"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Replace 'userId' with the actual user ID
                _addTask('userId');
              },
              child: Text("Add Task"),
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
                      User user = User.fromJson(entry.value);
                      return ExpansionTile(
                        title: Text(user.id),
                        children: user.tasks.entries.map((taskEntry) {
                          Task task = taskEntry.value;
                          return ListTile(
                            title: Text(task.name),
                            subtitle: Text("Number: ${task.number}\nData: ${task.data}"),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTask(user.id, taskEntry.key),
                            ),
                          );
                        }).toList(),
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
