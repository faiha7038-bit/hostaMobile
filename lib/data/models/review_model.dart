class Review {
  final int id;
  final int userId;
  final String name;
  final String? imageUrl;
  final String comment;
  final int rating;

  Review({
    required this.id,
    required this.userId,
    required this.name,
    this.imageUrl,
    required this.comment,
    required this.rating,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['userId'],
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'],
      comment: json['comment'] ?? '',
      rating: json['rating'] ?? 0,
    );
  }
}