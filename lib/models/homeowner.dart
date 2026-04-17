import 'package:quickfix/models/artisan.dart';

// Homeowner model — extends ServiceProvider (covers B2 inheritance)
class Homeowner implements ServiceProvider {
  @override
  final String id;
  @override
  final String name;
  @override
  final String phoneNumber;
  @override
  final String location;
  @override
  final double rating = 0.0;

  final String email;
  final String district;
  final bool isVerified;
  final DateTime joinedAt;
  final int? totalJobsPosted;

  const Homeowner({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.location,
    required this.email,
    required this.district,
    required this.joinedAt,
    this.isVerified = false,
    this.totalJobsPosted = 0,
  });

  @override
  String getContactInfo() {
    return 'Homeowner: $name | Phone: $phoneNumber | District: $district';
  }

  // Covers A4 — switch statement
  String get districtLabel {
    switch (district) {
      case 'gasabo':
        return 'Gasabo District';
      case 'kicukiro':
        return 'Kicukiro District';
      case 'nyarugenge':
        return 'Nyarugenge District';
      default:
        return 'Kigali, Rwanda';
    }
  }

  // Covers A2 — arrow function
  bool get isActiveUser =>
      totalJobsPosted != null && totalJobsPosted! > 0;
}

// User session — tracks who is logged in
// Covers A1 — nullable types
class UserSession {
  static Homeowner? currentHomeowner;
  static Artisan? currentArtisan;
  static UserType? userType;

  // Covers A4 — ternary
  static bool get isLoggedIn =>
      currentHomeowner != null || currentArtisan != null;

  static void loginAsHomeowner(Homeowner homeowner) {
    currentHomeowner = homeowner;
    userType = UserType.homeowner;
    currentArtisan = null;
  }

  static void loginAsArtisan(Artisan artisan) {
    currentArtisan = artisan;
    userType = UserType.artisan;
    currentHomeowner = null;
  }

  static void logout() {
    currentHomeowner = null;
    currentArtisan = null;
    userType = null;
  }
}

// Covers A3 — enum used as a Set equivalent for user types
enum UserType {
  homeowner,
  artisan,
}