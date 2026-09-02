import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../widgets/async_form_sheet.dart';

class SubjectsTab extends StatefulWidget {
  const SubjectsTab({super.key, required this.appState});
  final AppState appState;

  @override
  State<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<SubjectsTab> {
  final Set<String> _busy = {};

  void _showAddSubjectDialog() {
    var name = '';
    var teacher = '';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AsyncFormSheet(
        title: 'Nova Disciplina',
        submitLabel: 'Adicionar Disciplina',
        fields: (context, busy, refresh) => Column(children: [
          TextFormField(
            enabled: !busy,
            maxLength: 160,
            decoration: const InputDecoration(
                labelText: 'Nome da disciplina', border: OutlineInputBorder()),
            onChanged: (value) => name = value,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Informe o nome da disciplina.'
                : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            enabled: !busy,
            maxLength: 160,
            decoration: const InputDecoration(
                labelText: 'Professor', border: OutlineInputBorder()),
            onChanged: (value) => teacher = value,
          ),
        ]),
        onSubmit: () async {
          await widget.appState.addSubject(name: name, teacher: teacher);
        },
      ),
    );
  }

  Future<void> _removeSubject(String id) async {
    if (_busy.contains(id)) return;
    setState(() => _busy.add(id));
    try {
      if (!await confirmDelete(context, 'Excluir disciplina?') || !mounted) {
        return;
      }
      await widget.appState.removeSubject(id);
    } catch (error) {
      if (mounted) showActionError(context, error);
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.appState,
        builder: (context, _) {
          final subjects = widget.appState.subjects;
          return Scaffold(
            appBar: AppBar(title: const Text('Disciplinas')),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _showAddSubjectDialog,
              icon: const Icon(Icons.add),
              label: const Text('Nova Disciplina'),
            ),
            body: subjects.isEmpty
                ? const Center(child: Text('Nenhuma disciplina cadastrada.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.book)),
                          title: Text(subject.name),
                          subtitle: Text(subject.teacher.isEmpty
                              ? 'Professor não informado'
                              : subject.teacher),
                          trailing: IconButton(
                            tooltip: 'Remover disciplina',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: _busy.contains(subject.id)
                                ? null
                                : () => _removeSubject(subject.id),
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      );
}
