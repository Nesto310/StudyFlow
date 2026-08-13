import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/main.dart';

void main() {
  testWidgets('StudyFlow inicializa com a navegacao principal', (tester) async {
    await tester.pumpWidget(const StudyFlowApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Tarefas'), findsWidgets);
    expect(find.text('Cursos'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });
}
