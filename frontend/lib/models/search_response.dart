import 'provider.dart';
import 'agent_trace.dart';

class SearchResponse {
  final String requestId;
  final List<Provider> providers;
  final int totalFound;
  final String top3Reasoning;
  final List<AgentTrace> agentTrace;

  SearchResponse({
    required this.requestId,
    required this.providers,
    required this.totalFound,
    required this.top3Reasoning,
    required this.agentTrace,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      requestId: json['request_id'] as String? ?? '',
      providers: (json['providers'] as List<dynamic>?)
              ?.map((e) => Provider.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalFound: json['total_found'] as int? ?? 0,
      top3Reasoning: json['top_3_reasoning'] as String? ?? '',
      agentTrace: (json['agent_trace'] as List<dynamic>?)
              ?.map((e) => AgentTrace.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
