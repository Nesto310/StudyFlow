import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/state/app_state.dart';

void main() {
  group('AppState', () {
    test('adiciona disciplina', () {
      final state = AppState();
      final initialCount = state.subjects.length;

      final subject = state.addSubject(
        name: 'Desenvolvimento Mobile',
        teacher: 'Prof. Carla',
      );

      expect(state.subjects.length, initialCount + 1);
      expect(subject.name, 'Desenvolvimento Mobile');
      expect(subject.teacher, 'Prof. Carla');
      expect(state.findSubjectById(subject.id), subject);
    });

    test('adiciona tarefa vinculada a uma disciplina', () {
      final state = AppState();
      final subject = state.addSubject(name: 'Engenharia de Software');

      final task = state.addTask(
        title: 'Revisar requisitos',
        subjectId: subject.id,
        estimatedMinutes: 50,
        dueDate: DateTime(2026, 9, 10),
      );

      expect(task.subjectId, subject.id);
      expect(state.tasks.last.id, task.id);
      expect(state.findSubjectById(state.tasks.last.subjectId), subject);
    });

    test('marca tarefa como concluída', () {
      final state = AppState();
      final task = state.tasks.first;

      state.toggleTaskCompletion(task.id);

      final updated = state.tasks.firstWhere((item) => item.id == task.id);
      expect(updated.isCompleted, isTrue);
    });

    test('altera recorrência de disponibilidade', () {
      final state = AppState();
      final slot = state.availabilitySlots.first;

      state.updateAvailabilityRepeat(slot.id, !slot.repeatNextWeek);

      final updated = state.availabilitySlots.firstWhere(
        (item) => item.id == slot.id,
      );
      expect(updated.repeatNextWeek, !slot.repeatNextWeek);
    });

    test('impede remoção de disciplina que possui tarefa vinculada', () {
      final state = AppState();
      final subjectId = state.tasks.first.subjectId;

      final removed = state.removeSubject(subjectId);

      expect(removed, isFalse);
      expect(state.findSubjectById(subjectId), isNotNull);
    });
  });
}
