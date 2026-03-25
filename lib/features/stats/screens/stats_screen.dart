import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/good_habit/repositories/good_habit_repository.dart';
import '../../../features/bad_habit/repositories/bad_habit_repository.dart';
import '../../../shared/models/habit_model.dart';
import '../../../shared/widgets/app_icons.dart';

// FIX BUG 2: Provider.family untuk stats per habit
// Data di-fetch sekali lalu di-cache, tidak refetch tiap rebuild
final goodHabitStatsProvider = FutureProvider.family<
    Map<String, int>, String>((ref, habitId) async {
  final repo = ref.watch(goodHabitRepositoryProvider);
  final streak = await repo.getCurrentStreak(habitId);
  final longest = await repo.getLongestStreak(habitId);
  final logs = await repo.getLogs(habitId);
  return {
    'streak': streak,
    'longest': longest,
    'total': logs.length,
  };
});

final badHabitStatsProvider = FutureProvider.family<
    Map<String, int>, String>((ref, habitId) async {
  final repo = ref.watch(badHabitRepositoryProvider);
  final session = await repo.getCurrentSession(habitId);
  final best = await repo.getBestRecord(habitId);
  final total = await repo.getTotalRelapses(habitId);
  return {
    'current': session?.currentDays ?? 0,
    'best': best,
    'relapses': total,
  };
});

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Statistik'),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            tabs: const [
              Tab(
                icon: Icon(Icons.check_circle_outline_rounded),
                text: 'Kebiasaan Baik',
              ),
              Tab(
                icon: Icon(Icons.block_rounded),
                text: 'Kebiasaan Buruk',
              ),
            ],
            indicatorColor: const Color(0xFF1D9E75),
            labelColor: const Color(0xFF1D9E75),
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        body: const TabBarView(
          children: [
            _GoodHabitStats(),
            _BadHabitStats(),
          ],
        ),
      ),
    );
  }
}

// ── GOOD HABIT STATS ─────────────────────────────────────────

class _GoodHabitStats extends ConsumerWidget {
  const _GoodHabitStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(goodHabitsProvider);

    return habitsAsync.when(
      data: (habits) {
        if (habits.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Belum ada data statistik',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: habits.length,
          itemBuilder: (_, i) => _GoodHabitStatCard(habit: habits[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _GoodHabitStatCard extends ConsumerWidget {
  final HabitModel habit;
  const _GoodHabitStatCard({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = habit.color;
    // FIX BUG 2: watch provider.family → data langsung ada saat tersedia
    // tidak perlu setState, tidak ada delay tampil 0 dulu
    final statsAsync = ref.watch(goodHabitStatsProvider(habit.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EmojiBox(emoji: habit.icon, color: color, size: 40),
                const SizedBox(width: 10),
                Text(habit.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 14),
            statsAsync.when(
              // FIX: tampilkan data langsung saat sudah siap
              data: (stats) => Row(
                children: [
                  Expanded(
                      child: _MiniStat(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: Colors.orange,
                    label: 'Streak',
                    value: '${stats['streak']} hari',
                  )),
                  Expanded(
                      child: _MiniStat(
                    icon: Icons.emoji_events_rounded,
                    iconColor: Colors.amber,
                    label: 'Terpanjang',
                    value: '${stats['longest']} hari',
                  )),
                  Expanded(
                      child: _MiniStat(
                    icon: Icons.check_rounded,
                    iconColor: color,
                    label: 'Total',
                    value: '${stats['total']} kali',
                  )),
                ],
              ),
              // FIX BUG 2: saat loading tampilkan skeleton, BUKAN angka 0
              loading: () => const _StatsSkeleton(),
              error: (e, _) =>
                  Text('Error: $e', style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── BAD HABIT STATS ──────────────────────────────────────────

class _BadHabitStats extends ConsumerWidget {
  const _BadHabitStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(badHabitsProvider);

    return habitsAsync.when(
      data: (habits) {
        if (habits.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Belum ada data statistik',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: habits.length,
          itemBuilder: (_, i) => _BadHabitStatCard(habit: habits[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _BadHabitStatCard extends ConsumerWidget {
  final HabitModel habit;
  const _BadHabitStatCard({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = habit.color;
    // FIX BUG 2: sama seperti good habit, pakai provider.family
    final statsAsync = ref.watch(badHabitStatsProvider(habit.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EmojiBox(emoji: habit.icon, color: color, size: 40),
                const SizedBox(width: 10),
                Text(habit.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 14),
            statsAsync.when(
              data: (stats) {
                final currentDays = stats['current']!;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _MiniStat(
                          icon: Icons.timer_outlined,
                          iconColor: color,
                          label: 'Sekarang',
                          value: '$currentDays hari',
                        )),
                        Expanded(
                            child: _MiniStat(
                          icon: Icons.emoji_events_rounded,
                          iconColor: Colors.amber,
                          label: 'Rekor',
                          value: '${stats['best']} hari',
                        )),
                        Expanded(
                            child: _MiniStat(
                          icon: Icons.refresh_rounded,
                          iconColor: Colors.red,
                          label: 'Relapse',
                          value: '${stats['relapses']} kali',
                        )),
                      ],
                    ),
                    if (currentDays > 0) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        children: _getBadges(currentDays, color),
                      ),
                    ],
                  ],
                );
              },
              // FIX BUG 2: skeleton bukan 0
              loading: () => const _StatsSkeleton(),
              error: (e, _) =>
                  Text('Error: $e', style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getBadges(int days, Color color) {
    const map = {
      1: '🌱',
      3: '✨',
      7: '⭐',
      14: '🌟',
      30: '🏅',
      90: '🥈',
      180: '🥇',
      365: '🏆'
    };
    return map.entries
        .where((e) => days >= e.key)
        .map((e) => Chip(
              label: Text('${e.value} ${e.key}hr',
                  style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600)),
              backgroundColor: color.withValues(alpha: 0.1),
              side: BorderSide(color: color.withValues(alpha: 0.3)),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ))
        .toList();
  }
}

// ── SKELETON LOADING ─────────────────────────────────────────
// FIX BUG 2: tampil saat data belum siap, bukan angka 0

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    final base =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    return Row(
      children: List.generate(
        3,
        (_) => Expanded(
          child: Column(
            children: [
              Container(
                  width: 20, height: 20, decoration: BoxDecoration(color: base, shape: BoxShape.circle)),
              const SizedBox(height: 6),
              Container(
                  width: 44,
                  height: 14,
                  decoration: BoxDecoration(
                      color: base, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 4),
              Container(
                  width: 32,
                  height: 10,
                  decoration: BoxDecoration(
                      color: base, borderRadius: BorderRadius.circular(4))),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SHARED ───────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _MiniStat(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15)),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color:
                    Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
