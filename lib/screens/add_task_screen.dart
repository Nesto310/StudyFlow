import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class AddTaskScreen extends StatefulWidget {[cite: 1]
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();[cite: 1]
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>(); // Chave para validação
  final _titleController = TextEditingController();[cite: 4]
  final _descController = TextEditingController();
  final _taskService = TaskService();

  // Simulação do envio do formulário (POST)
  void _submitForm() async {
    if (_formKey.currentState!.validate()) { // Validação do formulário
      final newTask = TaskModel(
        id: DateTime.now().toString(), // ID dinâmico temporário
        title: _titleController.text,
        description: _descController.text,
      );

      await _taskService.saveTask(newTask); // Enviando para o nosso "backend" local

      if (mounted) {
        Navigator.pop(context); // Retorna à tela home atualizada[cite: 1, 4]
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold([cite: 4]
      appBar: AppBar(title: const Text('Nova Tarefa')),[cite: 4]
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField([cite: 4]
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título da Tarefa'),
                validator: (value) { // Validação exigida pelo professor
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira um título válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Salvar Tarefa (POST)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}