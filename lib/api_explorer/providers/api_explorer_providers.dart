import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/api_explorer_models.dart';

/// Loads and holds the entire API registry from the bundled asset.
final apiRegistryProvider = FutureProvider<ApiRegistry>((ref) async {
  final raw = await rootBundle.loadString('assets/api_registry.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return ApiRegistry.fromJson(json);
});

/// Search query string typed by the user in the Explorer search bar.
final apiExplorerSearchQueryProvider = StateProvider<String>((ref) => '');

/// Currently selected category chip (default = 'All').
final apiExplorerSelectedCategoryProvider =
    StateProvider<String>((ref) => 'All');

/// Currently selected endpoint for the detail pane.
final apiExplorerSelectedEndpointProvider =
    StateProvider<ApiEndpointTemplate?>((ref) => null);

/// Derived list of endpoints filtered by category + search query.
final filteredApiEndpointsProvider =
    Provider<AsyncValue<List<ApiEndpointTemplate>>>((ref) {
  final registryAsync = ref.watch(apiRegistryProvider);
  final query = ref.watch(apiExplorerSearchQueryProvider).toLowerCase().trim();
  final category = ref.watch(apiExplorerSelectedCategoryProvider);

  return registryAsync.whenData((registry) {
    var endpoints = registry.endpoints;

    // Category filter
    if (category != 'All') {
      endpoints = endpoints.where((e) => e.category == category).toList();
    }

    // Text search
    if (query.isNotEmpty) {
      endpoints = endpoints.where((e) {
        return e.apiName.toLowerCase().contains(query) ||
            e.summary.toLowerCase().contains(query) ||
            e.description.toLowerCase().contains(query) ||
            e.path.toLowerCase().contains(query) ||
            e.tags.any((t) => t.toLowerCase().contains(query));
      }).toList();
    }

    return endpoints;
  });
});
