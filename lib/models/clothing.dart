class Clothing {
  final String id;
  final String userId;
  final String category;
  final String brand;
  final String color;
  final List<String> seasons;
  final String? imageUrl;
  final DateTime? purchaseDate;
  final int? purchasePrice;
  final String? comment;
  final int wearCount;
  final DateTime createdAt;

  Clothing({
    required this.id,
    required this.userId,
    required this.category,
    required this.brand,
    required this.color,
    required this.seasons,
    this.imageUrl,
    this.purchaseDate,
    this.purchasePrice,
    this.comment,
    this.wearCount = 0,
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
        purchaseDate: json['purchase_date'] != null
          ? DateTime.tryParse(json['purchase_date'])
          : null,
        purchasePrice: json['purchase_price'] is num
          ? (json['purchase_price'] as num).toInt()
          : int.tryParse((json['purchase_price'] ?? '').toString()),
        comment: json['comment'],
        wearCount: json['wear_count'] is num
          ? (json['wear_count'] as num).toInt()
          : int.tryParse((json['wear_count'] ?? '0').toString()) ?? 0,
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
    'purchase_date': purchaseDate?.toIso8601String(),
    'purchase_price': purchasePrice,
    'comment': comment,
    'wear_count': wearCount,
  };
}