class Outfit {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<String> clothesIds;
  final String? imageUrl;
  final List<String> seasons;
  final int likesCount;
  final DateTime createdAt;

  Outfit({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.clothesIds,
    this.imageUrl,
    required this.seasons,
    this.likesCount = 0,
    required this.createdAt,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'],
      clothesIds: List<String>.from(json['clothes_ids'] ?? []),
      imageUrl: json['image_url'],
      seasons: List<String>.from(json['season'] ?? []),
      likesCount: json['likes_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}