class TaskModel {
  final String id;
  final String title;
  final String description;
  final String subjectId;
  final DateTime dueDate;
  final bool isCompleted;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.dueDate,
    this.isCompleted = false,
  });

  TaskModel copyWith({
    String? title,
    String? description,
    String? subjectId,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // POST: prepara os dados do formulario para persistencia local.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'subjectId': subjectId,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  // GET: reconstroi o objeto a partir dos dados persistidos.
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      subjectId: (map['subjectId'] as String?) ?? '',
      dueDate: DateTime.tryParse(map['dueDate'] as String? ?? '') ??
          DateTime.now(),
      isCompleted: map['isCompleted'] == true || map['isCompleted'] == 1,
    );
  }
}
