import '../models/task_model.dart';
import '../models/course_model.dart';
import '../models/availability_model.dart';
import '../models/schedule_model.dart';

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
        schedule.add(
          ScheduleBlock(
            dayName: dayName,
            timeRange: timeRange,
            itemTitle: '${task.subject}: ${task.title}',
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
}
