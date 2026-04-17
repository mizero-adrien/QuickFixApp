// Abstract class — covers B3
abstract class ServiceProvider {
  String get id;
  String get name;
  String get phoneNumber;
  String get location;
  double get rating;

  String getContactInfo() {
    return 'Name: $name | Phone: $phoneNumber | Location: $location';
  }
}

// Mixin — covers B3
mixin Rateable {
  double get rating;
  int get totalReviews;

  String get ratingLabel {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.0) return 'Good';
    return 'Fair';
  }
}

// Base class — covers B1, B4
class Artisan with Rateable implements ServiceProvider {
  @override
  final String id;
  @override
  final String name;
  @override
  final String phoneNumber;
  @override
  final String location;
  @override
  final double rating;
  @override
  final int totalReviews;

  final String trade;
  final List<String> skills;
  final int yearsOfExperience;
  final int completedJobs;
  final bool isAvailable;
  final String? profileImageUrl;
  final String about;
  final int startingPrice;

  // Named constructor with named parameters — covers B4
  const Artisan({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.location,
    required this.rating,
    required this.totalReviews,
    required this.trade,
    required this.skills,
    required this.yearsOfExperience,
    required this.completedJobs,
    required this.about,
    required this.startingPrice,
    this.isAvailable = true,
    this.profileImageUrl,
  });

  @override
  String getContactInfo() {
    return 'Artisan: $name | Trade: $trade | Phone: $phoneNumber';
  }
}

// Inheritance — covers B2
class VerifiedArtisan extends Artisan {
  final String verificationId;
  final DateTime verifiedOn;

  const VerifiedArtisan({
    required super.id,
    required super.name,
    required super.phoneNumber,
    required super.location,
    required super.rating,
    required super.totalReviews,
    required super.trade,
    required super.skills,
    required super.yearsOfExperience,
    required super.completedJobs,
    required super.about,
    required super.startingPrice,
    required this.verificationId,
    required this.verifiedOn,
    super.isAvailable,
    super.profileImageUrl,
  });

  bool get isRecentlyVerified {
    final difference = DateTime.now().difference(verifiedOn).inDays;
    return difference <= 365;
  }

  @override
  String getContactInfo() {
    return '${super.getContactInfo()} | Verified ✓';
  }
}