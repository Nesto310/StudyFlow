import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studyflow/main.dart';

void main() {
  testWidgets('StudyFlow abre a tela inicial', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const StudyFlowApp());
    await tester.pumpAndSettle();

    expect(find.text('StudyFlow - Controle academico'), findsOneWidget);
    expect(find.text('Tarefas'), findsOneWidget);
    expect(find.text('Materias'), findsOneWidget);
  });
}
