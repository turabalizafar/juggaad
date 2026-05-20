class FollowupResponse {
  final String message;
  final String sendAt;

  FollowupResponse({
    required this.message,
    required this.sendAt,
  });

  factory FollowupResponse.fromJson(Map<String, dynamic> json) {
    return FollowupResponse(
      message: json['message'] as String? ?? '',
      sendAt: json['send_at'] as String? ?? '',
    );
  }
}
