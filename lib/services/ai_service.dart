import '../models/task_model.dart';

class AiService {
  static const bool hasExternalAiIntegration = false;

  static Future<String> generateTaskTip(TaskModel task) async {
    // A integração Gemini será implementada futuramente através do backend.
    return _localFallbackTip(task);
  }

  static String _localFallbackTip(TaskModel task) {
    if (task.description.trim().isEmpty) {
      return '⚠️ **Dica do Sistema**: Você não adicionou uma descrição detalhada. Para otimizar seus estudos em **${task.subject}**, defina o capítulo ou exercício alvo.\n\nSugestão: divida os ${task.estimatedMinutes} minutos em blocos de 25 minutos de foco absoluto.';
    }

    return '💡 **Roteiro Rápido**: Para "${task.title}" (${task.subject}), comece revisando conceitos-chave por 10 min e use o restante do tempo para resolução prática.';
  }
}
