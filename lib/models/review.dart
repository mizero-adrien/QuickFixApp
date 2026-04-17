// Review model — covers B1, B4
class Review {
  final String id;
  final String artisanId;
  final String reviewerName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.artisanId,
    required this.reviewerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}