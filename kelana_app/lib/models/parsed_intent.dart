class ParsedIntent {
  final String location;
  final int budget;
  final String budgetLevel;
  final int foodBudgetPercent;
  final int accommodationBudgetPercent;
  final List<String> categories;
  final String dateTime;
  final int peopleCount;
  final String userNotes;

  ParsedIntent({
    required this.location,
    required this.budget,
    required this.budgetLevel,
    this.foodBudgetPercent = 50,
    this.accommodationBudgetPercent = 20,
    required this.categories,
    required this.dateTime,
    required this.peopleCount,
    required this.userNotes,
  });

  factory ParsedIntent.fromJson(Map<String, dynamic> json) {
    return ParsedIntent(
      location: json['location'] as String? ?? '',
      budget: (json['budget'] as num?)?.toInt() ?? 100000,
      budgetLevel: json['budgetLevel'] as String? ?? 'budget',
        foodBudgetPercent: (json['foodBudgetPercent'] as num?)?.toInt() ?? 50,
        accommodationBudgetPercent:
          (json['accommodationBudgetPercent'] as num?)?.toInt() ?? 20,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Wisata', 'Kuliner'],
      dateTime: json['dateTime'] as String? ?? 'Belum ditentukan',
      peopleCount: (json['peopleCount'] as num?)?.toInt() ?? 1,
      userNotes: json['userNotes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'budget': budget,
      'budgetLevel': budgetLevel,
      'foodBudgetPercent': foodBudgetPercent,
      'accommodationBudgetPercent': accommodationBudgetPercent,
      'categories': categories,
      'dateTime': dateTime,
      'peopleCount': peopleCount,
      'userNotes': userNotes,
    };
  }

  ParsedIntent copyWith({
    String? location,
    int? budget,
    String? budgetLevel,
    int? foodBudgetPercent,
    int? accommodationBudgetPercent,
    List<String>? categories,
    String? dateTime,
    int? peopleCount,
    String? userNotes,
  }) {
    return ParsedIntent(
      location: location ?? this.location,
      budget: budget ?? this.budget,
      budgetLevel: budgetLevel ?? this.budgetLevel,
        foodBudgetPercent: foodBudgetPercent ?? this.foodBudgetPercent,
        accommodationBudgetPercent:
          accommodationBudgetPercent ?? this.accommodationBudgetPercent,
      categories: categories ?? this.categories,
      dateTime: dateTime ?? this.dateTime,
      peopleCount: peopleCount ?? this.peopleCount,
      userNotes: userNotes ?? this.userNotes,
    );
  }
}
