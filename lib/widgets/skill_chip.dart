import 'package:flutter/material.dart';

class SkillChip extends StatelessWidget {
  final String label;
  final VoidCallback onDelete;

  const SkillChip({
    super.key,
    required this.label,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onDelete,
      backgroundColor: Colors.blue.shade50,
      labelStyle: const TextStyle(color: Colors.blue),
      deleteIconColor: Colors.blue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}