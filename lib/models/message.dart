import 'package:quickfix/services/supabase_service.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  bool get isMine => senderId == SupabaseService.currentUser?.id;
}

class Conversation {
  final String id;
  final String homeownerId;
  final String artisanId;
  final String? jobId;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final DateTime createdAt;

  // Joined fields
  final String? otherPersonName;
  final String? otherPersonAvatarUrl;
  final String? jobTitle;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.homeownerId,
    required this.artisanId,
    this.jobId,
    this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
    this.otherPersonName,
    this.otherPersonAvatarUrl,
    this.jobTitle,
    this.unreadCount = 0,
  });

  String otherPersonId(String myId) =>
      homeownerId == myId ? artisanId : homeownerId;
}
