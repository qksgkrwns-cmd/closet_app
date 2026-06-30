import 'package:flutter/material.dart';

const List<String> kSupportedColors = [
  '블랙',
  '화이트',
  '그레이',
  '네이비',
  '베이지',
  '카키',
  '브라운',
  '블루',
  '레드',
  '그린',
  '믹스',
  'Other',
];

String normalizeColorLabel(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'Other';

  final value = raw.toLowerCase().replaceAll(' ', '');

  if (value.contains('검정') || value.contains('블랙') || value.contains('black')) {
    return '블랙';
  }
  if (value.contains('흰') || value.contains('화이트') || value.contains('white')) {
    return '화이트';
  }
  if (value.contains('회색') || value.contains('그레이') || value.contains('gray') || value.contains('grey') || value.contains('silver')) {
    return '그레이';
  }
  if (value.contains('네이비') || value.contains('남색') || value.contains('navy')) {
    return '네이비';
  }
  if (value.contains('베이지') || value.contains('beige') || value.contains('아이보리') || value.contains('ivory') || value.contains('cream')) {
    return '베이지';
  }
  if (value.contains('카키') || value.contains('khaki') || value.contains('올리브') || value.contains('olive')) {
    return '카키';
  }
  if (value.contains('브라운') || value.contains('갈색') || value.contains('brown') || value.contains('tan') || value.contains('camel')) {
    return '브라운';
  }
  if (value.contains('블루') || value.contains('파랑') || value.contains('파란') || value.contains('blue') || value.contains('코발트')) {
    return '블루';
  }
  if (value.contains('레드') || value.contains('빨강') || value.contains('빨간') || value.contains('red') || value.contains('버건디') || value.contains('burgundy') || value.contains('와인')) {
    return '레드';
  }
  if (value.contains('그린') || value.contains('초록') || value.contains('green') || value.contains('민트') || value.contains('mint')) {
    return '그린';
  }
  if (value.contains('믹스') || value.contains('혼합') || value.contains('multi') || value.contains('multicolor') || value.contains('pattern') || value.contains('패턴') || value.contains('체크') || value.contains('스트라이프')) {
    return '믹스';
  }

  if (value.contains('other') ||
      value.contains('기타') ||
      value.contains('etc') ||
      value.contains('unknown') ||
      value == 'na' ||
      value == 'n/a') {
    return 'Other';
  }

  return 'Other';
}

class ColorSelector extends StatelessWidget {
  final String? selectedColor;
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
        const Text('색상', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: kSupportedColors
              .map((color) => ChoiceChip(
                    label: Text(color),
                    selected: selectedColor == color,
                    showCheckmark: true,
                    onSelected: (_) => onColorSelected(color),
                    side: BorderSide(
                      color: selectedColor == color
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      width: selectedColor == color ? 1.4 : 1,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}