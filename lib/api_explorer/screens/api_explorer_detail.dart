import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apidash_core/apidash_core.dart';
import 'package:apidash/providers/providers.dart';
import '../models/api_explorer_models.dart';
import '../providers/api_explorer_providers.dart';
import 'api_explorer_empty.dart';

/// Detail pane: shows endpoint info and "Import to Workspace" button.
class ApiExplorerDetail extends ConsumerWidget {
  const ApiExplorerDetail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final endpoint = ref.watch(apiExplorerSelectedEndpointProvider);
    if (endpoint == null) {
      return const ApiExplorerEmpty();
    }
    return _EndpointDetailView(endpoint: endpoint);
  }
}

class _EndpointDetailView extends ConsumerWidget {
  const _EndpointDetailView({required this.endpoint});

  final ApiEndpointTemplate endpoint;

  void _importToWorkspace(BuildContext context, WidgetRef ref) {
    // Build HttpRequestModel from the endpoint template
    final method = HTTPVerb.values.firstWhere(
      (v) => v.name.toUpperCase() == endpoint.method,
      orElse: () => HTTPVerb.get,
    );

    // Build params list from queryParams map
    final params = endpoint.queryParams.entries
        .map((e) => NameValueModel(name: e.key, value: e.value))
        .toList();

    // Build headers list from headers map
    final headers = endpoint.headers.entries
        .map((e) => NameValueModel(name: e.key, value: e.value))
        .toList();

    final httpModel = HttpRequestModel(
      url: endpoint.fullUrl,
      method: method,
      params: params.isNotEmpty ? params : null,
      headers: headers.isNotEmpty ? headers : null,
      body: endpoint.bodyTemplate,
      bodyContentType:
          endpoint.bodyTemplate != null ? ContentType.json : ContentType.json,
    );

    ref
        .read(collectionStateNotifierProvider.notifier)
        .addRequestModel(httpModel, name: endpoint.displayName);

    // Switch to Requests tab
    ref.read(navRailIndexStateProvider.notifier).state = 0;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${endpoint.displayName}" imported to workspace!',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header card ────────────────────────────────────────────────
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _MethodChip(method: endpoint.method),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          endpoint.displayName,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Chip(
                        label: Text(endpoint.apiName),
                        labelStyle: textTheme.labelSmall,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor:
                            colorScheme.secondaryContainer.withOpacity(0.5),
                      ),
                      const SizedBox(width: 6),
                      Chip(
                        label: Text(endpoint.category),
                        labelStyle: textTheme.labelSmall,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor:
                            colorScheme.tertiaryContainer.withOpacity(0.5),
                      ),
                    ],
                  ),
                  if (endpoint.description.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      endpoint.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ── URL ──────────────────────────────────────────────────────
          _SectionHeader(label: 'Endpoint URL'),
          const SizedBox(height: 6),
          _CopyableCodeBox(code: endpoint.fullUrl),

          // ── Query Params ─────────────────────────────────────────────
          if (endpoint.queryParams.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(label: 'Query Parameters'),
            const SizedBox(height: 6),
            _KeyValueTable(data: endpoint.queryParams),
          ],

          // ── Headers ──────────────────────────────────────────────────
          if (endpoint.headers.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(label: 'Headers'),
            const SizedBox(height: 6),
            _KeyValueTable(data: endpoint.headers),
          ],

          // ── Auth hint ────────────────────────────────────────────────
          if (endpoint.auth?.required == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.tertiary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 16, color: colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      endpoint.auth?.hint ?? 'Authentication required',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Body Template ─────────────────────────────────────────────
          if (endpoint.bodyTemplate != null) ...[
            const SizedBox(height: 16),
            _SectionHeader(label: 'Body Template'),
            const SizedBox(height: 6),
            _CopyableCodeBox(code: endpoint.bodyTemplate!, isMultiline: true),
          ],

          const SizedBox(height: 24),

          // ── Import Button ─────────────────────────────────────────────
          FilledButton.icon(
            onPressed: () => _importToWorkspace(context, ref),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Import to Workspace'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              textStyle: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _MethodChip extends StatelessWidget {
  const _MethodChip({required this.method});

  final String method;

  Color _color(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (method) {
      'GET' => isDark ? Colors.green.shade300 : Colors.green.shade700,
      'POST' => isDark ? Colors.blue.shade300 : Colors.blue.shade700,
      'PUT' => isDark ? Colors.orange.shade300 : Colors.orange.shade700,
      'PATCH' => isDark ? Colors.amber.shade300 : Colors.amber.shade800,
      'DELETE' => isDark ? Colors.red.shade300 : Colors.red.shade700,
      _ => Theme.of(context).colorScheme.secondary,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color(context).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color(context).withOpacity(0.5)),
      ),
      child: Text(
        method,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _color(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
    );
  }
}

class _CopyableCodeBox extends StatelessWidget {
  const _CopyableCodeBox({required this.code, this.isMultiline = false});

  final String code;
  final bool isMultiline;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SelectableText(
              code,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 14),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            tooltip: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _KeyValueTable extends StatelessWidget {
  const _KeyValueTable({required this.data});

  final Map<String, String> data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Table(
      border: TableBorder.all(
        color: colorScheme.outline.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ),
          children: [
            _TableCell(text: 'Key', isHeader: true),
            _TableCell(text: 'Value', isHeader: true),
          ],
        ),
        ...data.entries.map(
          (e) => TableRow(
            children: [
              _TableCell(text: e.key, isMono: true),
              _TableCell(text: e.value, isMono: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.text,
    this.isHeader = false,
    this.isMono = false,
  });

  final String text;
  final bool isHeader;
  final bool isMono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: isHeader ? FontWeight.w700 : FontWeight.normal,
              fontFamily: isMono ? 'monospace' : null,
            ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
