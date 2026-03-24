import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/good_habit/repositories/good_habit_repository.dart';
import '../../../features/bad_habit/repositories/bad_habit_repository.dart';
import '../../../shared/models/habit_model.dart';
import '../../../shared/widgets/app_icons.dart';

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
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _GoodHabitStatCard extends ConsumerStatefulWidget {
  final HabitModel habit;
  const _GoodHabitStatCard({required this.habit});

  @override
  ConsumerState<_GoodHabitStatCard> createState() =>
      _GoodHabitStatCardState();
}

class _GoodHabitStatCardState extends ConsumerState<_GoodHabitStatCard> {
  int _streak = 0;
  int _longest = 0;
  int _totalLogs = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(goodHabitRepositoryProvider);
    final streak = await repo.getCurrentStreak(widget.habit.id);
    final longest = await repo.getLongestStreak(widget.habit.id);
    final logs = await repo.getLogs(widget.habit.id);
    if (mounted) setState(() {
      _streak = streak;
      _longest = longest;
      _totalLogs = logs.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.habit.color;
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EmojiBox(emoji: widget.habit.icon, color: color, size: 40),
                const SizedBox(width: 10),
                Text(widget.habit.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _MiniStat(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: Colors.orange,
                  label: 'Streak',
                  value: '$_streak hari',
                )),
                Expanded(
                    child: _MiniStat(
                  icon: Icons.emoji_events_rounded,
                  iconColor: Colors.amber,
                  label: 'Terpanjang',
                  value: '$_longest hari',
                )),
                Expanded(
                    child: _MiniStat(
                  icon: Icons.check_rounded,
                  iconColor: color,
                  label: 'Total',
                  value: '$_totalLogs kali',
                )),
              ],
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
      loading: () =>
          const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _BadHabitStatCard extends ConsumerStatefulWidget {
  final HabitModel habit;
  const _BadHabitStatCard({required this.habit});

  @override
  ConsumerState<_BadHabitStatCard> createState() =>
      _BadHabitStatCardState();
}

class _BadHabitStatCardState extends ConsumerState<_BadHabitStatCard> {
  int _currentDays = 0;
  int _best = 0;
  int _totalRelapses = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(badHabitRepositoryProvider);
    final session = await repo.getCurrentSession(widget.habit.id);
    final best = await repo.getBestRecord(widget.habit.id);
    final total = await repo.getTotalRelapses(widget.habit.id);
    if (mounted) setState(() {
      _currentDays = session?.currentDays ?? 0;
      _best = best;
      _totalRelapses = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.habit.color;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                EmojiBox(emoji: widget.habit.icon, color: color, size: 40),
                const SizedBox(width: 10),
                Text(widget.habit.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _MiniStat(
                  icon: Icons.timer_outlined,
                  iconColor: color,
                  label: 'Sekarang',
                  value: '$_currentDays hari',
                )),
                Expanded(
                    child: _MiniStat(
                  icon: Icons.emoji_events_rounded,
                  iconColor: Colors.amber,
                  label: 'Rekor',
                  value: '$_best hari',
                )),
                Expanded(
                    child: _MiniStat(
                  icon: Icons.refresh_rounded,
                  iconColor: Colors.red,
                  label: 'Relapse',
                  value: '$_totalRelapses kali',
                )),
              ],
            ),
            // Milestone badges
            if (_currentDays > 0) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                children: _getBadges(_currentDays, color),
              ),
            ],
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
              backgroundColor: color.withOpacity(0.1),
              side: BorderSide(color: color.withOpacity(0.3)),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ))
        .toList();
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
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
