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

  static int timeToMinutes(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})(?::(\d{2})(?:\.\d{1,6})?)?$')
        .firstMatch(value);
    if (match == null) throw const FormatException('Invalid time');
    final hour = int.parse(match[1]!);
    final minute = int.parse(match[2]!);
    final second = int.parse(match[3] ?? '0');
    if (hour > 23 || minute > 59 || second > 59) {
      throw const FormatException('Invalid time');
    }
    return hour * 60 + minute;
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    final start = json['start_time'] as String;
    final end = json['end_time'] as String;
    final duration = timeToMinutes(end) - timeToMinutes(start);
    final day = json['day_of_week'] as int;
    if (duration < 0 || day < 1 || day > 7) {
      throw const FormatException('Invalid availability');
    }
    return TimeSlot(
      id: json['id'] as String,
      dayOfWeek: day,
      startHour: start.substring(0, 5),
      endHour: end.substring(0, 5),
      durationMinutes: duration,
      repeatNextWeek: json['repeat_next_week'] as bool,
    );
  }
}
