class TaskModel {
  final String id;
  final String title;
  final String subjectId;
  final String description;
  final int estimatedMinutes;
  final DateTime dueDate;
  final bool isCompleted;
  final String? aiTip;

  TaskModel({
    required this.id,
    required this.title,
    required this.subjectId,
    this.description = '',
    required this.estimatedMinutes,
    required this.dueDate,
    this.isCompleted = false,
    this.aiTip,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? subjectId,
    String? description,
    int? estimatedMinutes,
    DateTime? dueDate,
    bool? isCompleted,
    String? aiTip,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subjectId: subjectId ?? this.subjectId,
      description: description ?? this.description,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      aiTip: aiTip ?? this.aiTip,
    );
  }
}
