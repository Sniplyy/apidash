import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_explorer_models.dart';
import '../providers/api_explorer_providers.dart';
import 'api_explorer_empty.dart';

/// Left sidebar: category filter chips + search bar + endpoint list.
class ApiExplorerSidebar extends ConsumerWidget {
  const ApiExplorerSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registryAsync = ref.watch(apiRegistryProvider);
    final selectedCategory = ref.watch(apiExplorerSelectedCategoryProvider);
    final searchQuery = ref.watch(apiExplorerSearchQueryProvider);
    final filteredAsync = ref.watch(filteredApiEndpointsProvider);
    final selectedEndpoint = ref.watch(apiExplorerSelectedEndpointProvider);

    return registryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ApiExplorerLoadingError(error: e),
      data: (registry) {
        final categories = ['All', ...registry.categories];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Icon(Icons.explore,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'API Explorer',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${registry.endpoints.length} endpoints',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.5),
                        ),
                  ),
                ],
              ),
            ),

            // ── Search bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search APIs…',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            ref
                                .read(apiExplorerSearchQueryProvider.notifier)
                                .state = '';
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.5),
                    ),
                  ),
                ),
                onChanged: (val) {
                  ref.read(apiExplorerSearchQueryProvider.notifier).state = val;
                },
              ),
            ),

            // ── Category chips ──────────────────────────────────────────
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 4),
                itemBuilder: (ctx, i) {
                  final cat = categories[i];
                  final isSelected = cat == selectedCategory;
                  return FilterChip(
                    label: Text(cat),
                    labelStyle: Theme.of(context).textTheme.labelSmall,
                    selected: isSelected,
                    onSelected: (_) {
                      ref
                          .read(apiExplorerSelectedCategoryProvider.notifier)
                          .state = cat;
                    },
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // ── Endpoint list ───────────────────────────────────────────
            Expanded(
              child: filteredAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => ApiExplorerLoadingError(error: e),
                data: (endpoints) {
                  if (endpoints.isEmpty) {
                    return const ApiExplorerEmpty(isSearchResult: true);
                  }
                  return ListView.builder(
                    itemCount: endpoints.length,
                    itemBuilder: (ctx, idx) {
                      final ep = endpoints[idx];
                      final isSelected = ep.id == selectedEndpoint?.id;
                      return _EndpointTile(
                        endpoint: ep,
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(
                                  apiExplorerSelectedEndpointProvider.notifier)
                              .state = ep;
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Endpoint List Tile ────────────────────────────────────────────────────────

class _EndpointTile extends StatelessWidget {
  const _EndpointTile({
    required this.endpoint,
    required this.isSelected,
    required this.onTap,
  });

  final ApiEndpointTemplate endpoint;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withOpacity(0.6)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            _MethodBadge(method: endpoint.method),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    endpoint.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                  ),
                  Text(
                    endpoint.apiName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Method Badge ──────────────────────────────────────────────────────────────

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method});

  final String method;

  Color _color(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: _color(context).withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color(context).withOpacity(0.4)),
      ),
      child: Text(
        method,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: _color(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
