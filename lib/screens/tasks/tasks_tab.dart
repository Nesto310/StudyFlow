import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../../services/ai_service.dart';
import '../../services/api_client.dart';
import '../widgets/async_form_sheet.dart';
import '../../state/app_state.dart';

class TasksTab extends StatefulWidget {
  final AppState appState;

  const TasksTab({
    super.key,
    required this.appState,
  });

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final Map<String, bool> _loadingAi = {};
  final Set<String> _busy = {};

  void _getAiTip(TaskModel task) async {
    setState(() => _loadingAi[task.id] = true);
    final subjectName = widget.appState.findSubjectById(task.subjectId)?.name;
    final tip = await AiService.generateTaskTip(task, subjectName: subjectName);
    if (!mounted) return;
    widget.appState.setTaskAiTip(task.id, tip);

    if (mounted) {
      setState(() => _loadingAi[task.id] = false);
    }

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
        child: SingleChildScrollView(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dica IA: ${task.title}',
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
        )),
      ),
    );
  }

  void _showAddTaskDialog() {
    final subjects = widget.appState.subjects;
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cadastre uma disciplina antes de criar tarefas.')),
      );
      return;
    }
    var title = '';
    var description = '';
    var duration = '60';
    var subjectId = subjects.first.id;
    DateTime? date;
    TimeOfDay? time;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AsyncFormSheet(
        title: 'Nova Tarefa',
        submitLabel: 'Adicionar Tarefa',
        fields: (context, busy, refresh) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              enabled: !busy,
              maxLength: 200,
              decoration: const InputDecoration(
                  labelText: 'Título da Tarefa', border: OutlineInputBorder()),
              onChanged: (value) => title = value,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe o título.'
                  : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: subjectId,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Disciplina', border: OutlineInputBorder()),
              items: subjects
                  .map((subject) => DropdownMenuItem(
                        value: subject.id,
                        child:
                            Text(subject.name, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: busy
                  ? null
                  : (value) {
                      if (value != null) subjectId = value;
                    },
            ),
            const SizedBox(height: 10),
            TextFormField(
              enabled: !busy,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Descrição detalhada',
                  border: OutlineInputBorder()),
              onChanged: (value) => description = value,
            ),
            const SizedBox(height: 10),
            TextFormField(
              enabled: !busy,
              initialValue: duration,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Tempo Estimado (min)',
                  border: OutlineInputBorder()),
              onChanged: (value) => duration = value,
              validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0
                  ? 'Informe um número inteiro maior que zero.'
                  : null,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      final now = DateTime.now();
                      final selected = await showDatePicker(
                          context: context,
                          initialDate: date ?? now,
                          firstDate: DateTime(now.year - 1),
                          lastDate: DateTime(now.year + 10));
                      if (selected != null) {
                        date = selected;
                        refresh();
                      }
                    },
              icon: const Icon(Icons.calendar_today),
              label: Text(date == null
                  ? 'Data de entrega'
                  : MaterialLocalizations.of(context).formatMediumDate(date!)),
            ),
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      final selected = await showTimePicker(
                          context: context,
                          initialTime: time ?? TimeOfDay.now());
                      if (selected != null) {
                        time = selected;
                        refresh();
                      }
                    },
              icon: const Icon(Icons.schedule),
              label: Text(
                  time == null ? 'Horário de entrega' : time!.format(context)),
            ),
          ],
        ),
        onSubmit: () async {
          if (date == null || time == null) {
            throw const ApiException(
                'Selecione a data e o horário de entrega.');
          }
          await widget.appState.addTask(
              title: title,
              subjectId: subjectId,
              description: description,
              estimatedMinutes: int.parse(duration),
              dueDate: DateTime(date!.year, date!.month, date!.day, time!.hour,
                  time!.minute));
        },
      ),
    );
  }

  Future<void> _changeTask(TaskModel task, {bool delete = false}) async {
    if (_busy.contains(task.id)) return;
    setState(() => _busy.add(task.id));
    try {
      if (delete) {
        if (!await confirmDelete(context, 'Excluir tarefa?') || !mounted) {
          return;
        }
        await widget.appState.deleteTask(task.id);
      } else {
        await widget.appState.toggleTaskCompletion(task.id);
      }
    } catch (error) {
      if (mounted) showActionError(context, error);
    } finally {
      if (mounted) setState(() => _busy.remove(task.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final tasks = widget.appState.tasks;

        return Scaffold(
          appBar: AppBar(title: const Text('Tarefas e Estudos')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddTaskDialog,
            icon: const Icon(Icons.add),
            label: const Text('Nova Tarefa'),
          ),
          body: tasks.isEmpty
              ? const Center(child: Text('Nenhuma tarefa cadastrada.'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final subject = widget.appState.findSubjectById(
                      task.subjectId,
                    );
                    final subjectName = subject?.name ?? 'Disciplina';
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
                                Flexible(
                                    child: Chip(
                                  label: Text(subjectName,
                                      overflow: TextOverflow.ellipsis),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                )),
                                const SizedBox(width: 8),
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
                            Text(
                                'Entrega: ${MaterialLocalizations.of(context).formatMediumDate(task.dueDate.toLocal())} '
                                '${TimeOfDay.fromDateTime(task.dueDate.toLocal()).format(context)}'),
                            const Divider(),
                            // Opção DICA IA logo abaixo da tarefa
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
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
                                    task.aiTip != null
                                        ? 'Ver Dica IA'
                                        : 'Dica IA',
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Excluir tarefa',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: _busy.contains(task.id)
                                      ? null
                                      : () => _changeTask(task, delete: true),
                                ),
                                IconButton(
                                  tooltip: task.isCompleted
                                      ? 'Marcar como pendente'
                                      : 'Concluir tarefa',
                                  icon: Icon(
                                    task.isCompleted
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color:
                                        task.isCompleted ? Colors.green : null,
                                  ),
                                  onPressed: _busy.contains(task.id)
                                      ? null
                                      : () => _changeTask(task),
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
      },
    );
  }
}
