enum StudyPlanRisk { onTrack, atRisk, overdue }

class StudyPlan {
  StudyPlan.fromJson(Map<String, dynamic> json)
      : generatedAt = DateTime.parse(json['generated_at'] as String),
        horizonStart = DateTime.parse(json['horizon_start'] as String),
        horizonEnd = DateTime.parse(json['horizon_end'] as String),
        timezoneOffsetMinutes = json['timezone_offset_minutes'] as int,
        blocks = List.unmodifiable((json['blocks'] as List).map(
            (item) => StudyPlanBlock.fromJson(item as Map<String, dynamic>))),
        tasks = List.unmodifiable((json['tasks'] as List).map((item) =>
            StudyPlanTaskSummary.fromJson(item as Map<String, dynamic>))),
        summary =
            StudyPlanSummary.fromJson(json['summary'] as Map<String, dynamic>);

  final DateTime generatedAt;
  final DateTime horizonStart;
  final DateTime horizonEnd;
  final int timezoneOffsetMinutes;
  final List<StudyPlanBlock> blocks;
  final List<StudyPlanTaskSummary> tasks;
  final StudyPlanSummary summary;
}

class StudyPlanBlock {
  StudyPlanBlock.fromJson(Map<String, dynamic> json)
      : taskId = json['task_id'] as String,
        subjectId = json['subject_id'] as String,
        subjectName = json['subject_name'] as String,
        taskTitle = json['task_title'] as String,
        startAt = DateTime.parse(json['start_at'] as String),
        endAt = DateTime.parse(json['end_at'] as String),
        plannedMinutes = json['planned_minutes'] as int,
        dueDate = DateTime.parse(json['due_date'] as String);

  final String taskId;
  final String subjectId;
  final String subjectName;
  final String taskTitle;
  final DateTime startAt;
  final DateTime endAt;
  final int plannedMinutes;
  final DateTime dueDate;
}

class StudyPlanTaskSummary {
  StudyPlanTaskSummary.fromJson(Map<String, dynamic> json)
      : taskId = json['task_id'] as String,
        subjectId = json['subject_id'] as String,
        subjectName = json['subject_name'] as String,
        taskTitle = json['task_title'] as String,
        dueDate = DateTime.parse(json['due_date'] as String),
        estimatedMinutes = json['estimated_minutes'] as int,
        plannedMinutes = json['planned_minutes'] as int,
        unscheduledMinutes = json['unscheduled_minutes'] as int,
        risk = switch (json['risk']) {
          'on_track' => StudyPlanRisk.onTrack,
          'at_risk' => StudyPlanRisk.atRisk,
          'overdue' => StudyPlanRisk.overdue,
          _ => throw const FormatException('Invalid planner risk'),
        };

  final String taskId;
  final String subjectId;
  final String subjectName;
  final String taskTitle;
  final DateTime dueDate;
  final int estimatedMinutes;
  final int plannedMinutes;
  final int unscheduledMinutes;
  final StudyPlanRisk risk;
}

class StudyPlanSummary {
  StudyPlanSummary.fromJson(Map<String, dynamic> json)
      : totalPendingTasks = json['total_pending_tasks'] as int,
        totalPlannedMinutes = json['total_planned_minutes'] as int,
        totalUnscheduledMinutes = json['total_unscheduled_minutes'] as int,
        totalAvailableMinutes = json['total_available_minutes'] as int,
        onTrackTasks = json['on_track_tasks'] as int,
        atRiskTasks = json['at_risk_tasks'] as int,
        overdueTasks = json['overdue_tasks'] as int;

  final int totalPendingTasks;
  final int totalPlannedMinutes;
  final int totalUnscheduledMinutes;
  final int totalAvailableMinutes;
  final int onTrackTasks;
  final int atRiskTasks;
  final int overdueTasks;
}
