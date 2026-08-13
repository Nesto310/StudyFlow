class CourseModel {
  final String id;
  final String name;
  final String platform;
  final int weeklyHoursGoal;
  final int totalHours;
  final int completedHours;

  CourseModel({
    required this.id,
    required this.name,
    required this.platform,
    required this.weeklyHoursGoal,
    this.totalHours = 0,
    this.completedHours = 0,
  });
}
