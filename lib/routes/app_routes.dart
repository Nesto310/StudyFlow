import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/add_task_screen.dart';
import '../screens/add_subject_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String addTask = '/add-task';
  static const String addSubject = '/add-subject';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (context) => const HomeScreen(),
      addTask: (context) => const AddTaskScreen(),
      addSubject: (context) => const AddSubjectScreen(),
    };
  }
}
