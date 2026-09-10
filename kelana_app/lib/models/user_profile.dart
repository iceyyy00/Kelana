class UserProfile {
  final String userId;
  final String name;
  final String email;
  final String? photoUrl;
  final List<String> favoriteCategories;
  final int avgBudget;
  final String createdAt;

  UserProfile({
    required this.userId,
    required this.name,
    required this.email,
    this.photoUrl,
    this.favoriteCategories = const ['Kuliner', 'Wisata Sejarah'],
    this.avgBudget = 150000,
    required this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'] as String? ?? 'user_1',
      name: json['name'] as String? ?? 'Pengelana',
      email: json['email'] as String? ?? 'user@kelana.app',
      photoUrl: json['photoUrl'] as String?,
      favoriteCategories: (json['favoriteCategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Kuliner', 'Wisata Sejarah'],
      avgBudget: (json['avgBudget'] as num?)?.toInt() ?? 150000,
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'favoriteCategories': favoriteCategories,
      'avgBudget': avgBudget,
      'createdAt': createdAt,
    };
  }

  UserProfile copyWith({
    String? userId,
    String? name,
    String? email,
    String? photoUrl,
    List<String>? favoriteCategories,
    int? avgBudget,
    String? createdAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      avgBudget: avgBudget ?? this.avgBudget,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
