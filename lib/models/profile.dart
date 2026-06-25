class Profile {
  final String id;
  final String username;
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
    required this.bodyType,
    this.height,
    this.weight,
    required this.skinTone,
    required this.stylePreferences,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      username: json['username'],
      bodyType: json['body_type'],
      height: json['height'],
      weight: json['weight'],
      skinTone: json['skin_tone'],
      stylePreferences: List<String>.from(json['style_preferences'] ?? []),
      avatarUrl: json['avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'body_type': bodyType,
    'height': height,
    'weight': weight,
    'skin_tone': skinTone,
    'style_preferences': stylePreferences,
    'avatar_url': avatarUrl,
  };
}