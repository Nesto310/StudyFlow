import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'services/theme_controller.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudyFlowApp());
}

class StudyFlowApp extends StatelessWidget {
  const StudyFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'StudyFlow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          home: const MainNavigationScreen(),
        );
      },
    );
  }
}