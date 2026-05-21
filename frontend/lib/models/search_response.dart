import 'provider.dart';
import 'agent_trace.dart';

class SearchResponse {
  final String requestId;
  final List<Provider> providers;
  final int totalFound;
  final String top3Reasoning;
  final String aiHeaderText;
  final List<AgentTrace> agentTrace;
  final double? searchOriginLat;
  final double? searchOriginLng;

  SearchResponse({
    required this.requestId,
    required this.providers,
    required this.totalFound,
    required this.top3Reasoning,
    required this.aiHeaderText,
    required this.agentTrace,
    this.searchOriginLat,
    this.searchOriginLng,
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
      aiHeaderText: json['ai_header_text'] as String? ?? '',
      agentTrace: (json['agent_trace'] as List<dynamic>?)
              ?.map((e) => AgentTrace.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      searchOriginLat: (json['search_origin_lat'] as num?)?.toDouble(),
      searchOriginLng: (json['search_origin_lng'] as num?)?.toDouble(),
    );
  }
}
