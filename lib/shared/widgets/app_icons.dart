import 'package:flutter/material.dart';

/// Semua icon habit menggunakan emoji Unicode
/// Tidak butuh file asset apapun
class HabitEmoji {
  HabitEmoji._();

  static const List<Map<String, dynamic>> goodList = [
    {'emoji': '💪', 'label': 'Olahraga'},
    {'emoji': '📚', 'label': 'Belajar'},
    {'emoji': '🧘', 'label': 'Meditasi'},
    {'emoji': '🏃', 'label': 'Lari'},
    {'emoji': '💧', 'label': 'Minum air'},
    {'emoji': '🥗', 'label': 'Makan sehat'},
    {'emoji': '😴', 'label': 'Tidur cukup'},
    {'emoji': '✍️', 'label': 'Jurnal'},
    {'emoji': '🎵', 'label': 'Musik'},
    {'emoji': '🌿', 'label': 'Berkebun'},
    {'emoji': '🧹', 'label': 'Bersih-bersih'},
    {'emoji': '🙏', 'label': 'Ibadah'},
    {'emoji': '💊', 'label': 'Vitamin'},
    {'emoji': '🚴', 'label': 'Bersepeda'},
    {'emoji': '🎨', 'label': 'Kreativitas'},
    {'emoji': '🌅', 'label': 'Bangun pagi'},
    {'emoji': '🦷', 'label': 'Sikat gigi'},
    {'emoji': '📝', 'label': 'Mencatat'},
    {'emoji': '🏊', 'label': 'Berenang'},
    {'emoji': '🫁', 'label': 'Napas dalam'},
  ];

  static const List<Map<String, dynamic>> badList = [
    {'emoji': '🚬', 'label': 'Merokok'},
    {'emoji': '🍺', 'label': 'Alkohol'},
    {'emoji': '🍔', 'label': 'Junk food'},
    {'emoji': '🎮', 'label': 'Game berlebihan'},
    {'emoji': '📱', 'label': 'Medsos berlebihan'},
    {'emoji': '☕', 'label': 'Kafein berlebihan'},
    {'emoji': '🍫', 'label': 'Gula berlebihan'},
    {'emoji': '🛋️', 'label': 'Malas gerak'},
    {'emoji': '🌙', 'label': 'Begadang'},
    {'emoji': '💸', 'label': 'Boros'},
    {'emoji': '🧁', 'label': 'Camilan tidak sehat'},
    {'emoji': '😬', 'label': 'Gigit kuku'},
    {'emoji': '🛍️', 'label': 'Belanja impulsif'},
    {'emoji': '📺', 'label': 'Nonton berlebihan'},
    {'emoji': '🥤', 'label': 'Minuman manis'},
    {'emoji': '😰', 'label': 'Overthinking'},
    {'emoji': '🍕', 'label': 'Makan larut malam'},
    {'emoji': '😤', 'label': 'Mudah marah'},
    {'emoji': '🎰', 'label': 'Judi'},
    {'emoji': '🍟', 'label': 'Fast food'},
  ];
}

/// Warna preset untuk habit
class HabitPresetColors {
  HabitPresetColors._();

  static const List<Color> good = [
    Color(0xFF1D9E75),
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFF00BCD4),
    Color(0xFF8BC34A),
    Color(0xFF3F51B5),
    Color(0xFF673AB7),
    Color(0xFF009688),
  ];

  static const List<Color> bad = [
    Color(0xFFD85A30),
    Color(0xFFE53935),
    Color(0xFFFF5722),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFF9C27B0),
  ];
}

/// Kotak emoji untuk menampilkan icon habit
class EmojiBox extends StatelessWidget {
  final String emoji;
  final double size;
  final Color color;
  final double radius;

  const EmojiBox({
    super.key,
    required this.emoji,
    required this.color,
    this.size = 48,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: TextStyle(fontSize: size * 0.52),
      ),
    );
  }
}

/// Grid picker emoji
class EmojiPickerGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String? selected;
  final ValueChanged<String> onPick;

  const EmojiPickerGrid({
    super.key,
    required this.items,
    this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final isSelected = item['emoji'] == selected;
        return GestureDetector(
          onTap: () => onPick(item['emoji'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? primary.withOpacity(0.15)
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: primary, width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item['emoji'] as String,
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 2),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 9,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Row picker warna
class ColorPickerRow extends StatelessWidget {
  final List<Color> colors;
  final Color? selected;
  final ValueChanged<Color> onPick;

  const ColorPickerRow({
    super.key,
    required this.colors,
    this.selected,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colors.map((c) {
        final isSelected = c.value == selected?.value;
        return GestureDetector(
          onTap: () => onPick(c),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3)
                  : Border.all(color: Colors.transparent, width: 3),
              boxShadow: isSelected
                  ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
