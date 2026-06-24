class SubjectModel {
  final String id;
  final String name;
  final String teacher;

  SubjectModel({
    required this.id,
    required this.name,
    required this.teacher,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'teacher': teacher,
    };
  }

  factory SubjectModel.fromMap(Map<String, dynamic> map) {
    return SubjectModel(
      id: map['id'],
      name: map['name'],
      teacher: map['teacher'],
    );
  }
}
