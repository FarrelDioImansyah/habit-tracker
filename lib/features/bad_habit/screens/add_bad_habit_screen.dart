import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/app_icons.dart';
import '../repositories/bad_habit_repository.dart';

class AddBadHabitScreen extends ConsumerStatefulWidget {
  const AddBadHabitScreen({super.key});

  @override
  ConsumerState<AddBadHabitScreen> createState() =>
      _AddBadHabitScreenState();
}

class _AddBadHabitScreenState extends ConsumerState<AddBadHabitScreen> {
  final _nameCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  String _emoji = '🚬';
  Color _color = HabitPresetColors.bad.first;
  DateTime _startedAt = DateTime.now().toUtc();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _reasonCtrl.dispose();
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
      await ref.read(badHabitRepositoryProvider).addBadHabit(
            name: _nameCtrl.text.trim(),
            icon: _emoji,
            color:
                '#${_color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
            reason: _reasonCtrl.text.trim().isEmpty
                ? null
                : _reasonCtrl.text.trim(),
            startedAt: _startedAt,
          );
      ref.invalidate(badHabitsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _saving = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startedAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    const coral = Color(0xFFD85A30);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lepas Kebiasaan Buruk'),
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
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: coral.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: coral.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFFD85A30), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Timer mulai dihitung sejak tanggal yang kamu pilih. Jika kamu relapse, timer akan direset tapi riwayatmu tetap tersimpan.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preview emoji
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
                          color: cs.primary,
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
            _Label('Nama Kebiasaan Buruk'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Contoh: Merokok, Scroll TikTok berlebihan',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // Alasan berhenti
            _Label('Alasan Berhenti (opsional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(
                hintText:
                    'Contoh: Demi kesehatan dan keluargaku',
                prefixIcon: Icon(Icons.favorite_outline_rounded),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Tanggal mulai berhenti
            _Label('Mulai Berhenti Sejak'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: coral, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(_startedAt),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Icon(Icons.edit_calendar_outlined,
                        color: cs.onSurfaceVariant, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Warna
            _Label('Warna'),
            const SizedBox(height: 10),
            ColorPickerRow(
              colors: HabitPresetColors.bad,
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
                label: const Text('Mulai Pantau',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: coral,
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
            items: HabitEmoji.badList,
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
