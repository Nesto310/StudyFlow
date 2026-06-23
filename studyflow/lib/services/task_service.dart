import 'package:cloud_firestore/cloud_firestore.dart';

class TaskService {
  final tasks = FirebaseFirestore.instance.collection('tasks');

  Future addTask(Map<String, dynamic> data) async {
    await tasks.add(data);
  }

  Stream<QuerySnapshot> getTasks() {
    return tasks.snapshots();
  }

  Future deleteTask(String id) async {
    await tasks.doc(id).delete();
  }
}
