/// Models for the API Explorer feature.
library;

// ── Category ──────────────────────────────────────────────────────────────────

const kApiCategories = [
  'All',
  'AI',
  'Communication',
  'Data',
  'Developer',
  'E-Commerce',
  'Finance',
  'Health',
  'Maps',
  'Media',
  'News',
  'Social',
  'Weather',
  'Other',
];

// ── Auth Info ─────────────────────────────────────────────────────────────────

class ApiAuthInfo {
  const ApiAuthInfo({
    this.required = false,
    this.type = 'none',
    this.hint = '',
  });

  final bool required;
  final String type;
  final String hint;

  factory ApiAuthInfo.fromJson(Map<String, dynamic> json) {
    return ApiAuthInfo(
      required: json['required'] as bool? ?? false,
      type: json['type'] as String? ?? 'none',
      hint: json['hint'] as String? ?? '',
    );
  }
}

// ── Endpoint Template ─────────────────────────────────────────────────────────

class ApiEndpointTemplate {
  const ApiEndpointTemplate({
    required this.id,
    this.apiName = '',
    this.category = '',
    this.method = 'GET',
    this.baseUrl = '',
    this.path = '',
    this.summary = '',
    this.description = '',
    this.headers = const {},
    this.queryParams = const {},
    this.bodyTemplate,
    this.auth,
    this.tags = const [],
  });

  final String id;
  final String apiName;
  final String category;
  final String method;
  final String baseUrl;
  final String path;
  final String summary;
  final String description;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  final String? bodyTemplate;
  final ApiAuthInfo? auth;
  final List<String> tags;

  /// Full URL preview (base + path)
  String get fullUrl => '$baseUrl$path';

  /// Display name: summary if present, otherwise path
  String get displayName => summary.isNotEmpty ? summary : path;

  factory ApiEndpointTemplate.fromJson(Map<String, dynamic> json) {
    Map<String, String> parseStringMap(dynamic raw) {
      if (raw == null) return {};
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
      return {};
    }

    List<String> parseStringList(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return ApiEndpointTemplate(
      id: json['id'] as String? ?? '',
      apiName: json['api_name'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
      method: (json['method'] as String? ?? 'GET').toUpperCase(),
      baseUrl: json['base_url'] as String? ?? '',
      path: json['path'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      description: json['description'] as String? ?? '',
      headers: parseStringMap(json['headers']),
      queryParams: parseStringMap(json['query_params']),
      bodyTemplate: json['body_template'] as String?,
      auth: json['auth'] != null
          ? ApiAuthInfo.fromJson(json['auth'] as Map<String, dynamic>)
          : null,
      tags: parseStringList(json['tags']),
    );
  }
}

// ── Registry ──────────────────────────────────────────────────────────────────

class ApiRegistry {
  const ApiRegistry({
    this.version = '1.0.0',
    this.generatedAt = '',
    this.categories = const [],
    this.endpoints = const [],
  });

  final String version;
  final String generatedAt;
  final List<String> categories;
  final List<ApiEndpointTemplate> endpoints;

  factory ApiRegistry.fromJson(Map<String, dynamic> json) {
    final rawCategories = json['categories'] as List<dynamic>? ?? [];
    final rawEndpoints = json['endpoints'] as List<dynamic>? ?? [];
    return ApiRegistry(
      version: json['version'] as String? ?? '1.0.0',
      generatedAt: json['generated_at'] as String? ?? '',
      categories: rawCategories.map((e) => e.toString()).toList(),
      endpoints: rawEndpoints
          .map((e) =>
              ApiEndpointTemplate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
