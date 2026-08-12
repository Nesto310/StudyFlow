class TaskModel {
  final String id;
  final String title;
  final String subject;
  final String description;
  final int estimatedMinutes;
  final DateTime dueDate;
  final bool isCompleted;
  String? aiTip;

  TaskModel({
    required this.id,
    required this.title,
    required this.subject,
    this.description = '',
    required this.estimatedMinutes,
    required this.dueDate,
    this.isCompleted = false,
    this.aiTip,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? subject,
    String? description,
    int? estimatedMinutes,
    DateTime? dueDate,
    bool? isCompleted,
    String? aiTip,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      aiTip: aiTip ?? this.aiTip,
    );
  }
}