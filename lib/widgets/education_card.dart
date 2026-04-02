import 'package:flutter/material.dart';
import '../models/education.dart';

class EducationCard extends StatelessWidget {
  final Education education;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EducationCard({
    super.key,
    required this.education,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    education.university,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              education.major,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '${education.startYear} - ${education.endYear}',
              style: const TextStyle(fontSize: 14),
            ),
            if (education.gpa != null) ...[
              const SizedBox(height: 4),
              Text(
                'IPK: ${education.gpa}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}