import 'package:flutter/material.dart';
import '../../state/app_state.dart';

class SubjectsTab extends StatelessWidget {
  final AppState appState;

  const SubjectsTab({
    super.key,
    required this.appState,
  });

  void _showAddSubjectDialog(BuildContext context) {
    final nameController = TextEditingController();
    final teacherController = TextEditingController();

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
              'Nova Disciplina',
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da disciplina',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: teacherController,
              decoration: const InputDecoration(
                labelText: 'Professor',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) {
                    return;
                  }

                  appState.addSubject(
                    name: nameController.text,
                    teacher: teacherController.text,
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Adicionar Disciplina'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _removeSubject(BuildContext context, String subjectId) {
    final removed = appState.removeSubject(subjectId);
    if (removed) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Não é possível remover uma disciplina com tarefas vinculadas.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final subjects = appState.subjects;

        return Scaffold(
          appBar: AppBar(title: const Text('Disciplinas')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddSubjectDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Nova Disciplina'),
          ),
          body: subjects.isEmpty
              ? const Center(child: Text('Nenhuma disciplina cadastrada.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    final hasTasks = appState.hasTasksForSubject(subject.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.book)),
                        title: Text(subject.name),
                        subtitle: subject.teacher.isEmpty
                            ? const Text('Professor não informado')
                            : Text(subject.teacher),
                        trailing: IconButton(
                          tooltip: hasTasks
                              ? 'Há tarefas vinculadas'
                              : 'Remover disciplina',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeSubject(context, subject.id),
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
