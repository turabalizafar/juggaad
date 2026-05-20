class AgentTrace {
  final String step;
  final String message;
  final String timestamp;

  AgentTrace({
    required this.step,
    required this.message,
    required this.timestamp,
  });

  factory AgentTrace.fromJson(Map<String, dynamic> json) {
    return AgentTrace(
      step: json['step'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step': step,
      'message': message,
      'timestamp': timestamp,
    };
  }
}
