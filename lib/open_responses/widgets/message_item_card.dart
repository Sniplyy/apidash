import 'package:flutter/material.dart';
import '../open_responses_models.dart';
import 'status_badge.dart';

/// Renders a `MessageItem` (user or assistant) as a card with role badge,
/// status, and Markdown-capable text content.
class MessageItemCard extends StatelessWidget {
  const MessageItemCard({super.key, required this.item});

  final MessageItem item;

  bool get isUser => item.role == 'user';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Role-based theming
    final (borderColor, bgColor, roleLabel, roleBadgeColor) = isUser
        ? (
            Colors.blue.withValues(alpha: 0.4),
            colorScheme.primaryContainer.withValues(alpha: 0.25),
            'User',
            Colors.blue,
          )
        : (
            colorScheme.outline.withValues(alpha: 0.25),
            colorScheme.surfaceContainerLow,
            'Assistant',
            colorScheme.secondary,
          );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: roleBadgeColor.withValues(alpha: 0.15),
                  child: Text(
                    roleLabel[0],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: roleBadgeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  roleLabel,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isUser
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                StatusBadge(status: item.status),
              ],
            ),
            const SizedBox(height: 10),

            // Content parts
            ...item.content.map((part) {
              return switch (part.type) {
                'output_text' || 'input_text' || 'text' => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: _MarkdownText(text: part.displayText),
                  ),
                'refusal' => Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.block_rounded,
                            size: 14, color: Colors.red.shade400),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            part.displayText,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                _ => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      part.displayText,
                      style: textTheme.bodySmall,
                    ),
                  ),
              };
            }),
          ],
        ),
      ),
    );
  }
}

/// Simple selectable text renderer that handles code blocks in backticks.
class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.55,
          ),
    );
  }
}
