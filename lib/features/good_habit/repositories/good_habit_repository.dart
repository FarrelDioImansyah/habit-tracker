import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../../shared/models/habit_model.dart';
class GoodHabitRepository {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  GoodHabitRepository(this._client);

  // ── HABITS ──────────────────────────────────────────────

  // Ambil semua good habits milik user
  Future<List<HabitModel>> getGoodHabits() async {
    final userId = _client.auth.currentUser!.id;
    final res = await _client
        .from('habits')
        .select()
        .eq('user_id', userId)
        .eq('type', 'good')
        .order('created_at');
    return (res as List).map((e) => HabitModel.fromJson(e)).toList();
  }

  // Tambah good habit baru
  Future<HabitModel> addHabit({
    required String name,
    required String icon,
    required String color,
    required String frequency,
    int? targetValue,
    required String unit,
    String? groupId,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final data = {
      'id': id,
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'type': 'good',
      'frequency': frequency,
      'group_id': groupId,
      'is_paused': false,
      'created_at': now,
      'target_value': targetValue,
      'unit': unit,
    };

    final res = await _client.from('habits').insert(data).select().single();
    return HabitModel.fromJson(res);
  }
  Future<void> toggleHabit(String habitId) async {
    final userId = _client.auth.currentUser!.id;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final existing = await _client
        .from('habit_logs')
        .select()
        .eq('habit_id', habitId)
        .eq('user_id', userId)
        .gte('completed_at', startOfDay.toIso8601String());
        

    if (existing.isEmpty) {
      // ✅ belum done → insert
      await _client.from('habit_logs').insert({
        'habit_id': habitId,
        'user_id': userId,
        'completed_at': DateTime.now().toIso8601String(),
        'is_completed': true
      });
    } else {
      // 🔁 sudah done → hapus (toggle)
      await _client
          .from('habit_logs')
          .delete()
          .eq('habit_id', habitId)
          .eq('user_id', userId)
          .gte('completed_at', startOfDay.toIso8601String());
    }
  }
  // Update habit
  Future<void> updateHabit(String id, Map<String, dynamic> updates) async {
    await _client.from('habits').update(updates).eq('id', id);
  }

  // Hapus habit
  Future<void> deleteHabit(String id) async {
    await _client.from('habits').delete().eq('id', id);
  }

  // Pause / unpause habit
  Future<void> togglePause(String id, bool isPaused) async {
    await _client.from('habits').update({'is_paused': isPaused}).eq('id', id);
  }
  Future<void> updateGoodHabit({
    required String id,
    required String name,
    required String icon,
    required String color,
  }) async {
    await _client.from('habits').update({
      'name': name,
      'icon': icon,
      'color': color,
    }).eq('id', id);
  }

  Future<void> incrementProgress(String habitId, int target) async {
    try {
      final userId = _client.auth.currentUser!.id;

      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);

      final existing = await _client
          .from('habit_logs')
          .select()
          .eq('habit_id', habitId)
          .eq('user_id', userId)
          .gte('completed_at', start.toIso8601String())
          .limit(1)
          .maybeSingle();

      if (existing == null) {
        final isDone = 1 >= target;
        await _client.from('habit_logs').insert({
          'habit_id': habitId,
          'user_id': userId,
          'completed_at': DateTime.now().toIso8601String(),
          'progress': 1,
          'is_completed': isDone,
        });
        return;
      }

      final current = existing['progress'] ?? 0;

      if (current >= target) return;
      
      final newProgress = current + 1;

      print('CURRENT: $current | TARGET: $target');

      // 🔥 SATU UPDATE SAJA
      await _client
          .from('habit_logs')
          .update({
            'progress': newProgress,
            if (newProgress >= target) 'is_completed': true,
          })
          .eq('id', existing['id']);
    } catch (e) {
      print('ERROR incrementProgress: $e');
    }
  }
  // Check-in habit hari ini
  Future<HabitLog> checkIn(String habitId, {String? note}) async {
    final userId = _client.auth.currentUser!.id;
    final id = _uuid.v4();
    final now = DateTime.now();

    final data = {
      'id': id,
      'habit_id': habitId,
      'user_id': userId,
      'completed_at': now.toIso8601String(),
      'note': note,
      'is_completed': true
    };

    final res =
        await _client.from('habit_logs').insert(data).select().single();
    return HabitLog.fromJson(res);
  }

  // Undo check-in hari ini
  Future<void> undoCheckIn(String habitId) async {
    final userId = _client.auth.currentUser!.id;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay =
        DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

    await _client
        .from('habit_logs')
        .delete()
        .eq('habit_id', habitId)
        .eq('user_id', userId)
        .gte('completed_at', startOfDay)
        .lte('completed_at', endOfDay);
  }

