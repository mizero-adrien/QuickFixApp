enum BidStatus { pending, accepted, rejected }

class Bid {
  final String id;
  final String jobId;
  final String artisanId;
  final int amountRwf;
  final String note;
  final BidStatus status;
  final DateTime createdAt;
  final String? jobTitle;
  final String? jobCategory;
  final String? jobLocation;
  final String? artisanName;
  final String? artisanTrade;
  final double? artisanRating;

  const Bid({
    required this.id,
    required this.jobId,
    required this.artisanId,
    required this.amountRwf,
    required this.note,
    required this.status,
    required this.createdAt,
    this.jobTitle,
    this.jobCategory,
    this.jobLocation,
    this.artisanName,
    this.artisanTrade,
    this.artisanRating,
  });

  String get statusLabel {
    switch (status) {
      case BidStatus.pending:
        return 'Pending';
      case BidStatus.accepted:
        return 'Accepted';
      case BidStatus.rejected:
        return 'Rejected';
    }
  }
}
