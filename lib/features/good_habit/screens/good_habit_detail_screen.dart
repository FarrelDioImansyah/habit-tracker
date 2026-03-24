import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/habit_model.dart';
import '../repositories/good_habit_repository.dart';

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

    if (mounted) {
      setState(() {
        _habit = habit;
        _loading = false;
      });
    }
  }

  Future<void> _toggleDone() async {
    final repo = ref.read(goodHabitRepositoryProvider);

    await repo.toggleHabit(_habit!.id);

    ref.invalidate(goodHabitsProvider);

    if (mounted) setState(() {});
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

    return Scaffold(
      appBar: AppBar(
        title: Text(habit.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (selected) async {
              final repo = ref.read(goodHabitRepositoryProvider);

              if (selected == 'edit') {
                context.push(
                  '/edit-good-habit',
                  extra: habit,
                );
              } else if (selected == 'delete') {
                await repo.deleteHabit(habit.id);

                ref.invalidate(goodHabitsProvider);

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
                child: Text('Hapus',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  habit.icon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 10),
                Text(
                  habit.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // CHECK BUTTON
          ElevatedButton.icon(
            onPressed: () async {
              await _toggleDone();

              if (context.mounted) {
                context.pop(); // 🔥 balik ke home
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Tandai selesai hari ini'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          const SizedBox(height: 20),

          // INFO
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