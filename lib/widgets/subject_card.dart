import 'package:flutter/material.dart';
import '../models/subject_model.dart';

class SubjectCard extends StatelessWidget {
  final SubjectModel subject;

  const SubjectCard({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.book)),
        title: Text(subject.name),
        subtitle: Text('Professor(a): ${subject.teacher}'),
      ),
    );
  }
}
