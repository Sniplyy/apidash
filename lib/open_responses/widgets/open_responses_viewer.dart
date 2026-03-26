import 'package:flutter/material.dart';
import '../open_responses_detector.dart';
import '../open_responses_models.dart';
import 'response_meta_header.dart';
import 'message_item_card.dart';
import 'reasoning_item_card.dart';
import 'function_call_card.dart';
import 'function_call_output_card.dart';
import 'genui_export_button.dart';

/// Top-level widget for visualizing an Open Responses-compliant LLM response.
///
/// Pass the raw JSON [body] string. The widget parses it, shows a metadata
/// header (model, tokens), and renders each item as a card.
class OpenResponsesViewer extends StatelessWidget {
  const OpenResponsesViewer({super.key, required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final response = parseOpenResponsesBody(body);
    if (response == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Could not parse Open Responses schema.'),
        ),
      );
    }
    return _ResponseView(response: response, rawBody: body);
  }
}

class _ResponseView extends StatelessWidget {
  const _ResponseView({required this.response, required this.rawBody});

  final OpenResponsesResponse response;
  final String rawBody;

  Widget _buildItem(OpenResponsesItem item) {
    return switch (item) {
      MessageItem msg => MessageItemCard(item: msg),
      ReasoningItem r => ReasoningItemCard(item: r),
      FunctionCallItem fc => FunctionCallCard(item: fc),
      FunctionCallOutputItem fco => FunctionCallOutputCard(item: fco),
      UnknownItem u => _UnknownItemCard(item: u),
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Spec badge ─────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.tertiaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        size: 12, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Open Responses',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GenUIExportButton(jsonBody: rawBody),
            ],
          ),
          const SizedBox(height: 10),

          // ── Meta header ────────────────────────────────────────────────
          ResponseMetaHeader(response: response),
          const SizedBox(height: 14),

          // ── Item count ─────────────────────────────────────────────────
          if (response.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${response.items.length} item${response.items.length != 1 ? 's' : ''}',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                  letterSpacing: 0.3,
                ),
              ),
            ),

          // ── Items ──────────────────────────────────────────────────────
          if (response.items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded,
                        size: 48,
                        color: colorScheme.onSurface.withValues(alpha: 0.2)),
                    const SizedBox(height: 8),
                    Text(
                      'No output items in this response.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...response.items.map(_buildItem),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Fallback for unknown item types ─────────────────────────────────────────

class _UnknownItemCard extends StatelessWidget {
  const _UnknownItemCard({required this.item});
  final UnknownItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.help_outline_rounded,
                size: 16, color: colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(width: 8),
            Text(
              'Unknown item type: ${item.type}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
