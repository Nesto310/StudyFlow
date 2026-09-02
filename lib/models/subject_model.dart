class SubjectModel {
  final String id;
  final String name;
  final String teacher;

  const SubjectModel({
    required this.id,
    required this.name,
    this.teacher = '',
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) => SubjectModel(
        id: json['id'] as String,
        name: json['name'] as String,
        teacher: json['teacher'] as String? ?? '',
      );
}
