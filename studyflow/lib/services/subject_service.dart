import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectService {
  final subjects = FirebaseFirestore.instance.collection('subjects');

  Future addSubject(Map<String, dynamic> data) async {
    await subjects.add(data);
  }

  Stream<QuerySnapshot> getSubjects() {
    return subjects.snapshots();
  }
}
