import 'parsed_intent.dart';
import 'agent_trace.dart';

class ParseResponse {
  final String requestId;
  final String status;
  final ParsedIntent intent;
  final List<String> missingFields;
  final String aiMessage;
  final List<AgentTrace> agentTrace;

  ParseResponse({
    required this.requestId,
    required this.status,
    required this.intent,
    required this.missingFields,
    required this.aiMessage,
    required this.agentTrace,
  });

  factory ParseResponse.fromJson(Map<String, dynamic> json) {
    return ParseResponse(
      requestId: json['request_id'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      intent: ParsedIntent.fromJson(json['intent'] as Map<String, dynamic>? ?? {}),
      missingFields: (json['missing_fields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      aiMessage: json['ai_message'] as String? ?? '',
      agentTrace: (json['agent_trace'] as List<dynamic>?)
              ?.map((e) => AgentTrace.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
