import 'package:flutter/material.dart';
import '../../models/schedule_model.dart';
import '../../services/scheduler_service.dart';
import '../../state/app_state.dart';

class AvailabilityTab extends StatefulWidget {
  final AppState appState;

  const AvailabilityTab({
    super.key,
    required this.appState,
  });

  @override
  State<AvailabilityTab> createState() => _AvailabilityTabState();
}

class _AvailabilityTabState extends State<AvailabilityTab> {
  List<ScheduleBlock> _generatedSchedule = [];

  final List<String> _days = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];

  void _runScheduler() {
    setState(() {
      _generatedSchedule = SchedulerService.generateOptimalSchedule(
        slots: widget.appState.availabilitySlots,
        tasks: widget.appState.tasks,
        courses: [],
        subjects: widget.appState.subjects,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        final slots = widget.appState.availabilitySlots;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Horários Disponíveis'),
            actions: [
              IconButton(
                tooltip: 'Organizar Cronograma',
                icon: const Icon(Icons.auto_graph),
                onPressed: _runScheduler,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Marque "Repetir na próxima semana" para replicar automaticamente seu quadro de disponibilidade.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Slots Configurados:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...slots.map(
                  (slot) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(_days[slot.dayOfWeek - 1].substring(0, 3)),
                      ),
                      title: Text(
                        '${_days[slot.dayOfWeek - 1]}: ${slot.startHour} às ${slot.endHour}',
                      ),
                      subtitle: Text(
                        slot.repeatNextWeek
                            ? '🔁 Replicar semanalmente'
                            : '🗓️ Apenas nesta semana',
                      ),
                      trailing: Switch(
                        value: slot.repeatNextWeek,
                        onChanged: (val) {
                          widget.appState.updateAvailabilityRepeat(
                            slot.id,
                            val,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_generatedSchedule.isNotEmpty) ...[
                  const Divider(),
                  Text(
                    'Cronograma Gerado pelo Algoritmo:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._generatedSchedule.map(
                    (b) => Card(
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      child: ListTile(
                        leading: const Icon(Icons.schedule),
                        title: Text(b.itemTitle),
                        subtitle: Text(
                          '${b.dayName} (${b.timeRange}) • ${b.category}',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
