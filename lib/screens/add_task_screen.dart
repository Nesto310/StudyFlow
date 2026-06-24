import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final TaskService _taskService = TaskService();

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final newTask = TaskModel(
        id: DateTime.now().toIso8601String(),
        title: _titleController.text,
        description: _descController.text,
      );
      await _taskService.postTask(newTask);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adicionar Tarefa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration:
                    const InputDecoration(labelText: 'Título da Tarefa'),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Campo obrigatório'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration:
                    const InputDecoration(labelText: 'Descrição detalhada'),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Insira uma breve descrição'
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                child: const Text('Salvar no Sistema (POST)'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
