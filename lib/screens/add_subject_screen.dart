import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../services/subject_service.dart';

class AddSubjectScreen extends StatefulWidget {
  const AddSubjectScreen({super.key});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _teacherController = TextEditingController();
  final SubjectService _subjectService = SubjectService();

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final newSubject = SubjectModel(
        id: DateTime.now().toIso8601String(),
        name: _nameController.text,
        teacher: _teacherController.text,
      );
      await _subjectService.postSubject(newSubject);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Matéria')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome da Matéria'),
                validator: (value) => (value == null || value.isEmpty) ? 'Insira o nome da disciplina' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _teacherController,
                decoration: const InputDecoration(labelText: 'Nome do Professor'),
                validator: (value) => (value == null || value.isEmpty) ? 'Insira o nome do professor' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text('Cadastrar Disciplina (POST)'),
              )
            ],
          ),
        ),
      ),
    );
  }
}