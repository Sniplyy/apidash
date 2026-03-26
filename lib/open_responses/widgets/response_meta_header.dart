import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../open_responses_models.dart';

/// Compact information strip at the top of the visualizer showing model,
/// token usage, and response status.
class ResponseMetaHeader extends StatelessWidget {
  const ResponseMetaHeader({super.key, required this.response});

  final OpenResponsesResponse response;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Model name
          if (response.model != null) ...[
            Icon(Icons.smart_toy_outlined, size: 14, color: colorScheme.primary),
            const SizedBox(width: 5),
            Text(
              response.model!,
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Token chips
          if (response.inputTokens != null || response.outputTokens != null) ...[
            _TokenChip(
              icon: Icons.input_rounded,
              label: '${response.inputTokens ?? 0} in',
              color: colorScheme.tertiary,
            ),
            const SizedBox(width: 4),
            _TokenChip(
              icon: Icons.output_rounded,
              label: '${response.outputTokens ?? 0} out',
              color: colorScheme.secondary,
            ),
            const SizedBox(width: 4),
          ],

          const Spacer(),

          // Response ID — copyable
          if (response.responseId != null)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: response.responseId!));
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ID: ${response.responseId!.length > 16 ? '${response.responseId!.substring(0, 14)}…' : response.responseId!}',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.copy_rounded,
                      size: 11,
                      color: colorScheme.onSurface.withValues(alpha: 0.4)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _TokenChip extends StatelessWidget {
  const _TokenChip(
      {required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
