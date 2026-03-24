import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/habit_model.dart';
import '../../../shared/widgets/app_icons.dart';
import '../repositories/bad_habit_repository.dart';

class BadHabitDetailScreen extends ConsumerStatefulWidget {
  final String habitId;
  const BadHabitDetailScreen({super.key, required this.habitId});

  @override
  ConsumerState<BadHabitDetailScreen> createState() =>
      _BadHabitDetailScreenState();
}

class _BadHabitDetailScreenState extends ConsumerState<BadHabitDetailScreen> {
  HabitModel? _habit;
  BadHabitSession? _session;
  List<Relapse> _history = [];
  int _best = 0;
  int _totalRelapses = 0;
  bool _loading = true;
  Duration _live = Duration.zero;

  @override
  void initState() {
    super.initState();
    _load();
    _tick();
  }

  Future<void> _load() async {
    final repo = ref.read(badHabitRepositoryProvider);
    final habits = await repo.getBadHabits();
    final habit = habits.where((h) => h.id == widget.habitId).isNotEmpty
    ? habits.firstWhere((h) => h.id == widget.habitId)
    : null;
    final session = await repo.getCurrentSession(widget.habitId);
    final best = await repo.getBestRecord(widget.habitId);
    final total = await repo.getTotalRelapses(widget.habitId);
    final history = await repo.getRelapseHistory(widget.habitId);
    if (mounted) {
      setState(() {
        _habit = habit;
        _session = session;
        _live = session?.currentDuration ?? Duration.zero;
        _best = best;
        _totalRelapses = total;
        _history = history;
        _loading = false;
      });
    }
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _live = _session?.currentDuration ?? Duration.zero);
      _tick();
    });
  }

  Future<void> _doRelapse(String? note) async {
    final repo = ref.read(badHabitRepositoryProvider);
    await repo.recordRelapse(widget.habitId, note: note);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timer direset. Kamu pasti bisa lebih baik! 💪'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showRelapseDialog() {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('😔', style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text('Catat Relapse?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Timer ${_live.inDays} hari akan direset ke 0.\n'
              'Tapi histori progresmu tetap tersimpan!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'Apa yang terjadi? (opsional)',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final note = noteController.text.trim();
              await _doRelapse(note.isEmpty ? null : note);
            },
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade600),
            child: const Text('Reset Timer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
      if (_loading) {
        return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
        );
      }

      if (_habit == null) {
        return const Scaffold(
          body: Center(child: Text('Habit tidak ditemukan')),
        );
      }

    final habit = _habit!;
    final color = habit.color;
    final cs = Theme.of(context).colorScheme;
    final repo = ref.read(badHabitRepositoryProvider);
    final nextMilestone = repo.getNextMilestone(_live.inDays);
    final achieved = repo.getAchievedMilestones(_live.inDays);

    return Scaffold(
       appBar: AppBar(
        actions: [
        PopupMenuButton<String>(
        onSelected: (selected) async {
          if (selected == 'edit') {
            context.push(
              '/edit-bad-habit',
              extra: habit,
            );
          } else if (selected == 'pause') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Habit dipause')),
            );
          } else if (selected == 'delete') {
            await repo.deleteHabit(habit.id);

            ref.invalidate(badHabitsProvider);

            if (!mounted) return;

            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Habit dihapus')),
            );
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'pause', child: Text('Pause')),
          PopupMenuItem(
            value: 'delete',
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ],
  ),
      body: SafeArea(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // ── EMOJI + ALASAN ──
            EmojiBox(emoji: habit.icon, color: color, size: 72, radius: 22),
            if (habit.reason != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.format_quote_rounded,
                        color: color, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        habit.reason!,
                        style: TextStyle(
                            color: color,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // ── TIMER BESAR ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: color.withOpacity(0.25), width: 1.5),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined, color: color, size: 18),
                      const SizedBox(width: 6),
                      Text('Waktu Bersih',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Unit-unit timer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_live.inDays > 0) ...[
                        _TimerBox(
                            value: _live.inDays,
                            label: 'HARI',
                            color: color),
                        _TimerSep(color: color),
                      ],
                      _TimerBox(
                          value: _live.inHours % 24,
                          label: 'JAM',
                          color: color),
                      _TimerSep(color: color),
                      _TimerBox(
                          value: _live.inMinutes % 60,
                          label: 'MENIT',
                          color: color),
                      _TimerSep(color: color),
                      _TimerBox(
                          value: _live.inSeconds % 60,
                          label: 'DETIK',
                          color: color),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_session != null)
                    Text(
                      'Sejak ${DateFormat('d MMM yyyy • HH:mm').format(_session!.startedAt)}',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── MILESTONE PROGRESS ──
            if (nextMilestone != null)
              _MilestoneProgress(
                currentDays: _live.inDays,
                nextMilestone: nextMilestone,
                color: color,
              ),
            const SizedBox(height: 16),

            // ── BADGE ACHIEVED ──
            if (achieved.isNotEmpty)
              _AchievedBadges(milestones: achieved, color: color),
            const SizedBox(height: 16),

            // ── STAT CARDS ──
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.emoji_events_rounded,
                    iconColor: Colors.amber,
                    label: 'Rekor Terbaik',
                    value: '$_best hari',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.refresh_rounded,
                    iconColor: Colors.purple,
                    label: 'Total Relapse',
                    value: '$_totalRelapses kali',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── TOMBOL RELAPSE ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showRelapseDialog,
                icon: const Icon(Icons.refresh_rounded,
                    color: Color(0xFFE53935)),
                label: const Text('Saya Relapse...',
                    style: TextStyle(
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(
                      color: Color(0xFFE53935), width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── RIWAYAT RELAPSE ──
            if (_history.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.history_rounded,
                      size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text('Riwayat Relapse',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                ],
              ),
              const SizedBox(height: 10),
              ..._history.map((r) => _RelapseHistoryTile(
                    relapse: r,
                    color: color,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ── CHILD WIDGETS ─────────────────────────────────────────────

class _TimerBox extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _TimerBox(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                color: color.withOpacity(0.7),
                letterSpacing: 0.5)),
      ],
    );
  }
}

class _TimerSep extends StatelessWidget {
  final Color color;
  const _TimerSep({required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
      child: Text(':',
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color.withOpacity(0.4))),
    );
  }
}

class _MilestoneProgress extends StatelessWidget {
  final int currentDays;
  final int nextMilestone;
  final Color color;

  const _MilestoneProgress({
    required this.currentDays,
    required this.nextMilestone,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    const milestones = [0, 1, 3, 7, 14, 30, 90, 180, 365];
    final idx = milestones.indexOf(nextMilestone);
    final prev = idx > 0 ? milestones[idx - 1] : 0;
    final progress =
        ((currentDays - prev) / (nextMilestone - prev)).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text('Menuju $nextMilestone hari',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              Text(
                '$currentDays / $nextMilestone hari',
                style: TextStyle(
                    fontSize: 12,
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${((1 - progress) * (nextMilestone - prev)).round()} hari lagi!',
            style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _AchievedBadges extends StatelessWidget {
  final List<int> milestones;
  final Color color;
  const _AchievedBadges(
      {required this.milestones, required this.color});

  @override
  Widget build(BuildContext context) {
    const labels = {
      1: '1 Hari',
      3: '3 Hari',
      7: '1 Minggu',
      14: '2 Minggu',
      30: '1 Bulan',
      90: '3 Bulan',
      180: '6 Bulan',
      365: '1 Tahun',
    };
    const icons = {
      1: '🌱',
      3: '✨',
      7: '⭐',
      14: '🌟',
      30: '🏅',
      90: '🥈',
      180: '🥇',
      365: '🏆',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('🏅', style: TextStyle(fontSize: 16)),
            SizedBox(width: 6),
            Text('Pencapaian',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: milestones.map((m) {
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(icons[m] ?? '🏅',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(labels[m] ?? '$m hr',
                      style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _RelapseHistoryTile extends StatelessWidget {
  final Relapse relapse;
  final Color color;
  const _RelapseHistoryTile(
      {required this.relapse, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('d MMM yyyy • HH:mm')
                        .format(relapse.relapsedAt),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  if (relapse.note != null)
                    Text(relapse.note!,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${relapse.previousDurationDays}hr',
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