  // Cek apakah sudah check-in hari ini
  Future<bool> isCheckedInToday(String habitId) async {
    final userId = _client.auth.currentUser!.id;
    final now = DateTime.now().toUtc();

      final startOfDay = DateTime.utc(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

    final res = await _client
        .from('habit_logs')
        .select('id')
        .eq('habit_id', habitId)
        .eq('user_id', userId)
        .gte('completed_at', startOfDay)
        .lte('completed_at', endOfDay);

    return (res as List).isNotEmpty;
  }

  // Ambil semua log dalam rentang tanggal (untuk kalender/statistik)
  Future<List<HabitLog>> getLogs(String habitId,
      {DateTime? from, DateTime? to}) async {
      final userId = _client.auth.currentUser!.id;    
      var query = _client
        .from('habit_logs')
        .select()
        .eq('habit_id', habitId)
        .eq('user_id', userId);

    if (from != null) {
      query = query.gte('completed_at', from.toIso8601String());
    }
    if (to != null) {
      query = query.lte('completed_at', to.toIso8601String());
    }

    final res = await query.order('completed_at', ascending: false);
    return (res as List).map((e) => HabitLog.fromJson(e)).toList();
  }

  // ── STREAK ──────────────────────────────────────────────

  // Hitung streak saat ini
  Future<int> getCurrentStreak(String habitId) async {
    final logs = await getLogs(habitId);
    if (logs.isEmpty) return 0;
    
    int streak = 0;
    DateTime checkDate = DateTime.now();

    // Normalisasi ke hari saja
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);
    
    for (int i = 0; i < 365; i++) {
      final dayToCheck = checkDate.subtract(Duration(days: i));
      final hasLog = logs.any((log) {
        final logDate = DateTime(
          log.completedAt.year,
          log.completedAt.month,
          log.completedAt.day,
        );
          return logDate == dayToCheck && log.isCompleted;
      });

      if (hasLog) {
        streak++;
      } else {
        // Toleransi 1 hari: jika hari ini belum check-in, cek kemarin dulu
        if (i == 0) continue;
        break;
      }
    }
    
    return streak;
  }

  // Hitung streak terpanjang
  Future<int> getLongestStreak(String habitId) async {
    final logs = await getLogs(habitId);
    if (logs.isEmpty) return 0;

    // Kumpulkan tanggal unik
    final dates = logs
        .map((l) =>
            DateTime(l.completedAt.year, l.completedAt.month, l.completedAt.day))
        .toSet()
        .toList()
      ..sort();

    int longest = 1;
    int current = 1;

    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }

    return longest;
  }
  //buat agar ga lag
  Future<int> getTodayProgress(String habitId) async {
  final userId = _client.auth.currentUser!.id;

  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);

  final data = await _client
      .from('habit_logs')
      .select('progress')
      .eq('habit_id', habitId)
      .eq('user_id', userId)
      .gte('completed_at', start.toIso8601String())
      .limit(1)
      .maybeSingle();

  return data?['progress'] ?? 0;
  }
  Future<int> getWeeklyStreak(String habitId, int target) async {
  final logs = await getLogs(habitId);
  if (logs.isEmpty) return 0;

  int streak = 0;
  DateTime now = DateTime.now();
  print('TOTAL LOGS: ${logs.length}');
for (var log in logs) {
  print('LOG: ${log.completedAt} | progress: ${log.progress}');
}
  // mulai dari minggu sekarang
  DateTime startOfWeek =
      now.subtract(Duration(days: now.weekday - 1)); // senin

  for (int i = 0; i < 52; i++) {
    final weekStart = startOfWeek.subtract(Duration(days: i * 7));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final count = logs.where((log) {
      final date = log.completedAt;
      return !date.isBefore(weekStart) && date.isBefore(weekEnd);
    }).fold<int>(0, (sum, log) {
      return sum + ((log.progress != null && log.progress! > 0)
    ? log.progress!
    : 1);
    });

    if (count >= target) {
      streak++;
    } else {
      if (i == 0) continue; // toleransi minggu ini
      break;
    }
  }

  return streak;
}
  Future<Map<String, dynamic>> getTodayHabitData() async {
  final userId = _client.auth.currentUser!.id;

  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day);

  final res = await _client
      .from('habit_logs')
      .select()
      .eq('user_id', userId)
      .gte('completed_at', start.toIso8601String());

  final Map<String, dynamic> result = {};

  for (final item in res) {
    final habitId = item['habit_id'];

    result[habitId] = {
      'progress': item['progress'] ?? 0,
      'completed': item['is_completed'] ?? false,
    };
  }

  return result;
}
}

// Provider
final goodHabitRepositoryProvider = Provider<GoodHabitRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return GoodHabitRepository(client);
});

// Provider list good habits
final goodHabitsProvider = FutureProvider<List<HabitModel>>((ref) {
  return ref.watch(goodHabitRepositoryProvider).getGoodHabits();
});


