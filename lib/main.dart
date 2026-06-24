import 'package:flutter/material.dart';
import 'routes/app_routes.dart';

void main() {
  runApp(const MyApp());[cite: 4]
}

class MyApp extends StatelessWidget {[cite: 1, 4]
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {[cite: 1]
    return MaterialApp([cite: 4]
      title: 'Studyflow',
      theme: ThemeData(primarySwatch: Colors.blue),[cite: 4]
      initialRoute: AppRoutes.home,[cite: 4]
      routes: AppRoutes.getRoutes(),
    );
  }
}