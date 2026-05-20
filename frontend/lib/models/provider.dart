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

  factory Provider.fromJson(Map<String, dynamic> json) {
    return Provider(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown',
      phoneNumber: json['phone_number'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      etaMinutes: json['eta_minutes'] as int? ?? 0,
      basePrice: json['base_price'] as int? ?? 0,
      available: json['available'] as bool? ?? false,
      rankScore: (json['rank_score'] as num?)?.toDouble() ?? 0.0,
      explanation: json['explanation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'rating': rating,
      'distance_km': distanceKm,
      'eta_minutes': etaMinutes,
      'base_price': basePrice,
      'available': available,
      'rank_score': rankScore,
      'explanation': explanation,
    };
  }
}
