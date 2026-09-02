import 'package:flutter/material.dart';

import '../../models/availability_model.dart';
import '../../models/schedule_model.dart';
import '../../services/api_client.dart';
import '../../services/scheduler_service.dart';
import '../../state/app_state.dart';
import '../widgets/async_form_sheet.dart';

class AvailabilityTab extends StatefulWidget {
  const AvailabilityTab({super.key, required this.appState});
  final AppState appState;

  @override
  State<AvailabilityTab> createState() => _AvailabilityTabState();
}

class _AvailabilityTabState extends State<AvailabilityTab> {
  List<ScheduleBlock> _generatedSchedule = [];
  final Set<String> _busy = {};
  static const _days = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_invalidateSchedule);
  }

  @override
  void dispose() {
    widget.appState.removeListener(_invalidateSchedule);
    super.dispose();
  }

  void _invalidateSchedule() {
    if (mounted && _generatedSchedule.isNotEmpty) {
      setState(() => _generatedSchedule = []);
    }
  }

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

  void _showAddSlot() {
    var day = 1;
    var start = const TimeOfDay(hour: 9, minute: 0);
    var end = const TimeOfDay(hour: 10, minute: 0);
    var repeat = true;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AsyncFormSheet(
        title: 'Novo Horário',
        submitLabel: 'Adicionar Horário',
        fields: (context, busy, refresh) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              initialValue: day,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Dia da semana', border: OutlineInputBorder()),
              items: List.generate(
                  7,
                  (index) => DropdownMenuItem(
                      value: index + 1, child: Text(_days[index]))),
              onChanged: busy
                  ? null
                  : (value) {
                      if (value != null) day = value;
                    },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      final selected = await showTimePicker(
                          context: context, initialTime: start);
                      if (selected != null) {
                        start = selected;
                        refresh();
                      }
                    },
              icon: const Icon(Icons.schedule),
              label: Text('Hora inicial: ${start.format(context)}'),
            ),
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      final selected = await showTimePicker(
                          context: context, initialTime: end);
                      if (selected != null) {
                        end = selected;
                        refresh();
                      }
                    },
              icon: const Icon(Icons.schedule),
              label: Text('Hora final: ${end.format(context)}'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Repetir na próxima semana'),
              value: repeat,
              onChanged: busy
                  ? null
                  : (value) {
                      repeat = value;
                      refresh();
                    },
            ),
          ],
        ),
        onSubmit: () async {
          if (start.hour * 60 + start.minute >= end.hour * 60 + end.minute) {
            throw const ApiException(
                'O horário final deve ser posterior ao inicial.');
          }
          await widget.appState.addAvailabilitySlot(
              dayOfWeek: day,
              startTime: timeValue(start),
              endTime: timeValue(end),
              repeatNextWeek: repeat);
        },
      ),
    );
  }

  Future<void> _changeSlot(TimeSlot slot,
      {bool delete = false, bool? repeat}) async {
    if (_busy.contains(slot.id)) return;
    setState(() => _busy.add(slot.id));
    try {
      if (delete) {
        if (!await confirmDelete(context, 'Excluir horário?') || !mounted) {
          return;
        }
        await widget.appState.deleteAvailabilitySlot(slot.id);
      } else {
        await widget.appState.updateAvailabilityRepeat(slot.id, repeat!);
      }
    } catch (error) {
      if (mounted) showActionError(context, error);
    } finally {
      if (mounted) setState(() => _busy.remove(slot.id));
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: widget.appState,
        builder: (context, _) {
          final slots = widget.appState.availabilitySlots;
          return Scaffold(
            appBar: AppBar(title: const Text('Horários Disponíveis'), actions: [
              IconButton(
                  tooltip: 'Organizar Cronograma',
                  icon: const Icon(Icons.auto_graph),
                  onPressed: slots.isEmpty ? null : _runScheduler),
            ]),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _showAddSlot,
              icon: const Icon(Icons.add),
              label: const Text('Novo Horário'),
            ),
            body: slots.isEmpty
                ? const Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Nenhum horário disponível cadastrado.',
                            textAlign: TextAlign.center)))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    children: [
                      ...slots.map((slot) => Card(
                              child: Column(children: [
                            ListTile(
                              leading: CircleAvatar(
                                  child: Text(_days[slot.dayOfWeek - 1]
                                      .substring(0, 3))),
                              title: Text(
                                  '${_days[slot.dayOfWeek - 1]}: ${slot.startHour} às ${slot.endHour}'),
                              subtitle: Text('${slot.durationMinutes} min'),
                              trailing: IconButton(
                                tooltip: 'Excluir horário',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: _busy.contains(slot.id)
                                    ? null
                                    : () => _changeSlot(slot, delete: true),
                              ),
                            ),
                            SwitchListTile(
                              title: const Text('Repetir na próxima semana'),
                              value: slot.repeatNextWeek,
                              onChanged: _busy.contains(slot.id)
                                  ? null
                                  : (value) => _changeSlot(slot, repeat: value),
                            ),
                          ]))),
                      if (_generatedSchedule.isNotEmpty) ...[
                        const Divider(height: 32),
                        Text('Cronograma Gerado pelo Algoritmo:',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ..._generatedSchedule.map((block) => Card(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.3),
                              child: ListTile(
                                leading: const Icon(Icons.schedule),
                                title: Text(block.itemTitle),
                                subtitle: Text(
                                    '${block.dayName} (${block.timeRange}) • ${block.category}'),
                              ),
                            )),
                      ],
                    ],
                  ),
          );
        },
      );
}
