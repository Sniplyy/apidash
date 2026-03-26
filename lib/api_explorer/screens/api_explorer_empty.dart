import 'package:flutter/material.dart';

/// Empty state shown when no endpoint is selected.
class ApiExplorerEmpty extends StatelessWidget {
  const ApiExplorerEmpty({super.key, this.isSearchResult = false});

  final bool isSearchResult;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearchResult ? Icons.search_off_rounded : Icons.explore_outlined,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isSearchResult
                  ? 'No endpoints found'
                  : 'Explore Public APIs',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearchResult
                  ? 'Try a different search term or category.'
                  : 'Select an API endpoint from the list to view\ndetails and import it into your workspace.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state for the sidebar when the registry is loading or failed.
class ApiExplorerLoadingError extends StatelessWidget {
  const ApiExplorerLoadingError({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error.withOpacity(0.7)),
            const SizedBox(height: 12),
            Text(
              'Failed to load API registry',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
