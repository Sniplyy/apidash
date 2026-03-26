/// Models for the Open Responses specification.
/// https://www.openresponses.org/specification
library;

// ── Status ────────────────────────────────────────────────────────────────────

enum OpenResponsesStatus { inProgress, completed, incomplete, unknown }

OpenResponsesStatus parseStatus(String? s) => switch (s) {
      'in_progress' => OpenResponsesStatus.inProgress,
      'completed' => OpenResponsesStatus.completed,
      'incomplete' => OpenResponsesStatus.incomplete,
      _ => OpenResponsesStatus.unknown,
    };

// ── Content Part ──────────────────────────────────────────────────────────────

class ContentPart {
  const ContentPart({required this.type, this.text, this.imageUrl});
  final String type; // output_text, input_text, image_url, refusal…
  final String? text;
  final String? imageUrl;

  factory ContentPart.fromJson(Map<String, dynamic> json) {
    return ContentPart(
      type: json['type'] as String? ?? 'output_text',
      text: json['text'] as String?,
      imageUrl: json['image_url'] as String?,
    );
  }

  String get displayText =>
      text ?? imageUrl ?? '[unsupported content type: $type]';
}

// ── Base Item ─────────────────────────────────────────────────────────────────

sealed class OpenResponsesItem {
  OpenResponsesItem({
    required this.id,
    required this.type,
    required this.status,
    this.raw = const {},
  });
  final String id;
  final String type;
  final OpenResponsesStatus status;
  final Map<String, dynamic> raw;
}

// ── Message Item ──────────────────────────────────────────────────────────────

class MessageItem extends OpenResponsesItem {
  MessageItem({
    required super.id,
    required super.status,
    required super.raw,
    this.role = 'assistant',
    this.content = const [],
  }) : super(type: 'message');

  final String role;
  final List<ContentPart> content;

  String get fullText => content.map((c) => c.displayText).join('\n');

  factory MessageItem.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'] as List<dynamic>? ?? [];
    return MessageItem(
      id: json['id'] as String? ?? '',
      status: parseStatus(json['status'] as String?),
      role: json['role'] as String? ?? 'assistant',
      content: rawContent
          .whereType<Map<String, dynamic>>()
          .map(ContentPart.fromJson)
          .toList(),
      raw: json,
    );
  }
}

// ── Reasoning Item ────────────────────────────────────────────────────────────

class ReasoningItem extends OpenResponsesItem {
  ReasoningItem({
    required super.id,
    required super.status,
    required super.raw,
    this.summaryText,
    this.encryptedContent,
  }) : super(type: 'reasoning');

  final String? summaryText;
  final String? encryptedContent;

  factory ReasoningItem.fromJson(Map<String, dynamic> json) {
    // OpenAI format: summary[].text
    final summaryList = json['summary'] as List<dynamic>?;
    String? summaryText;
    if (summaryList != null && summaryList.isNotEmpty) {
      final first = summaryList.first;
      if (first is Map) summaryText = first['text'] as String?;
    }
    return ReasoningItem(
      id: json['id'] as String? ?? '',
      status: parseStatus(json['status'] as String?),
      summaryText: summaryText,
      encryptedContent: json['encrypted_content'] as String?,
      raw: json,
    );
  }
}

// ── Function Call Item ────────────────────────────────────────────────────────

class FunctionCallItem extends OpenResponsesItem {
  FunctionCallItem({
    required super.id,
    required super.status,
    required super.raw,
    this.name = '',
    this.arguments = '',
    this.callId = '',
  }) : super(type: 'function_call');

  final String name;
  final String arguments;
  final String callId;

  factory FunctionCallItem.fromJson(Map<String, dynamic> json) {
    return FunctionCallItem(
      id: json['id'] as String? ?? '',
      status: parseStatus(json['status'] as String?),
      name: json['name'] as String? ?? '',
      arguments: json['arguments'] as String? ?? '{}',
      callId: json['call_id'] as String? ?? '',
      raw: json,
    );
  }
}

// ── Function Call Output Item ─────────────────────────────────────────────────

class FunctionCallOutputItem extends OpenResponsesItem {
  FunctionCallOutputItem({
    required super.id,
    required super.status,
    required super.raw,
    this.callId = '',
    this.output = '',
  }) : super(type: 'function_call_output');

  final String callId;
  final String output;

  factory FunctionCallOutputItem.fromJson(Map<String, dynamic> json) {
    return FunctionCallOutputItem(
      id: json['id'] as String? ?? '',
      status: parseStatus(json['status'] as String?),
      callId: json['call_id'] as String? ?? '',
      output: json['output'] as String? ?? '',
      raw: json,
    );
  }
}

// ── Unknown Item ─────────────────────────────────────────────────────────────

class UnknownItem extends OpenResponsesItem {
  UnknownItem({required super.id, required super.type, required super.raw})
      : super(status: OpenResponsesStatus.unknown);
}

// ── Top-Level Response ────────────────────────────────────────────────────────

class OpenResponsesResponse {
  const OpenResponsesResponse({
    required this.items,
    this.responseId,
    this.model,
    this.status,
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
  });

  final List<OpenResponsesItem> items;
  final String? responseId;
  final String? model;
  final OpenResponsesStatus? status;
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;

  OpenResponsesItem? _parseItem(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? '';
    return switch (type) {
      'message' => MessageItem.fromJson(json),
      'reasoning' => ReasoningItem.fromJson(json),
      'function_call' => FunctionCallItem.fromJson(json),
      'function_call_output' => FunctionCallOutputItem.fromJson(json),
      _ => UnknownItem(id: json['id'] as String? ?? '', type: type, raw: json),
    };
  }

  factory OpenResponsesResponse.fromJsonMap(Map<String, dynamic> json) {
    final rawItems = json['output'] as List<dynamic>? ?? [];
    final usage = json['usage'] as Map<String, dynamic>? ?? {};

    // Determine status
    OpenResponsesStatus? status;
    final statusStr = json['status'] as String?;
    if (statusStr != null) status = parseStatus(statusStr);

    final response = OpenResponsesResponse(
      responseId: json['id'] as String?,
      model: json['model'] as String?,
      status: status,
      inputTokens: usage['input_tokens'] as int?,
      outputTokens: usage['output_tokens'] as int?,
      totalTokens: usage['total_tokens'] as int?,
      items: const [],
    );

    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(response._parseItem)
        .whereType<OpenResponsesItem>()
        .toList();

    return OpenResponsesResponse(
      items: items,
      responseId: response.responseId,
      model: response.model,
      status: response.status,
      inputTokens: response.inputTokens,
      outputTokens: response.outputTokens,
      totalTokens: response.totalTokens,
    );
  }
}
