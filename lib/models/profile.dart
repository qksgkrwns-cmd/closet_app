class Profile {
  final String id;
  final String username;
  final String gender;
  final String bodyType;
  final int? height;
  final int? weight;
  final String skinTone;
  final List<String> stylePreferences;
  final String? avatarUrl;
  final DateTime createdAt;

  Profile({
    required this.id,
    required this.username,
    required this.gender,
    required this.bodyType,
    this.height,
    this.weight,
    required this.skinTone,
    required this.stylePreferences,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final rawStyles = json['style_preferences'] ??
        json['style_preference'] ??
        json['styles'] ??
        <dynamic>[];

    return Profile(
      id: json['id'],
      username: (json['username'] ?? 'user').toString(),
      gender: (json['gender'] ?? '미설정').toString(),
      bodyType: (json['body_type'] ?? '미설정').toString(),
      height: json['height'],
      weight: json['weight'],
      skinTone: (json['skin_tone'] ?? '미설정').toString(),
      stylePreferences: List<String>.from(rawStyles),
      avatarUrl: json['avatar_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'gender': gender,
    'body_type': bodyType,
    'height': height,
    'weight': weight,
    'skin_tone': skinTone,
    'style_preferences': stylePreferences,
    'avatar_url': avatarUrl,
  };
}