import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/supabase/supabase_provider.dart';
import '../../../shared/models/habit_model.dart';
class BadHabitRepository {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  BadHabitRepository(this._client);

  // ── HABITS ──────────────────────────────────────────────

  Future<List<HabitModel>> getBadHabits() async {
    final userId = _client.auth.currentUser!.id;
    final res = await _client
        .from('habits')
        .select()
        .eq('user_id', userId)
        .eq('type', 'bad')
        .order('created_at');
    return (res as List).map((e) => HabitModel.fromJson(e)).toList();
  }

  Future<HabitModel> addBadHabit({
    required String name,
    required String icon,
    required String color,
    String? reason,
    String? groupId,
    DateTime? startedAt,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    // Buat habit
    final habitData = {
      'id': id,
      'user_id': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'type': 'bad',
      'reason': reason,
      'group_id': groupId,
      'is_paused': false,
      'created_at': now,
    };

    final res =
        await _client.from('habits').insert(habitData).select().single();

    // Langsung buat sesi pertama
    await _startNewSession(id, userId, startedAt: startedAt);

    return HabitModel.fromJson(res);
  }

  // ── SESSIONS & TIMER ────────────────────────────────────

  // Ambil sesi yang sedang berjalan
  Future<BadHabitSession?> getCurrentSession(String habitId) async {
    final res = await _client
        .from('bad_habit_sessions')
        .select()
        .eq('habit_id', habitId)
        .eq('is_current', true)
        .maybeSingle();

    if (res == null) return null;
    return BadHabitSession.fromJson(res);
  }

  // Ambil semua sesi (riwayat)
  Future<List<BadHabitSession>> getAllSessions(String habitId) async {
    final res = await _client
        .from('bad_habit_sessions')
        .select()
        .eq('habit_id', habitId)
        .order('started_at', ascending: false);

    return (res as List).map((e) => BadHabitSession.fromJson(e)).toList();
  }

  // ── RELAPSE ─────────────────────────────────────────────

  // Catat relapse — reset timer
  Future<void> recordRelapse(
    String habitId, {
    String? note,
  }) async {
    final userId = _client.auth.currentUser!.id;
    final now = DateTime.now();

    // 1. Ambil sesi yang sedang berjalan
    final currentSession = await getCurrentSession(habitId);
    if (currentSession == null) return;

    final durationDays = now.difference(currentSession.startedAt).inDays;

    // 2. Tutup sesi lama
    await _client.from('bad_habit_sessions').update({
      'ended_at': now.toIso8601String(),
      'duration_days': durationDays,
      'is_current': false,
    }).eq('id', currentSession.id);

    // 3. Simpan relapse (histori tidak dihapus!)
    await _client.from('relapses').insert({
      'id': _uuid.v4(),
      'habit_id': habitId,
      'user_id': userId,
      'relapsed_at': now.toIso8601String(),
      'note': note,
      'previous_duration_days': durationDays,
    });

    // 4. Mulai sesi baru dari 0
    await _startNewSession(habitId, userId);
  }
  Future<void> updateBadHabit({
  required String id,
  required String name,
  required String icon,
  required String color,
  String? reason,
    }) async {
  await _client.from('habits').update({
    'name': name,
    'icon': icon,
    'color': color,
    'reason': reason,
  }).eq('id', id);
  }

  // Mulai sesi baru
  Future<void> _startNewSession(
    String habitId,
    String userId, {
    DateTime? startedAt,
  }) async {
    await _client.from('bad_habit_sessions').insert({
      'id': _uuid.v4(),
      'habit_id': habitId,
      'user_id': userId,
      'started_at': (startedAt ?? DateTime.now()).toIso8601String(),
      'is_current': true,
    });
  }
  //delate bad habbit 
  Future<void> deleteHabit(String id) async {
  await _client.from('habits').delete().eq('id', id);
}

  // Ambil riwayat relapse
  Future<List<Relapse>> getRelapseHistory(String habitId) async {
    final res = await _client
        .from('relapses')
        .select()
        .eq('habit_id', habitId)
        .order('relapsed_at', ascending: false);

    return (res as List).map((e) => Relapse.fromJson(e)).toList();
  }

  // ── STATISTIK ───────────────────────────────────────────

  // Rekor terlama (best streak)
  Future<int> getBestRecord(String habitId) async {
    final sessions = await getAllSessions(habitId);
    if (sessions.isEmpty) return 0;

    final finished = sessions
        .where((s) => !s.isCurrent && s.durationDays != null)
        .map((s) => s.durationDays!)
        .toList();

    // Bandingkan dengan sesi saat ini juga
    final current = await getCurrentSession(habitId);
    if (current != null) finished.add(current.currentDays);

    if (finished.isEmpty) return 0;
    return finished.reduce((a, b) => a > b ? a : b);
  }

  // Total relapse count
  Future<int> getTotalRelapses(String habitId) async {
    final res = await _client
        .from('relapses')
        .select('id')
        .eq('habit_id', habitId);

    return (res as List).length;
  }

  // Milestone list yang sudah dicapai
  List<int> getAchievedMilestones(int currentDays) {
    const milestones = [1, 3, 7, 14, 30, 90, 180, 365];
    return milestones.where((m) => currentDays >= m).toList();
  }

  // Milestone berikutnya
  int? getNextMilestone(int currentDays) {
    const milestones = [1, 3, 7, 14, 30, 90, 180, 365];
    try {
      return milestones.firstWhere((m) => m > currentDays);
    } catch (_) {
      return null; // sudah melewati semua milestone
    }
  }
}

// Providers
final badHabitRepositoryProvider = Provider<BadHabitRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return BadHabitRepository(client);
});

final badHabitsProvider = FutureProvider<List<HabitModel>>((ref) {
  return ref.watch(badHabitRepositoryProvider).getBadHabits();
});
