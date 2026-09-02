class TimeSlot {
  final String id;
  final int dayOfWeek; // 1 = Segunda, 7 = Domingo
  final String startHour; // Formato "HH:mm" (ex: "14:00")
  final String endHour; // Formato "HH:mm" (ex: "18:00")
  final int durationMinutes;
  final bool repeatNextWeek;

  TimeSlot({
    required this.id,
    required this.dayOfWeek,
    required this.startHour,
    required this.endHour,
    required this.durationMinutes,
    this.repeatNextWeek = true,
  });

  TimeSlot copyWith({
    String? id,
    int? dayOfWeek,
    String? startHour,
    String? endHour,
    int? durationMinutes,
    bool? repeatNextWeek,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      repeatNextWeek: repeatNextWeek ?? this.repeatNextWeek,
    );
  }
}
