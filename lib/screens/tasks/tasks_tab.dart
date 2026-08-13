import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../services/ai_service.dart';

class TasksTab extends StatefulWidget {
  const TasksTab({super.key});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final List<TaskModel> _tasks = [
    TaskModel(
      id: '1',
      title: 'Estruturas de Dados em Árvore',
      subject: 'Algoritmos',
      description: 'Implementar balanceamento AVL e percurso em ordem.',
      estimatedMinutes: 90,
      dueDate: DateTime.now().add(const Duration(days: 2)),
    ),
    TaskModel(
      id: '2',
      title: 'Normalização de Banco de Dados',
      subject: 'Banco de Dados',
      description: '',
      estimatedMinutes: 45,
      dueDate: DateTime.now().add(const Duration(days: 4)),
    ),
  ];

  final Map<String, bool> _loadingAi = {};

  void _getAiTip(TaskModel task) async {
    setState(() => _loadingAi[task.id] = true);
    final tip = await AiService.generateTaskTip(task);
    setState(() {
      task.aiTip = tip;
      _loadingAi[task.id] = false;
    });

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Dica IA: ${task.title}',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(tip, style: const TextStyle(fontSize: 15, height: 1.4)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Entendido'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    final descController = TextEditingController();
    final durationController = TextEditingController(text: '60');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nova Tarefa',
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Título da Tarefa',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Matéria / Assunto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descrição detalhada',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tempo Estimado (min)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    setState(() {
                      _tasks.add(
                        TaskModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleController.text,
                          subject: subjectController.text,
                          description: descController.text,
                          estimatedMinutes:
                              int.tryParse(durationController.text) ?? 60,
                          dueDate: DateTime.now().add(const Duration(days: 3)),
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Adicionar Tarefa'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tarefas e Estudos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nova Tarefa'),
      ),
      body: _tasks.isEmpty
          ? const Center(child: Text('Nenhuma tarefa cadastrada.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                final isLoading = _loadingAi[task.id] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text(task.subject),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                            ),
                            Text(
                              '${task.estimatedMinutes} min',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(),
                        // Opção DICA IA logo abaixo da tarefa
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed:
                                  isLoading ? null : () => _getAiTip(task),
                              icon: isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.auto_awesome,
                                      size: 18,
                                      color: Colors.amber,
                                    ),
                              label: Text(
                                task.aiTip != null ? 'Ver Dica IA' : 'Dica IA',
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                task.isCompleted
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: task.isCompleted ? Colors.green : null,
                              ),
                              onPressed: () {
                                setState(() {
                                  _tasks[index] = task.copyWith(
                                    isCompleted: !task.isCompleted,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
