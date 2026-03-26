import 'dart:convert';
import 'package:flutter/material.dart';
import '../open_responses_models.dart';
import 'status_badge.dart';

/// Card for a `function_call` item — shows tool name and JSON arguments.
class FunctionCallCard extends StatefulWidget {
  const FunctionCallCard({super.key, required this.item});
  final FunctionCallItem item;

  @override
  State<FunctionCallCard> createState() => _FunctionCallCardState();
}

class _FunctionCallCardState extends State<FunctionCallCard> {
  bool _argsExpanded = false;

  String get _prettyArgs {
    try {
      final decoded = jsonDecode(widget.item.arguments);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return widget.item.arguments;
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
        side: BorderSide(color: Colors.purple.withValues(alpha: 0.4)),
      ),
      color: Colors.purple.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.build_rounded, size: 14, color: Colors.purple.shade600),
                const SizedBox(width: 6),
                Text(
                  'Tool Call',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.purple.shade700,
                  ),
                ),
                const Spacer(),
                StatusBadge(status: widget.item.status),
              ],
            ),
            const SizedBox(height: 10),

            // Function name chip
            Chip(
              avatar: Icon(Icons.functions_rounded,
                  size: 14, color: Colors.purple.shade600),
              label: SelectableText(
                widget.item.name,
                style: textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: Colors.purple.shade800,
                ),
              ),
              backgroundColor: Colors.purple.withValues(alpha: 0.1),
              side: BorderSide(color: Colors.purple.withValues(alpha: 0.3)),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),

            // Call ID
            if (widget.item.callId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'call_id: ${widget.item.callId}',
                  style: textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Arguments toggle
            InkWell(
              onTap: () => setState(() => _argsExpanded = !_argsExpanded),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Arguments',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _argsExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 16,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _argsExpanded
                  ? Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.2),
                        ),
                      ),
                      child: SelectableText(
                        _prettyArgs,
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
