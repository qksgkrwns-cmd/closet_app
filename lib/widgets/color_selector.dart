import 'package:flutter/material.dart';

class ColorSelector extends StatelessWidget {
  final String selectedColor;
  final Function(String) onColorSelected;

  const ColorSelector({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '색상',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: ['검정', '흰색', '네이비', '베이지', '카키', '회색']
              .map((color) {
                return ChoiceChip(
                  label: Text(color),
                  selected: selectedColor == color,
                  onSelected: (_) {
                    onColorSelected(color);
                  },
                );
              })
              .toList(),
        ),
      ],
    );
  }
}