import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/habit_model.dart';
import '../repositories/good_habit_repository.dart';


class EditGoodHabitScreen extends ConsumerStatefulWidget {
  final HabitModel habit;

  const EditGoodHabitScreen({super.key, required this.habit});

  @override
  ConsumerState<EditGoodHabitScreen> createState() =>
      _EditGoodHabitScreenState();
}

class _EditGoodHabitScreenState
    extends ConsumerState<EditGoodHabitScreen> {
  late TextEditingController _nameController;
  late String _emoji;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.habit.name);
    _emoji = widget.habit.icon;
    _color = widget.habit.color;
  }

  Future<void> _update() async {
    final repo = ref.read(goodHabitRepositoryProvider);

    await repo.updateGoodHabit(
      id: widget.habit.id,
      name: _nameController.text,
      icon: _emoji,
      color:  '#${_color.value.toRadixString(16).substring(2)}',
    );

    ref.invalidate(goodHabitsProvider);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Habit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration:
                  const InputDecoration(labelText: 'Nama Habit'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _update,
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}