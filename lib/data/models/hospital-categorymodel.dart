class Category {
  final int id;
  final String name;
  final String? imageUrl;
  final bool isActive;

  static const String s3BaseUrl =
      "https://hostahealthcare.s3.eu-north-1.amazonaws.com/";

  Category({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final image = json['imageUrl']?.toString().trim();

    String? fullImageUrl;

    if (image != null && image.isNotEmpty) {
      if (image.startsWith("http://") || image.startsWith("https://")) {
        fullImageUrl = image;
      } else {
        fullImageUrl = "$s3BaseUrl$image";
      }
    }

    return Category(
      id: json['id'],
      name: json['name'] ?? '',
      imageUrl: fullImageUrl,
      isActive: json['isActive'] ?? false,
    );
  }
}