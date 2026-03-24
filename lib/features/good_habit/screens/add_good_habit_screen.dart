import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_icons.dart';
import '../repositories/good_habit_repository.dart';

class AddGoodHabitScreen extends ConsumerStatefulWidget {
  const AddGoodHabitScreen({super.key});

  @override
  ConsumerState<AddGoodHabitScreen> createState() =>
      _AddGoodHabitScreenState();
}

class _AddGoodHabitScreenState extends ConsumerState<AddGoodHabitScreen> {
  final _nameCtrl = TextEditingController();
  String _emoji = '💪';
  Color _color = HabitPresetColors.good.first;
  String _frequency = 'daily';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama habit tidak boleh kosong')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(goodHabitRepositoryProvider).addHabit(
            name: _nameCtrl.text.trim(),
            icon: _emoji,
            color:
                '#${_color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
            frequency: _frequency,
          );
      ref.invalidate(goodHabitsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF1D9E75);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Kebiasaan Baik'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Simpan',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview
            Center(
              child: GestureDetector(
                onTap: () => _showEmojiPicker(context),
                child: Stack(
                  children: [
                    EmojiBox(
                        emoji: _emoji,
                        color: _color,
                        size: 80,
                        radius: 24),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit,
                            size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text('Tap untuk ubah ikon',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const SizedBox(height: 24),

            // Nama
            _Label('Nama Habit'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Contoh: Olahraga 30 menit',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // Frekuensi
            _Label('Frekuensi'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FreqBtn(
                    label: 'Setiap Hari',
                    icon: Icons.today_rounded,
                    selected: _frequency == 'daily',
                    color: teal,
                    onTap: () => setState(() => _frequency = 'daily'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FreqBtn(
                    label: 'Mingguan',
                    icon: Icons.date_range_rounded,
                    selected: _frequency == 'weekly',
                    color: teal,
                    onTap: () => setState(() => _frequency = 'weekly'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Warna
            _Label('Warna'),
            const SizedBox(height: 10),
            ColorPickerRow(
              colors: HabitPresetColors.good,
              selected: _color,
              onPick: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: 32),

            // Tombol simpan
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Simpan Habit',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
  expand: false,
  initialChildSize: 0.6,
  builder: (context, scrollController) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        controller: scrollController,
        children: [
          const Text(
            'Pilih Ikon',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          EmojiPickerGrid(
            items: HabitEmoji.goodList,
            selected: _emoji,
            onPick: (e) {
              setState(() => _emoji = e);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  },
),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14));
}

class _FreqBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FreqBtn(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : Colors.grey.withOpacity(0.4),
              width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : Colors.grey),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: selected ? color : Colors.grey,
                    fontWeight: selected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
