import 'place.dart';
import 'parsed_intent.dart';

class LatLngPoint {
  final double lat;
  final double lng;
  LatLngPoint({required this.lat, required this.lng});

  factory LatLngPoint.fromJson(Map<String, dynamic> json) {
    return LatLngPoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class Itinerary {
  final String id;
  final String userId;
  final String title;
  final String summary;
  final String createdAt;
  final String status; // 'draft', 'saved', 'completed'
  final String rawQuery;
  final String location;
  final ParsedIntent? parsedIntent;
  final List<Place> places;
  final int totalEstimatedTravelMinutes;
  final List<LatLngPoint> polylinePoints;
  final String? shareCode;

  Itinerary({
    required this.id,
    this.userId = 'user_guest',
    required this.title,
    required this.summary,
    required this.createdAt,
    this.status = 'draft',
    this.rawQuery = '',
    required this.location,
    this.parsedIntent,
    required this.places,
    this.totalEstimatedTravelMinutes = 0,
    this.polylinePoints = const [],
    this.shareCode,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'] as String? ?? 'itinerary_${DateTime.now().millisecondsSinceEpoch}',
      userId: json['userId'] as String? ?? 'user_guest',
      title: json['title'] as String? ?? 'Itinerary Kelana',
      summary: json['summary'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      status: json['status'] as String? ?? 'saved',
      rawQuery: json['rawQuery'] as String? ?? '',
      location: json['location'] as String? ?? 'Indonesia',
      parsedIntent: json['parsedIntent'] != null
          ? ParsedIntent.fromJson(json['parsedIntent'] as Map<String, dynamic>)
          : null,
      places: (json['places'] as List<dynamic>?)
              ?.map((p) => Place.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      totalEstimatedTravelMinutes:
          (json['totalEstimatedTravelMinutes'] as num?)?.toInt() ?? 0,
      polylinePoints: (json['polylinePoints'] as List<dynamic>?)
              ?.map((pt) => LatLngPoint.fromJson(pt as Map<String, dynamic>))
              .toList() ??
          [],
      shareCode: json['shareCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'summary': summary,
      'createdAt': createdAt,
      'status': status,
      'rawQuery': rawQuery,
      'location': location,
      'parsedIntent': parsedIntent?.toJson(),
      'places': places.map((p) => p.toJson()).toList(),
      'totalEstimatedTravelMinutes': totalEstimatedTravelMinutes,
      'polylinePoints': polylinePoints.map((pt) => pt.toJson()).toList(),
      'shareCode': shareCode,
    };
  }

  int get totalEstimatedCost {
    return places.fold(0, (sum, p) => sum + p.estimatedPrice);
  }

  int get visitedCount {
    return places.where((p) => p.visited).length;
  }

  Itinerary copyWith({
    String? id,
    String? userId,
    String? title,
    String? summary,
    String? createdAt,
    String? status,
    String? rawQuery,
    String? location,
    ParsedIntent? parsedIntent,
    List<Place>? places,
    int? totalEstimatedTravelMinutes,
    List<LatLngPoint>? polylinePoints,
    String? shareCode,
  }) {
    return Itinerary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      rawQuery: rawQuery ?? this.rawQuery,
      location: location ?? this.location,
      parsedIntent: parsedIntent ?? this.parsedIntent,
      places: places ?? this.places,
      totalEstimatedTravelMinutes:
          totalEstimatedTravelMinutes ?? this.totalEstimatedTravelMinutes,
      polylinePoints: polylinePoints ?? this.polylinePoints,
      shareCode: shareCode ?? this.shareCode,
    );
  }
}
