import 'package:quickfix/models/artisan.dart';
import 'package:quickfix/models/job.dart';
import 'package:quickfix/models/review.dart';

// Dummy artisans — covers A3 (List, Map, Set)
final List<VerifiedArtisan> dummyArtisans = [
  VerifiedArtisan(
    id: 'a1',
    name: 'Jean Pierre Habimana',
    phoneNumber: '+250781234567',
    location: 'Gasabo, Kigali',
    rating: 4.8,
    totalReviews: 124,
    trade: 'Plumber',
    skills: ['Pipe Repair', 'Leak Detection', 'Water Heater', 'Drain Cleaning'],
    yearsOfExperience: 6,
    completedJobs: 124,
    about:
        'Jean Pierre is a licensed plumber with 6 years of experience serving homeowners across Gasabo and Kicukiro. He specialises in emergency pipe repairs and water heater installations. Known for arriving on time and cleaning up after every job.',
    startingPrice: 5000,
    isAvailable: true,
    verificationId: 'VRF-001',
    verifiedOn: DateTime(2024, 3, 15),
  ),
  VerifiedArtisan(
    id: 'a2',
    name: 'Eric Nshimiyimana',
    phoneNumber: '+250788765432',
    location: 'Kicukiro, Kigali',
    rating: 4.6,
    totalReviews: 89,
    trade: 'Electrician',
    skills: ['Wiring', 'Solar Installation', 'Circuit Breaker', 'Lighting'],
    yearsOfExperience: 8,
    completedJobs: 89,
    about:
        'Eric is a certified electrician with 8 years of experience. He handles everything from basic wiring to full solar panel installations. He has worked with several construction companies in Kigali and brings professional-grade quality to every home job.',
    startingPrice: 8000,
    isAvailable: true,
    verificationId: 'VRF-002',
    verifiedOn: DateTime(2024, 1, 20),
  ),
  VerifiedArtisan(
    id: 'a3',
    name: 'Alice Mukamana',
    phoneNumber: '+250722334455',
    location: 'Nyarugenge, Kigali',
    rating: 4.9,
    totalReviews: 201,
    trade: 'Cleaner',
    skills: ['Deep Cleaning', 'Post-Construction', 'Office Cleaning', 'Carpet'],
    yearsOfExperience: 4,
    completedJobs: 201,
    about:
        'Alice runs a small cleaning team serving homes and offices across Nyarugenge. She is known for her attention to detail and her team always arrives with their own equipment and supplies.',
    startingPrice: 3000,
    isAvailable: false,
    verificationId: 'VRF-003',
    verifiedOn: DateTime(2023, 11, 10),
  ),
  VerifiedArtisan(
    id: 'a4',
    name: 'Patrick Uwitonze',
    phoneNumber: '+250799887766',
    location: 'Gasabo, Kigali',
    rating: 4.3,
    totalReviews: 57,
    trade: 'Carpenter',
    skills: ['Furniture Repair', 'Door Fitting', 'Cabinets', 'Roofing'],
    yearsOfExperience: 10,
    completedJobs: 57,
    about:
        'Patrick is a seasoned carpenter who has been working in Kigali for over a decade. He specialises in custom furniture repair, door and window fitting, and kitchen cabinet installation.',
    startingPrice: 6000,
    isAvailable: true,
    verificationId: 'VRF-004',
    verifiedOn: DateTime(2024, 2, 5),
  ),
  VerifiedArtisan(
    id: 'a5',
    name: 'Claudine Uwase',
    phoneNumber: '+250733221100',
    location: 'Kicukiro, Kigali',
    rating: 4.7,
    totalReviews: 143,
    trade: 'Painter',
    skills: ['Interior Painting', 'Exterior Painting', 'Wall Texturing', 'Waterproofing'],
    yearsOfExperience: 5,
    completedJobs: 143,
    about:
        'Claudine is a professional painter known for her clean finishes and colour consultation skills. She works with both residential and commercial clients and always completes jobs on schedule.',
    startingPrice: 4000,
    isAvailable: true,
    verificationId: 'VRF-005',
    verifiedOn: DateTime(2024, 4, 1),
  ),
];

// Dummy reviews — covers A3 (List)
final List<Review> dummyReviews = [
  Review(
    id: 'r1',
    artisanId: 'a1',
    reviewerName: 'Diane Uwimana',
    rating: 5.0,
    comment:
        'Jean Pierre fixed our burst pipe within 2 hours of booking. Very professional and cleaned up everything after. Highly recommend!',
    createdAt: DateTime(2026, 3, 10),
  ),
  Review(
    id: 'r2',
    artisanId: 'a1',
    reviewerName: 'Robert Mugisha',
    rating: 4.5,
    comment:
        'Good work on the water heater. Arrived on time and explained everything clearly. Will book again.',
    createdAt: DateTime(2026, 2, 22),
  ),
  Review(
    id: 'r3',
    artisanId: 'a2',
    reviewerName: 'Grace Ineza',
    rating: 5.0,
    comment:
        'Eric installed our solar system perfectly. Very knowledgeable and patient with our questions.',
    createdAt: DateTime(2026, 3, 5),
  ),
  Review(
    id: 'r4',
    artisanId: 'a3',
    reviewerName: 'Samuel Nkurunziza',
    rating: 5.0,
    comment:
        'Alice and her team did an incredible deep clean of our new apartment. Worth every franc!',
    createdAt: DateTime(2026, 3, 15),
  ),
];

// Category map — covers A3 (Map)
final Map<String, String> categoryIcons = {
  'Plumbing': '🔧',
  'Electrical': '⚡',
  'Painting': '🎨',
  'Carpentry': '🪚',
  'Cleaning': '🧹',
  'Masonry': '🧱',
};

// Service categories as a Set — covers A3 (Set)
final Set<String> serviceCategories = {
  'Plumbing',
  'Electrical',
  'Painting',
  'Carpentry',
  'Cleaning',
  'Masonry',
};

// Dummy jobs — covers A3 (List)
final List<Job> dummyJobs = [
  Job(
    id: 'j1',
    homeownerId: 'u1',
    title: 'Burst pipe in kitchen',
    description: 'Water leaking under the kitchen sink, needs urgent repair.',
    location: 'KG 15 Ave, Gasabo',
    category: ServiceCategory.plumbing,
    status: JobStatus.inProgress,
    budgetRwf: 10000,
    requestedAt: DateTime(2026, 4, 17),
    assignedArtisanId: 'a1',
  ),
  Job(
    id: 'j2',
    homeownerId: 'u1',
    title: 'Paint living room walls',
    description: 'Need interior painting for a 3-bedroom apartment.',
    location: 'KN 4 Ave, Nyarugenge',
    category: ServiceCategory.painting,
    status: JobStatus.completed,
    budgetRwf: 25000,
    requestedAt: DateTime(2026, 4, 10),
    assignedArtisanId: 'a5',
  ),
];

// Async function simulating data fetch — covers B5
Future<List<VerifiedArtisan>> fetchArtisans() async {
  await Future.delayed(const Duration(seconds: 1));
  return dummyArtisans;
}

Future<List<Review>> fetchReviewsForArtisan(String artisanId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return dummyReviews.where((r) => r.artisanId == artisanId).toList();
}