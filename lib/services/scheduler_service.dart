import '../models/availability_model.dart';
import '../models/course_model.dart';
import '../models/schedule_model.dart';
import '../models/subject_model.dart';
import '../models/task_model.dart';

class SchedulerService {
  static final List<String> _weekDays = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  static List<ScheduleBlock> generateOptimalSchedule({
    required List<TimeSlot> slots,
    required List<TaskModel> tasks,
    required List<CourseModel> courses,
    required List<SubjectModel> subjects,
  }) {
    List<ScheduleBlock> schedule = [];

    // 1. Filtrar e ordenar tarefas pendentes por urgência (dueDate)
    final pendingTasks = tasks.where((t) => !t.isCompleted).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // 2. Ordenar horários por dia da semana
    final sortedSlots = List<TimeSlot>.from(slots)
      ..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));

    int taskIndex = 0;
    int courseIndex = 0;

    for (var slot in sortedSlots) {
      final dayName = _weekDays[slot.dayOfWeek - 1];
      final timeRange = '${slot.startHour} - ${slot.endHour}';

      // Alterna ou prioriza tarefas urgentes sobre cursos
      if (taskIndex < pendingTasks.length) {
        final task = pendingTasks[taskIndex];
        final subjectName = _subjectNameFor(task.subjectId, subjects);
        schedule.add(
          ScheduleBlock(
            dayName: dayName,
            timeRange: timeRange,
            itemTitle: '$subjectName: ${task.title}',
            category: 'Tarefa (Urgente)',
          ),
        );
        taskIndex++;
      } else if (courses.isNotEmpty) {
        final course = courses[courseIndex % courses.length];
        schedule.add(
          ScheduleBlock(
            dayName: dayName,
            timeRange: timeRange,
            itemTitle: 'Curso: ${course.name} (${course.platform})',
            category: 'Curso',
          ),
        );
        courseIndex++;
      } else {
        schedule.add(
          ScheduleBlock(
            dayName: dayName,
            timeRange: timeRange,
            itemTitle: 'Bloco Livre / Revisão Geral',
            category: 'Livre',
          ),
        );
      }
    }

    return schedule;
  }

  static String _subjectNameFor(String subjectId, List<SubjectModel> subjects) {
    for (final subject in subjects) {
      if (subject.id == subjectId) {
        return subject.name;
      }
    }

    return 'Disciplina';
  }
}
