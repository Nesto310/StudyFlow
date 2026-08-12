import 'package:flutter/material.dart';
import '../../models/course_model.dart';

class CoursesTab extends StatefulWidget {
  const CoursesTab({super.key});

  @override
  State<CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<CoursesTab> {
  final List<CourseModel> _courses = [
    CourseModel(
      id: '1',
      name: 'Flutter & Dart Avançado',
      platform: 'Udemy',
      weeklyHoursGoal: 4,
      totalHours: 40,
      completedHours: 12,
    ),
    CourseModel(
      id: '2',
      name: 'Arquitetura de Software',
      platform: 'Coursera',
      weeklyHoursGoal: 3,
      totalHours: 20,
      completedHours: 6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Cursos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Novo Curso'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          final progress = course.totalHours > 0 ? course.completedHours / course.totalHours : 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        course.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Chip(label: Text(course.platform, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Meta: ${course.weeklyHoursGoal} horas semanais reservadas'),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 6),
                  Text(
                    'Progresso: ${course.completedHours}h de ${course.totalHours}h (${(progress * 100).toInt()}%)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}