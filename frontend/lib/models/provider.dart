class Provider {
  final String id;
  final String name;
  final String phoneNumber;
  final double rating;
  final double distanceKm;
  final int etaMinutes;
  final int basePrice;
  final bool available;
  final double rankScore;
  final String explanation;

  Provider({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.rating,
    required this.distanceKm,
    required this.etaMinutes,
    required this.basePrice,
    required this.available,
    required this.rankScore,
    required this.explanation,
  });
}
