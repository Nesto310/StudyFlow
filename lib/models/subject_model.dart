class SubjectModel {
  final String id;
  final String name;
  final String teacher;

  const SubjectModel({
    required this.id,
    required this.name,
    this.teacher = '',
  });
}
