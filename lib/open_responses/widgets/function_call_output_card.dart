import 'dart:convert';
import 'package:flutter/material.dart';
import '../open_responses_models.dart';
import 'status_badge.dart';

/// Card for a `function_call_output` item — shows tool result.
class FunctionCallOutputCard extends StatelessWidget {
  const FunctionCallOutputCard({super.key, required this.item});
  final FunctionCallOutputItem item;

  String get _prettyOutput {
    try {
      final decoded = jsonDecode(item.output);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return item.output;
    }
  }

  bool get _isJson {
    try {
      jsonDecode(item.output);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.teal.withValues(alpha: 0.4)),
      ),
      color: Colors.teal.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.output_rounded,
                    size: 14, color: Colors.teal.shade600),
                const SizedBox(width: 6),
                Text(
                  'Tool Result',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.teal.shade700,
                  ),
                ),
                const Spacer(),
                StatusBadge(status: item.status),
              ],
            ),

            if (item.callId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'call_id: ${item.callId}',
                  style: textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              )
            else
              const SizedBox(height: 10),

            // Output
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.teal.withValues(alpha: 0.2),
                ),
              ),
              child: SelectableText(
                _prettyOutput,
                style: textTheme.bodySmall?.copyWith(
                  fontFamily: _isJson ? 'monospace' : null,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
