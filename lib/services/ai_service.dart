import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

class AiService {
  // Substitua pela sua chave de API
  static const String apiKey = '***REMOVED_GEMINI_API_KEY***';
  
  // Endpoint Google Gemini REST API
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static Future<String> generateTaskTip(TaskModel task) async {
    if (apiKey == '***REMOVED_GEMINI_API_KEY***' || apiKey.isEmpty) {
      return _localFallbackTip(task);
    }

    final prompt = '''
Você é um tutor acadêmico de alta precisão do aplicativo StudyFlow.
Analise a tarefa abaixo:
- Matéria/Assunto: "${task.subject}"
- Título da Tarefa: "${task.title}"
- Detalhes/Descrição: "${task.description.isEmpty ? 'Sem descrição fornecida' : task.description}"
- Tempo estimado: ${task.estimatedMinutes} minutos

Instruções para sua resposta:
1. Se a descrição ou o título tiver pouquíssimas informações, inicie dizendo objetivamente quais informações o estudante precisa adicionar para um direcionamento perfeito.
2. Dê uma dica prática, método de estudo recomendado (ex: Feynman, Pomodoro, Active Recall) ou os tópicos essenciais que ele deve cobrir.
3. Seja conciso, direto e motivador. Evite saudações longas.
''';

    try {
      final response = await http.post(
        Uri.parse('$_endpoint?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 300,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return text ?? 'Não foi possível extrair a sugestão da IA.';
      } else {
        return 'Erro ao consultar IA (${response.statusCode}). Verifique a chave de API.';
      }
    } catch (e) {
      return 'Erro na conexão com o serviço de IA: $e';
    }
  }

  static String _localFallbackTip(TaskModel task) {
    if (task.description.trim().isEmpty) {
      return '⚠️ **Dica do Sistema**: Você não adicionou uma descrição detalhada. Para otimizar seus estudos em **${task.subject}**, defina o capítulo ou exercício alvo.\n\nSugestão: Divida os ${task.estimatedMinutes} minutos em blocos de 25 minutos de foco absoluto.';
    }
    return '💡 **Roteiro Rápido**: Para "${task.title}" (${task.subject}), comece revisando conceitos-chave por 10 min e use o restante do tempo para resolução prática.';
  }
}