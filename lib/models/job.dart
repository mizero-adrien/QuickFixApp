// Enum for job status — covers A4
enum JobStatus {
  requested,
  quoted,
  booked,
  onTheWay,
  inProgress,
  completed,
  cancelled,
}

// Enum for service category
enum ServiceCategory {
  plumbing,
  electrical,
  painting,
  carpentry,
  cleaning,
  masonry,
}

// Job model — covers B1, B4
class Job {
  final String id;
  final String homeownerId;
  final String title;
  final String description;
  final String location;
  final ServiceCategory category;
  final JobStatus status;
  final int? budgetRwf;
  final DateTime requestedAt;
  final String? assignedArtisanId;
  final String? photoUrl;

  const Job({
    required this.id,
    required this.homeownerId,
    required this.title,
    required this.description,
    required this.location,
    required this.category,
    required this.requestedAt,
    this.status = JobStatus.requested,
    this.budgetRwf,
    this.assignedArtisanId,
    this.photoUrl,
  });

  // Returns human readable status — covers A4
  String get statusLabel {
    switch (status) {
      case JobStatus.requested:
        return 'Requested';
      case JobStatus.quoted:
        return 'Quoted';
      case JobStatus.booked:
        return 'Booked';
      case JobStatus.onTheWay:
        return 'On the Way';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
      case JobStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get categoryLabel {
    switch (category) {
      case ServiceCategory.plumbing:
        return 'Plumbing';
      case ServiceCategory.electrical:
        return 'Electrical';
      case ServiceCategory.painting:
        return 'Painting';
      case ServiceCategory.carpentry:
        return 'Carpentry';
      case ServiceCategory.cleaning:
        return 'Cleaning';
      case ServiceCategory.masonry:
        return 'Masonry';
    }
  }
}