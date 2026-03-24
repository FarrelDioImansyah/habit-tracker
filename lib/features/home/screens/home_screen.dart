import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../features/good_habit/repositories/good_habit_repository.dart';
import '../../../features/bad_habit/repositories/bad_habit_repository.dart';
import '../../../shared/models/habit_model.dart';
import '../../../shared/widgets/app_icons.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header()),
            SliverToBoxAdapter(child: _GoodHabitSection()),
            SliverToBoxAdapter(child: _BadHabitSection()),
            const SliverToBoxAdapter(child: SizedBox(height: 60)),
          ],
        ),
      ),
    );
  }
}

// ── HEADER ───────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goodAsync = ref.watch(goodHabitsProvider);
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Selamat pagi'
        : now.hour < 17
            ? 'Selamat siang'
            : 'Selamat malam';
    final dateStr =
        DateFormat('EEEE, d MMMM yyyy').format(now);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
                Text('Ayo semangat! 💪',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(dateStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          // Progress ring
          goodAsync.when(
            data: (habits) => _ProgressRing(habits: habits),
            loading: () => const SizedBox(width: 56, height: 56),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends ConsumerWidget {
  final List<HabitModel> habits;
  const _ProgressRing({required this.habits});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (habits.isEmpty) return const SizedBox(width: 56, height: 56);
    // Hitung berapa yang sudah check-in hari ini
    // Untuk simplisitas kita tampilkan jumlah habit saja dulu
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: habits.isEmpty ? 0 : 0.0,
            strokeWidth: 5,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceVariant,
            color: const Color(0xFF1D9E75),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${habits.length}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'habit',
                style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── GOOD HABIT SECTION ───────────────────────────────────────

class _GoodHabitSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(goodHabitsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.check_circle_outline_rounded,
          label: 'Kebiasaan Baik',
          color: const Color(0xFF1D9E75),
        ),
        async.when(
          data: (habits) => habits.isEmpty
              ? _EmptyCard(
                  icon: Icons.add_circle_outline_rounded,
                  message: 'Tambah kebiasaan baik pertamamu',
                  color: const Color(0xFF1D9E75),
                  onTap: () => context.push(AppRoutes.addGoodHabit),
                )
              : Column(
                  children: habits
                      .map((h) => _GoodHabitCard(habit: h ))
                      .toList(),
                ),
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _ErrorCard(message: e.toString()),
        ),
      ],
    );
  }
}

class _GoodHabitCard extends ConsumerStatefulWidget {
  final HabitModel habit;
  const _GoodHabitCard({required this.habit});

  @override
  ConsumerState<_GoodHabitCard> createState() => _GoodHabitCardState();
}

class _GoodHabitCardState extends ConsumerState<_GoodHabitCard> {
  bool _checked = false;
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(goodHabitRepositoryProvider);
    final checked = await repo.isCheckedInToday(widget.habit.id);
    final streak = await repo.getCurrentStreak(widget.habit.id);
    if (mounted) setState(() {
      _checked = checked;
      _streak = streak;
      _loading = false;
    });
  }

  Future<void> _toggle() async {
    final repo = ref.read(goodHabitRepositoryProvider);
    setState(() => _loading = true);
    if (_checked) {
      await repo.undoCheckIn(widget.habit.id);
    } else {
      await repo.checkIn(widget.habit.id);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.habit.color;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: _checked ? color.withOpacity(0.08) : cs.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: () {
            context.push('/good-habit/${widget.habit.id}');
          },
          onLongPress: () {
              context.push(
              '/edit-good-habit',
              extra: widget.habit,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Icon
                EmojiBox(emoji: widget.habit.icon, color: color, size: 46),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habit.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          decoration: _checked
                              ? TextDecoration.lineThrough
                              : null,
                          color: _checked
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              size: 14, color: Colors.orange),
                          const SizedBox(width: 3),
                          Text(
                            '$_streak hari streak',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Check button
                GestureDetector(
                  onTap: _loading ? null : _toggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _checked ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: _checked ? Colors.white : color,
                      size: 22,
                    ),
                  ),
                ),              
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── BAD HABIT SECTION ────────────────────────────────────────

class _BadHabitSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(badHabitsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.block_rounded,
          label: 'Lepas Kebiasaan Buruk',
          color: const Color(0xFFD85A30),
        ),
        async.when(
          data: (habits) => habits.isEmpty
              ? _EmptyCard(
                  icon: Icons.add_circle_outline_rounded,
                  message: 'Pantau kebiasaan buruk yang ingin dihentikan',
                  color: const Color(0xFFD85A30),
                  onTap: () => context.push(AppRoutes.addBadHabit),
                )
              : Column(
                  children: habits
                      .map((h) => _BadHabitCard(habit: h))
                      .toList(),
                ),
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _ErrorCard(message: e.toString()),
        ),
      ],
    );
  }
}

