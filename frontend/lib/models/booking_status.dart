class BookingStatusResponse {
  final String bookingId;
  final String trackingId;
  final String status;
  final String providerName;
  final String providerPhone;
  final int etaMinutes;
  final String lastUpdated;

  BookingStatusResponse({
    required this.bookingId,
    required this.trackingId,
    required this.status,
    required this.providerName,
    required this.providerPhone,
    required this.etaMinutes,
    required this.lastUpdated,
  });

  factory BookingStatusResponse.fromJson(Map<String, dynamic> json) {
    return BookingStatusResponse(
      bookingId: json['booking_id'] as String? ?? '',
      trackingId: json['tracking_id'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      providerName: json['provider_name'] as String? ?? '',
      providerPhone: json['provider_phone'] as String? ?? '',
      etaMinutes: json['eta_minutes'] as int? ?? 0,
      lastUpdated: json['last_updated'] as String? ?? '',
    );
  }
}
