import 'package:flutter/material.dart';

class BodyTypeSelector extends StatelessWidget {
  final String selectedBodyType;
  final List<String> bodyTypes;
  final Function(String) onBodyTypeSelected;

  const BodyTypeSelector({
    super.key,
    required this.selectedBodyType,
    required this.bodyTypes,
    required this.onBodyTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: bodyTypes.map((type) => ChoiceChip(
        label: Text(type),
        selected: selectedBodyType == type,
        onSelected: (_) => onBodyTypeSelected(type),
      )).toList(),
    );
  }
}