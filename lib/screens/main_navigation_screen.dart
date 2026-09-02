import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../state/auth_state.dart';
import 'availability/availability_tab.dart';
import 'courses/courses_tab.dart';
import 'profile/profile_tab.dart';
import 'subjects/subjects_tab.dart';
import 'tasks/tasks_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  final AppState appState;
  final AuthState authState;

  const MainNavigationScreen({
    super.key,
    required this.appState,
    required this.authState,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      TasksTab(appState: widget.appState),
      SubjectsTab(appState: widget.appState),
      AvailabilityTab(appState: widget.appState),
      const CoursesTab(),
      ProfileTab(authState: widget.authState),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Tarefas',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Disciplinas',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Horários',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Cursos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
