import 'package:flutter/material.dart';
import '../../models/availability_model.dart';
import '../../models/schedule_model.dart';
import '../../services/scheduler_service.dart';

class AvailabilityTab extends StatefulWidget {
  const AvailabilityTab({super.key});

  @override
  State<AvailabilityTab> createState() => _AvailabilityTabState();
}

class _AvailabilityTabState extends State<AvailabilityTab> {
  final List<TimeSlot> _slots = [
    TimeSlot(
        id: '1',
        dayOfWeek: 1,
        startHour: '14:00',
        endHour: '16:00',
        durationMinutes: 120,
        repeatNextWeek: true),
    TimeSlot(
        id: '2',
        dayOfWeek: 3,
        startHour: '19:00',
        endHour: '21:00',
        durationMinutes: 120,
        repeatNextWeek: true),
    TimeSlot(
        id: '3',
        dayOfWeek: 5,
        startHour: '10:00',
        endHour: '12:00',
        durationMinutes: 120,
        repeatNextWeek: false),
  ];

  List<ScheduleBlock> _generatedSchedule = [];

  final List<String> _days = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo'
  ];

  void _runScheduler() {
    setState(() {
      _generatedSchedule = SchedulerService.generateOptimalSchedule(
        slots: _slots,
        tasks: [],
        courses: [],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Slots Configurados:',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._slots.map((slot) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                        child: Text(_days[slot.dayOfWeek - 1].substring(0, 3))),
                    title: Text(
                        '${_days[slot.dayOfWeek - 1]}: ${slot.startHour} às ${slot.endHour}'),
                    subtitle: Text(slot.repeatNextWeek
                        ? '🔁 Replicar semanalmente'
                        : '🗓️ Apenas nesta semana'),
                    trailing: Switch(
                      value: slot.repeatNextWeek,
                      onChanged: (val) {
                        setState(() {
                          final idx = _slots.indexWhere((s) => s.id == slot.id);
                          _slots[idx] = TimeSlot(
                            id: slot.id,
                            dayOfWeek: slot.dayOfWeek,
                            startHour: slot.startHour,
                            endHour: slot.endHour,
                            durationMinutes: slot.durationMinutes,
                            repeatNextWeek: val,
                          );
                        });
                      },
                    ),
                  ),
                )),
            const SizedBox(height: 20),
            if (_generatedSchedule.isNotEmpty) ...[
              const Divider(),
              Text('Cronograma Gerado pelo Algoritmo:',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._generatedSchedule.map((b) => Card(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    child: ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text(b.itemTitle),
                      subtitle:
                          Text('${b.dayName} (${b.timeRange}) • ${b.category}'),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
