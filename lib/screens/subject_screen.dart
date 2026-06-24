import 'package:flutter/material.dart';

import '../services/subject_service.dart';

class AddSubjectScreen extends StatelessWidget {
  AddSubjectScreen({super.key});

  final controller = TextEditingController();

  final service = SubjectService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nova Disciplina"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isEmpty) {
                  return;
                }

                await service.addSubject({'nome': controller.text});

                Navigator.pop(context);
              },
              child: const Text('Salvar'),
            )
          ],
        ),
      ),
    );
  }
}
