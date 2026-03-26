import 'package:flutter/material.dart';
import '../open_responses_models.dart';
import 'status_badge.dart';

/// Collapsible card for a `reasoning` item — the model's chain-of-thought.
class ReasoningItemCard extends StatefulWidget {
  const ReasoningItemCard({super.key, required this.item});
  final ReasoningItem item;

  @override
  State<ReasoningItemCard> createState() => _ReasoningItemCardState();
}

class _ReasoningItemCardState extends State<ReasoningItemCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _rotateAnim = Tween(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasContent = widget.item.summaryText?.isNotEmpty ?? false;
    final isEncrypted =
        !hasContent && (widget.item.encryptedContent?.isNotEmpty ?? false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      color: Colors.amber.withValues(alpha: 0.05),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: hasContent ? _toggle : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    size: 16,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Thinking…',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.amber.shade800,
                    ),
                  ),
                  const Spacer(),
                  StatusBadge(status: widget.item.status),
                  const SizedBox(width: 8),
                  if (isEncrypted)
                    Icon(Icons.lock_rounded,
                        size: 14, color: Colors.amber.shade600)
                  else if (hasContent)
                    RotationTransition(
                      turns: _rotateAnim,
                      child: Icon(Icons.expand_more_rounded,
                          size: 18, color: Colors.amber.shade700),
                    ),
                ],
              ),
            ),
          ),

          // Collapsible summary content
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: (_expanded && hasContent)
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: Colors.amber.withValues(alpha: 0.3)),
                        const SizedBox(height: 6),
                        SelectableText(
                          widget.item.summaryText!,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.75),
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
