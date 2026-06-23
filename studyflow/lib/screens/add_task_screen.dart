import 'package:flutter/material.dart';

import '../services/task_service.dart';

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});

  final titulo = TextEditingController();

  final disciplina = TextEditingController();

  final prazo = TextEditingController();

  final service = TaskService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nova Tarefa")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titulo,
              decoration: InputDecoration(labelText: "Título"),
            ),
            TextField(
              controller: disciplina,
              decoration: InputDecoration(labelText: "Disciplina"),
            ),
            TextField(
              controller: prazo,
              decoration: InputDecoration(labelText: "Prazo"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titulo.text.isEmpty) {
                  return;
                }

                await service.addTask({
                  'titulo': titulo.text,
                  'disciplina': disciplina.text,
                  'prazo': prazo.text,
                  'status': 'Pendente'
                });

                Navigator.pop(context);
              },
              child: const Text("Salvar"),
            )
          ],
        ),
      ),
    );
  }
}
