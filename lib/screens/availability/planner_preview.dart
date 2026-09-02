import 'package:flutter/material.dart';

import '../../models/study_plan_model.dart';

class PlannerPreview extends StatelessWidget {
  const PlannerPreview({super.key, required this.plan});
  final StudyPlan plan;

  static const _days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  String _date(DateTime value) =>
      '${_days[value.weekday - 1]}, ${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final summary = plan.summary;
    final days = plan.horizonEnd.difference(plan.horizonStart).inDays;
    final grouped = <DateTime, List<StudyPlanBlock>>{};
    for (final block in plan.blocks) {
      final local = block.startAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      (grouped[day] ??= []).add(block);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 20),
      Text('Plano dos próximos $days dias',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (summary.totalPendingTasks == 0)
        const Text('Você não possui tarefas pendentes para planejar.')
      else ...[
        Text(
            '${summary.totalPlannedMinutes} min planejados · ${summary.totalUnscheduledMinutes} min não alocados'),
        Text('${summary.totalAvailableMinutes} min disponíveis'),
        const SizedBox(height: 8),
        if (summary.totalAvailableMinutes == 0)
          const Text('Cadastre horários disponíveis para gerar seu plano.'),
        if (summary.atRiskTasks > 0)
          Text(
              'Não há tempo suficiente disponível antes do prazo de ${summary.atRiskTasks} ${summary.atRiskTasks == 1 ? 'tarefa' : 'tarefas'}.'),
        if (summary.overdueTasks > 0)
          Text(
              'Você possui ${summary.overdueTasks} ${summary.overdueTasks == 1 ? 'tarefa atrasada' : 'tarefas atrasadas'} no plano.'),
        if (summary.onTrackTasks == summary.totalPendingTasks)
          const Text(
              'Todas as tarefas pendentes cabem na sua disponibilidade atual.'),
      ],
      for (final entry in grouped.entries) ...[
        Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Text(_date(entry.key),
                style: Theme.of(context).textTheme.titleMedium)),
        for (final block in entry.value)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                            '${_time(block.startAt.toLocal())} - ${_time(block.endAt.toLocal())} · ${block.plannedMinutes} min',
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 6),
                        Text(block.subjectName,
                            style: Theme.of(context).textTheme.labelLarge),
                        Text(block.taskTitle),
                      ]))),
      ],
    ]);
  }
}
