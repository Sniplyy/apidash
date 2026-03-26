import 'package:flutter/material.dart';
import '../open_responses_models.dart';

/// Small badge chip showing an item's status.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final OpenResponsesStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      OpenResponsesStatus.completed => ('completed', Colors.green),
      OpenResponsesStatus.inProgress => ('in_progress', Colors.blue),
      OpenResponsesStatus.incomplete => ('incomplete', Colors.orange),
      OpenResponsesStatus.unknown => ('unknown', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color.shade700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
