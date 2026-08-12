class ScheduleBlock {
  final String dayName;
  final String timeRange;
  final String itemTitle;
  final String category; // 'Tarefa' ou 'Curso'

  ScheduleBlock({
    required this.dayName,
    required this.timeRange,
    required this.itemTitle,
    required this.category,
  });
}