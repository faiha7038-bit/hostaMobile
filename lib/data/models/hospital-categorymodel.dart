class Category {
  final int id;
  final String name;
  final String? imageUrl;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? false,
    );
  }
}