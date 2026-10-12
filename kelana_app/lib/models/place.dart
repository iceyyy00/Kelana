class Place {
  final String placeId;
  final String name;
  final String category;
  final double rating;
  final int userRatingsTotal;
  final int priceLevel;
  final int estimatedPrice;
  final int estimatedCostMin;
  final int estimatedCostMax;
  final String budgetCategory;
  final String budgetTier;
  final String osmKey;
  final String osmValue;
  final String cuisine;
  final String stars;
  final String fee;
  final double lat;
  final double lng;
  final String address;
  final String photoUrl;
  final String description;
  final String openingHours;
  final int order;
  final bool visited;
  final int estimatedTravelTimeFromPrevious;
  final String? suggestedArrivalTime;
  final int? suggestedDurationMinutes;
  final String? activityTip;

  Place({
    required this.placeId,
    required this.name,
    required this.category,
    required this.rating,
    required this.userRatingsTotal,
    required this.priceLevel,
    required this.estimatedPrice,
    this.estimatedCostMin = 0,
    this.estimatedCostMax = 0,
    this.budgetCategory = 'other',
    this.budgetTier = 'moderate',
    this.osmKey = '',
    this.osmValue = '',
    this.cuisine = '',
    this.stars = '',
    this.fee = '',
    required this.lat,
    required this.lng,
    required this.address,
    required this.photoUrl,
    required this.description,
    required this.openingHours,
    this.order = 1,
    this.visited = false,
    this.estimatedTravelTimeFromPrevious = 0,
    this.suggestedArrivalTime,
    this.suggestedDurationMinutes,
    this.activityTip,
  });

  String get budgetTierLabel => switch (budgetTier) {
        'free' => 'Gratis',
        'budget' => 'Hemat',
        'moderate' => 'Standar',
        'luxury' => 'Premium',
        _ => 'Estimasi',
      };

  bool get hasUsableName {
    final normalizedName = name.trim();
    final letterCount =
        RegExp(r'\p{L}', unicode: true).allMatches(normalizedName).length;
    final digitCount =
        RegExp(r'\p{N}', unicode: true).allMatches(normalizedName).length;
    final alphaNumericCount = letterCount + digitCount;

    return normalizedName.length >= 3 &&
        normalizedName.length <= 100 &&
        letterCount >= 3 &&
        alphaNumericCount > 0 &&
        letterCount / alphaNumericCount >= 0.5 &&
        !RegExp(
          r'^(?:unknown|unnamed|no name|unclassified|object|node|way)\b',
          caseSensitive: false,
        ).hasMatch(normalizedName);
  }

  factory Place.fromJson(Map<String, dynamic> json) {
    final estimatedPrice = (json['estimatedPrice'] as num?)?.toInt() ?? 20000;
    return Place(
      placeId: json['placeId'] as String? ?? '',
      name: json['name'] as String? ?? 'Destinasi',
      category: json['category'] as String? ?? 'Wisata',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      userRatingsTotal: (json['userRatingsTotal'] as num?)?.toInt() ?? 0,
      priceLevel: (json['priceLevel'] as num?)?.toInt() ?? 1,
      estimatedPrice: estimatedPrice,
      estimatedCostMin:
          (json['estimatedCostMin'] as num?)?.toInt() ?? estimatedPrice,
      estimatedCostMax:
          (json['estimatedCostMax'] as num?)?.toInt() ?? estimatedPrice,
      budgetCategory: json['budgetCategory'] as String? ?? 'other',
      budgetTier: json['budgetTier'] as String? ?? 'moderate',
      osmKey: json['osmKey'] as String? ?? '',
      osmValue: json['osmValue'] as String? ?? '',
      cuisine: json['cuisine'] as String? ?? '',
      stars: json['stars']?.toString() ?? '',
      fee: json['fee']?.toString() ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      openingHours: json['openingHours'] as String? ?? 'Buka setiap hari',
      order: (json['order'] as num?)?.toInt() ?? 1,
      visited: json['visited'] as bool? ?? false,
      estimatedTravelTimeFromPrevious:
          (json['estimatedTravelTimeFromPrevious'] as num?)?.toInt() ?? 0,
      suggestedArrivalTime: json['suggestedArrivalTime'] as String?,
      suggestedDurationMinutes:
          (json['suggestedDurationMinutes'] as num?)?.toInt(),
      activityTip: json['activityTip'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'category': category,
      'rating': rating,
      'userRatingsTotal': userRatingsTotal,
      'priceLevel': priceLevel,
      'estimatedPrice': estimatedPrice,
      'estimatedCostMin': estimatedCostMin,
      'estimatedCostMax': estimatedCostMax,
      'budgetCategory': budgetCategory,
      'budgetTier': budgetTier,
      'osmKey': osmKey,
      'osmValue': osmValue,
      'cuisine': cuisine,
      'stars': stars,
      'fee': fee,
      'lat': lat,
      'lng': lng,
      'address': address,
      'photoUrl': photoUrl,
      'description': description,
      'openingHours': openingHours,
      'order': order,
      'visited': visited,
      'estimatedTravelTimeFromPrevious': estimatedTravelTimeFromPrevious,
      'suggestedArrivalTime': suggestedArrivalTime,
      'suggestedDurationMinutes': suggestedDurationMinutes,
      'activityTip': activityTip,
    };
  }

  Place copyWith({
    String? placeId,
    String? name,
    String? category,
    double? rating,
    int? userRatingsTotal,
    int? priceLevel,
    int? estimatedPrice,
    int? estimatedCostMin,
    int? estimatedCostMax,
    String? budgetCategory,
    String? budgetTier,
    String? osmKey,
    String? osmValue,
    String? cuisine,
    String? stars,
    String? fee,
    double? lat,
    double? lng,
    String? address,
    String? photoUrl,
    String? description,
    String? openingHours,
    int? order,
    bool? visited,
    int? estimatedTravelTimeFromPrevious,
    String? suggestedArrivalTime,
    int? suggestedDurationMinutes,
    String? activityTip,
  }) {
    return Place(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      userRatingsTotal: userRatingsTotal ?? this.userRatingsTotal,
      priceLevel: priceLevel ?? this.priceLevel,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      estimatedCostMin: estimatedCostMin ?? this.estimatedCostMin,
      estimatedCostMax: estimatedCostMax ?? this.estimatedCostMax,
      budgetCategory: budgetCategory ?? this.budgetCategory,
      budgetTier: budgetTier ?? this.budgetTier,
      osmKey: osmKey ?? this.osmKey,
      osmValue: osmValue ?? this.osmValue,
      cuisine: cuisine ?? this.cuisine,
      stars: stars ?? this.stars,
      fee: fee ?? this.fee,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      description: description ?? this.description,
      openingHours: openingHours ?? this.openingHours,
      order: order ?? this.order,
      visited: visited ?? this.visited,
      estimatedTravelTimeFromPrevious: estimatedTravelTimeFromPrevious ??
          this.estimatedTravelTimeFromPrevious,
      suggestedArrivalTime: suggestedArrivalTime ?? this.suggestedArrivalTime,
      suggestedDurationMinutes:
          suggestedDurationMinutes ?? this.suggestedDurationMinutes,
      activityTip: activityTip ?? this.activityTip,
    );
  }
}
