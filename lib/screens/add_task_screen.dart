import 'package:flutter/material.dart';

import '../models/subject_model.dart';
import '../models/task_model.dart';
import '../routes/app_routes.dart';
import '../services/subject_service.dart';
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
  final SubjectService _subjectService = SubjectService();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  String? _subjectId;
  bool _isSaving = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final task = TaskModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      subjectId: _subjectId!,
      dueDate: _dueDate,
    );

    try {
      await _taskService.postTask(task);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ArgumentError catch (error) {
      _showMessage(error.message.toString());
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selected != null) {
      setState(() => _dueDate = selected);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
      appBar: AppBar(title: const Text('Adicionar tarefa')),
      body: FutureBuilder<List<SubjectModel>>(
        future: _subjectService.getSubjects(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final subjects = snapshot.data ?? [];
          if (subjects.isEmpty) {
            return _EmptySubjectsState(onCreateSubject: () {
              Navigator.pushNamed(context, AppRoutes.addSubject).then((_) {
                if (mounted) {
                  setState(() {});
                }
              });
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titulo da tarefa',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 3) {
                        return 'Informe pelo menos 3 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Descricao',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 3,
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().length < 5) {
                        return 'Descreva melhor a tarefa.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _subjectId,
                    decoration: const InputDecoration(
                      labelText: 'Materia',
                      border: OutlineInputBorder(),
                    ),
                    items: subjects
                        .map(
                          (subject) => DropdownMenuItem(
                            value: subject.id,
                            child: Text(subject.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _subjectId = value),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Selecione uma materia.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('Data de entrega'),
                    subtitle: Text(_formatDate(_dueDate)),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Salvar tarefa (POST)'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _EmptySubjectsState extends StatelessWidget {
  final VoidCallback onCreateSubject;

  const _EmptySubjectsState({required this.onCreateSubject});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_outlined, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Cadastre uma materia antes de criar tarefas.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreateSubject,
              icon: const Icon(Icons.add),
              label: const Text('Nova materia'),
            ),
          ],
        ),
      ),
    );
  }
}
