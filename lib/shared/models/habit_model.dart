import 'package:flutter/material.dart';

// Enum tipe habit
enum HabitType { good, bad }

// Enum frekuensi (khusus good habit)
enum HabitFrequency { daily, weekly }

class HabitModel {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final Color color;
  final HabitType type;
  final HabitFrequency frequency;
  final String? groupId;
  final String? reason;        // khusus bad habit: alasan berhenti
  final bool isPaused;
  final DateTime createdAt;
  final int? targetValue;
  final String? unit;

  const HabitModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.frequency = HabitFrequency.daily,
    this.groupId,
    this.reason,
    this.isPaused = false,
    this.targetValue,
    this.unit,
    required this.createdAt,
  });

  // Dari JSON Supabase
  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '🌟',
      color: Color(int.parse(
          (json['color'] as String? ?? 'FF6750A4').replaceFirst('#', 'FF'),
          radix: 16)),
      type: json['type'] == 'bad' ? HabitType.bad : HabitType.good,
      frequency: json['frequency'] == 'weekly'
          ? HabitFrequency.weekly
          : HabitFrequency.daily,
      groupId: json['group_id'] as String?,
      reason: json['reason'] as String?,
      isPaused: json['is_paused'] as bool? ?? false,
      targetValue: json['target_value'] as int?,
      unit: json['unit'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Ke JSON untuk Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      'type': type == HabitType.bad ? 'bad' : 'good',
      'frequency': frequency == HabitFrequency.weekly ? 'weekly' : 'daily',
      'group_id': groupId,
      'reason': reason,
      'is_paused': isPaused,
      'target_value': targetValue,
      'unit': unit,
      'created_at': createdAt.toIso8601String(),
    };
  }

  HabitModel copyWith({
    String? name,
    String? icon,
    Color? color,
    HabitFrequency? frequency,
    String? groupId,
    String? reason,
    bool? isPaused,
  }) {
    return HabitModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type,
      frequency: frequency ?? this.frequency,
      groupId: groupId ?? this.groupId,
      reason: reason ?? this.reason,
      isPaused: isPaused ?? this.isPaused,
      createdAt: createdAt,
    );
  }
}

// Model untuk log good habit (check-in harian)
class HabitLog {
  final String id;
  final String habitId;
  final String userId;
  final DateTime completedAt;
  final String? note;
  final bool isCompleted;
  final int? progress;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.completedAt,
    this.note,
    required this.isCompleted,
    this.progress // 🔥 TAMBAH INI
  });

  factory HabitLog.fromJson(Map<String, dynamic> json) {
    return HabitLog(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      userId: json['user_id'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      note: json['note'] as String?,
      isCompleted: json['is_completed'] ?? false,
      progress: json['progress'] // 🔥 INI KUNCI
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habit_id': habitId,
      'user_id': userId,
      'completed_at': completedAt.toIso8601String(),
      'note': note,
      'is_completed': isCompleted, // 🔥 TAMBAH INI
    };
  }
}

// Model untuk sesi bad habit (timer berjalan)
class BadHabitSession {
  final String id;
  final String habitId;
  final String userId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationDays;
  final bool isCurrent;

  const BadHabitSession({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.startedAt,
    this.endedAt,
    this.durationDays,
    this.isCurrent = true,
  });

  // Hitung durasi sesi saat ini secara real-time
  Duration get currentDuration {
    final end = endedAt ?? DateTime.now().toUtc(); // ✅ FIX
    return end.difference(startedAt);
  }

  int get currentDays => currentDuration.inDays;
  int get currentHours => currentDuration.inHours % 24;
  int get currentMinutes => currentDuration.inMinutes % 60;

  factory BadHabitSession.fromJson(Map<String, dynamic> json) {
    return BadHabitSession(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      userId: json['user_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String).toUtc(),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String).toUtc()
          : null,
      durationDays: json['duration_days'] as int?,
      isCurrent: json['is_current'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habit_id': habitId,
      'user_id': userId,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_days': durationDays,
      'is_current': isCurrent,
    };
  }
}

// Model untuk relapse
class Relapse {
  final String id;
  final String habitId;
  final String userId;
  final DateTime relapsedAt;
  final String? note;
  final int previousDurationDays;

  const Relapse({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.relapsedAt,
    this.note,
    required this.previousDurationDays,
  });

  factory Relapse.fromJson(Map<String, dynamic> json) {
    return Relapse(
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      userId: json['user_id'] as String,
      relapsedAt: DateTime.parse(json['relapsed_at'] as String),
      note: json['note'] as String?,
      previousDurationDays: json['previous_duration_days'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habit_id': habitId,
      'user_id': userId,
      'relapsed_at': relapsedAt.toIso8601String(),
      'note': note,
      'previous_duration_days': previousDurationDays,
    };
  }
}
