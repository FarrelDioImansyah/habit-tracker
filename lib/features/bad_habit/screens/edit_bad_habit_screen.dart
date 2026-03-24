import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/habit_model.dart';
import '../repositories/bad_habit_repository.dart';

class EditBadHabitScreen extends ConsumerStatefulWidget {
  final HabitModel habit;

  const EditBadHabitScreen({super.key, required this.habit});

  @override
  ConsumerState<EditBadHabitScreen> createState() =>
      _EditBadHabitScreenState();
}

class _EditBadHabitScreenState
    extends ConsumerState<EditBadHabitScreen> {

  late TextEditingController _nameController;
  late TextEditingController _reasonController;

  late String _emoji;
  late Color _color; // ✅ FIX: pakai Color

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(text: widget.habit.name);

    _reasonController =
        TextEditingController(text: widget.habit.reason ?? '');

    _emoji = widget.habit.icon;
    _color = widget.habit.color; // ✅ tidak error
  }

  Future<void> _update() async {
    final repo = ref.read(badHabitRepositoryProvider);

    await repo.updateBadHabit(
      id: widget.habit.id,
      name: _nameController.text,
      icon: _emoji,

      // 🔥 convert Color → String untuk DB
      color: '#${_color.value.toRadixString(16).substring(2)}',

      reason: _reasonController.text,
    );

    ref.invalidate(badHabitsProvider);

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit berhasil diupdate')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Bad Habit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView( // ✅ biar tidak overflow
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration:
                    const InputDecoration(labelText: 'Nama Habit'),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _reasonController,
                decoration:
                    const InputDecoration(labelText: 'Alasan berhenti'),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _update,
                child: const Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}