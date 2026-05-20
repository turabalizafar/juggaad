class HistoryRequestItem {
  final String requestId;
  final String serviceType;
  final String locationText;
  final String urgency;
  final String issueSummary;
  final String createdAt;
  final String status;

  HistoryRequestItem({
    required this.requestId,
    required this.serviceType,
    required this.locationText,
    required this.urgency,
    required this.issueSummary,
    required this.createdAt,
    required this.status,
  });

  factory HistoryRequestItem.fromJson(Map<String, dynamic> json) {
    return HistoryRequestItem(
      requestId: json['request_id'] as String? ?? '',
      serviceType: json['service_type'] as String? ?? 'unknown',
      locationText: json['location_text'] as String? ?? 'Not specified',
      urgency: json['urgency'] as String? ?? 'flexible',
      issueSummary: json['issue_summary'] as String? ?? 'Service request',
      createdAt: json['created_at'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
    );
  }
}
