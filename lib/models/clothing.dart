class Clothing {
  final String id;
  final String userId;
  final String category;
  final String brand;
  final String color;
  final List<String> seasons;
  final String? imageUrl;
  final DateTime createdAt;

  Clothing({
    required this.id,
    required this.userId,
    required this.category,
    required this.brand,
    required this.color,
    required this.seasons,
    this.imageUrl,
    required this.createdAt,
  });

  factory Clothing.fromJson(Map<String, dynamic> json) {
    return Clothing(
      id: json['id'].toString(),
      userId: json['user_id'] ?? '',
      category: json['category'] ?? '',
      brand: json['brand'] ?? 'etc',
      color: json['color'] ?? '',
      seasons: List<String>.from(json['seasons'] ?? []),
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'category': category,
    'brand': brand,
    'color': color,
    'seasons': seasons,
    'image_url': imageUrl,
  };
}