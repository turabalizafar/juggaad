class ParsedIntent {
  final String serviceType;
  final String? locationText;
  final String urgency;
  final String issueSummary;
  final String languageDetected;

  ParsedIntent({
    required this.serviceType,
    this.locationText,
    required this.urgency,
    required this.issueSummary,
    required this.languageDetected,
  });
}