class _BadHabitCard extends ConsumerStatefulWidget {
  final HabitModel habit;
  const _BadHabitCard({required this.habit});

  @override
  ConsumerState<_BadHabitCard> createState() => _BadHabitCardState();
}

class _BadHabitCardState extends ConsumerState<_BadHabitCard> {
  BadHabitSession? _session;
  int _best = 0;
  bool _loading = true;
  late Duration _live;

  @override
  void initState() {
    super.initState();
    _live = Duration.zero;
    _load();
    _tick();
  }

  Future<void> _load() async {
    final repo = ref.read(badHabitRepositoryProvider);
    final session = await repo.getCurrentSession(widget.habit.id);
    final best = await repo.getBestRecord(widget.habit.id);
    if (mounted) setState(() {
      _session = session;
      _live = session?.currentDuration ?? Duration.zero;
      _best = best;
      _loading = false;
    });
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _live = _session?.currentDuration ?? Duration.zero);
      _tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.habit.color;
    final cs = Theme.of(context).colorScheme;
    final days = _live.inDays;
    final hours = _live.inHours % 24;
    final minutes = _live.inMinutes % 60;

    String timerText = days > 0
        ? '$days hr ${hours}j ${minutes}m'
        : hours > 0
            ? '${hours}j ${minutes}m bersih'
            : '${minutes}m bersih';

    // Milestone berikutnya
    final nextMilestone = ref
        .read(badHabitRepositoryProvider)
        .getNextMilestone(days);
    double milestoneProgress = 0;
    if (nextMilestone != null) {
      final prev = _prevMilestone(nextMilestone);
      milestoneProgress = (days - prev) / (nextMilestone - prev);
      milestoneProgress = milestoneProgress.clamp(0.0, 1.0);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push('/bad-habit/${widget.habit.id}'),
          onLongPress: () {
              context.push(
              '/edit-bad-habit',
              extra: widget.habit,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    EmojiBox(emoji: widget.habit.icon, color: color, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.habit.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                          const SizedBox(height: 4),
                          _loading
                              ? const SizedBox(height: 14)
                              : Row(
                                  children: [
                                    Icon(Icons.timer_outlined,
                                        size: 13, color: color),
                                    const SizedBox(width: 3),
                                    Text(timerText,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: color,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                        ],
                      ),
                    ),
                    // Rekor
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Icon(Icons.emoji_events_outlined,
                            size: 16, color: Colors.amber),
                        Text(
                          'Rekor: $_best hr',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        color: cs.onSurfaceVariant),
                  ],
                ),
                // Progress bar menuju milestone
                if (nextMilestone != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: milestoneProgress,
                            minHeight: 6,
                            backgroundColor:
                                color.withOpacity(0.15),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Target: $nextMilestone hr',
                        style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _prevMilestone(int next) {
    const milestones = [0, 1, 3, 7, 14, 30, 90, 180, 365];
    final idx = milestones.indexOf(next);
    return idx > 0 ? milestones[idx - 1] : 0;
  }
}

// ── SHARED WIDGETS ───────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionTitle(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final VoidCallback onTap;
  const _EmptyCard(
      {required this.icon,
      required this.message,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DashedBorderCard(
        color: color,
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Text(message,
                style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class DashedBorderCard extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  final Widget child;
  const DashedBorderCard(
      {super.key,
      required this.color,
      required this.onTap,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: color.withOpacity(0.35),
              width: 1.5,
              style: BorderStyle.solid),
        ),
        child: child,
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text('Error: $message',
          style: const TextStyle(color: Colors.red)),
    );
  }
}
