import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/task_model.dart';

class AiService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static bool get hasConfiguredApiKey => _apiKey.isNotEmpty;

  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static Future<String> generateTaskTip(TaskModel task) async {
    if (!hasConfiguredApiKey) {
      return _localFallbackTip(task);
    }

    final prompt = '''
Voce e um tutor academico de alta precisao do aplicativo StudyFlow.
Analise a tarefa abaixo:
- Materia/Assunto: "${task.subject}"
- Titulo da Tarefa: "${task.title}"
- Detalhes/Descricao: "${task.description.isEmpty ? 'Sem descricao fornecida' : task.description}"
- Tempo estimado: ${task.estimatedMinutes} minutos

Instrucoes para sua resposta:
1. Se a descricao ou o titulo tiver pouquissimas informacoes, inicie dizendo objetivamente quais informacoes o estudante precisa adicionar para um direcionamento perfeito.
2. De uma dica pratica, metodo de estudo recomendado (ex: Feynman, Pomodoro, Active Recall) ou os topicos essenciais que ele deve cobrir.
3. Seja conciso, direto e motivador. Evite saudacoes longas.
''';

    try {
      final response = await http.post(
        Uri.parse('$_endpoint?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 300},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return text ?? 'Nao foi possivel extrair a sugestao da IA.';
      } else {
        return 'Erro ao consultar IA (${response.statusCode}). Verifique a configuracao da API.';
      }
    } catch (_) {
      return _localFallbackTip(task);
    }
  }

  static String _localFallbackTip(TaskModel task) {
    if (task.description.trim().isEmpty) {
      return 'Dica do sistema: voce nao adicionou uma descricao detalhada. Para otimizar seus estudos em ${task.subject}, defina o capitulo ou exercicio alvo.\n\nSugestao: divida os ${task.estimatedMinutes} minutos em blocos de 25 minutos de foco absoluto.';
    }

    return 'Roteiro rapido: para "${task.title}" (${task.subject}), comece revisando conceitos-chave por 10 min e use o restante do tempo para resolucao pratica.';
  }
}
