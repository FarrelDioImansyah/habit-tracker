import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/habit_model.dart';
import '../../../shared/widgets/app_icons.dart';
import '../repositories/good_habit_repository.dart';
// FIX BUG 3: import provider.family dari home_screen
import '../../home/screens/home_screen.dart';

class GoodHabitDetailScreen extends ConsumerStatefulWidget {
  final String habitId;
  const GoodHabitDetailScreen({super.key, required this.habitId});

  @override
  ConsumerState<GoodHabitDetailScreen> createState() =>
      _GoodHabitDetailScreenState();
}

class _GoodHabitDetailScreenState
    extends ConsumerState<GoodHabitDetailScreen> {
  HabitModel? _habit;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(goodHabitRepositoryProvider);
    final habits = await repo.getGoodHabits();
    final habit = habits.where((h) => h.id == widget.habitId).isNotEmpty
        ? habits.firstWhere((h) => h.id == widget.habitId)
        : null;
    if (mounted) setState(() { _habit = habit; _loading = false; });
  }

  Future<void> _toggleDone() async {
    final repo = ref.read(goodHabitRepositoryProvider);
    await repo.toggleHabit(_habit!.id);
    // FIX BUG 3: invalidate semua provider terkait habit ini
    // Dengan ini saat kembali ke home, status centang langsung update
    ref.invalidate(goodHabitsProvider);
    ref.invalidate(checkedTodayProvider(_habit!.id));
    ref.invalidate(currentStreakProvider(_habit!));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_habit == null) {
      return const Scaffold(body: Center(child: Text('Habit tidak ditemukan')));
    }

    final habit = _habit!;
    final color = habit.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (selected) async {
              final repo = ref.read(goodHabitRepositoryProvider);
              if (selected == 'edit') {
                context.push('/edit-good-habit', extra: habit);
              } else if (selected == 'delete') {
                await repo.deleteHabit(habit.id);
                ref.invalidate(goodHabitsProvider);
                ref.invalidate(checkedTodayProvider(habit.id));
                ref.invalidate(currentStreakProvider(habit));
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Habit dihapus')),
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                  value: 'delete',
                  child: Text('Hapus', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                EmojiBox(emoji: habit.icon, color: color, size: 64, radius: 20),
                const SizedBox(height: 10),
                Text(habit.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Consumer(builder: (context, ref, _) {
                  final checked =
                      ref.watch(checkedTodayProvider(habit.id)).value ?? false;
                  return Text(
                    checked ? '✅ Sudah selesai hari ini' : '⏳ Belum selesai hari ini',
                    style: TextStyle(
                      fontSize: 13,
                      color: checked
                          ? const Color(0xFF1D9E75)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              await _toggleDone();
              if (context.mounted) context.pop();
            },
            icon: const Icon(Icons.check),
            label: const Text('Tandai selesai hari ini'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Kebiasaan baik ini membantu kamu berkembang. '
              'Lakukan secara konsisten setiap hari 🚀',
            ),
          ),
        ],
      ),
    );
  }
}
