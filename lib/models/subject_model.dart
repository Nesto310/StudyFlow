class SubjectModel {
  final String id;
  final String name;
  final String teacher;
  final int workloadHours;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.teacher,
    required this.workloadHours,
  });

  SubjectModel copyWith({
    String? name,
    String? teacher,
    int? workloadHours,
  }) {
    return SubjectModel(
      id: id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      workloadHours: workloadHours ?? this.workloadHours,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teacher': teacher,
      'workloadHours': workloadHours,
    };
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'] as String,
      name: map['name'] as String,
      teacher: map['teacher'] as String,
      workloadHours: (map['workloadHours'] as num?)?.toInt() ?? 0,
    );
  }
}
