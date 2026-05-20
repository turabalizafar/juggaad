import 'agent_trace.dart';

class BookResponse {
  final String bookingId;
  final String trackingId;
  final String status;
  final String providerName;
  final String providerPhone;
  final int etaMinutes;
  final String confirmationText;
  final bool simulated;
  final List<AgentTrace> agentTrace;

  BookResponse({
    required this.bookingId,
    required this.trackingId,
    required this.status,
    required this.providerName,
    required this.providerPhone,
    required this.etaMinutes,
    required this.confirmationText,
    required this.simulated,
    required this.agentTrace,
  });

  factory BookResponse.fromJson(Map<String, dynamic> json) {
    return BookResponse(
      bookingId: json['booking_id'] as String? ?? '',
      trackingId: json['tracking_id'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      providerName: json['provider_name'] as String? ?? '',
      providerPhone: json['provider_phone'] as String? ?? '',
      etaMinutes: json['eta_minutes'] as int? ?? 0,
      confirmationText: json['confirmation_text'] as String? ?? '',
      simulated: json['simulated'] as bool? ?? true,
      agentTrace: (json['agent_trace'] as List<dynamic>?)
              ?.map((e) => AgentTrace.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
