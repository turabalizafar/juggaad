class HistoryBookingItem {
  final String bookingId;
  final String requestId;
  final String providerId;
  final String providerName;
  final String providerPhone;
  final String serviceType;
  final String status;
  final String timeSlot;
  final String createdAt;

  HistoryBookingItem({
    required this.bookingId,
    required this.requestId,
    required this.providerId,
    required this.providerName,
    required this.providerPhone,
    required this.serviceType,
    required this.status,
    required this.timeSlot,
    required this.createdAt,
  });

  factory HistoryBookingItem.fromJson(Map<String, dynamic> json) {
    return HistoryBookingItem(
      bookingId: json['booking_id'] as String? ?? '',
      requestId: json['request_id'] as String? ?? '',
      providerId: json['provider_id'] as String? ?? '',
      providerName: json['provider_name'] as String? ?? 'Unknown',
      providerPhone: json['provider_phone'] as String? ?? '',
      serviceType: json['service_type'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'unknown',
      timeSlot: json['time_slot'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
