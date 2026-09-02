import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studyflow/main.dart';

void main() {
  testWidgets('StudyFlow inicializa com a navegação principal', (tester) async {
    await tester.pumpWidget(const StudyFlowApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Tarefas'), findsWidgets);
    expect(find.text('Disciplinas'), findsOneWidget);
    expect(find.text('Horários'), findsOneWidget);
    expect(find.text('Cursos'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });
}
