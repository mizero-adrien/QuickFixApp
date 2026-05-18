class AppNotification {
  final String id;
  final String userId;
  final String type; // new_bid | bid_accepted | bid_rejected | booking_declined
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  bool get isForArtisan => type == 'bid_accepted';
  bool get isForHomeowner =>
      type == 'new_bid' || type == 'booking_declined';
}
