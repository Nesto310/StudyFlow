import 'package:flutter/material.dart';

import '../screens/add_subject_screen.dart';
import '../screens/add_task_screen.dart';
import '../screens/home_screen.dart';
import '../screens/subject_screen.dart';
import '../screens/task_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String addTask = '/tasks/new';
  static const String taskDetails = '/tasks/details';
  static const String addSubject = '/subjects/new';
  static const String subjectDetails = '/subjects/details';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const HomeScreen(),
      addTask: (context) => const AddTaskScreen(),
      addSubject: (context) => const AddSubjectScreen(),
    };
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case taskDetails:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => TaskScreen(taskId: args),
            settings: settings,
          );
        }
        break;
      case subjectDetails:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => SubjectScreen(subjectId: args),
            settings: settings,
          );
        }
        break;
    }

    return MaterialPageRoute(
      builder: (_) => const HomeScreen(),
      settings: settings,
    );
  }
}
