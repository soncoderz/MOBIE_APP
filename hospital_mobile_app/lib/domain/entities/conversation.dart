import 'package:equatable/equatable.dart';
import 'message.dart';

class Conversation extends Equatable {
  final String id;
  final List<ChatParticipant> participants;
  final Message? lastMessage;
  final Map<String, int>? unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    // Parse unreadCount which can be Map or object
    Map<String, int>? unreadCount;
    if (json['unreadCount'] != null) {
      if (json['unreadCount'] is Map) {
        unreadCount = Map<String, int>.from(
          (json['unreadCount'] as Map).map(
            (key, value) => MapEntry(key.toString(), value as int? ?? 0),
          ),
        );
      }
    }

    // Handle id which can be string or ObjectId object
    String id;
    if (json['_id'] is Map) {
      id = json['_id']['\$oid'] ?? json['_id']['_id'] ?? json['_id'].toString();
    } else {
      id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    }

    return Conversation(
      id: id,
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => ChatParticipant.fromJson(p))
              .toList()
          : [],
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      unreadCount: unreadCount,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Get unread count for a specific user
  int getUnreadCountForUser(String userId) {
    return unreadCount?[userId] ?? 0;
  }

  /// Get the other participant (not the current user)
  ChatParticipant? getOtherParticipant(String currentUserId) {
    try {
      return participants.firstWhere((p) => p.id != currentUserId);
    } catch (_) {
      return participants.isNotEmpty ? participants.first : null;
    }
  }

  @override
  List<Object?> get props => [
        id,
        participants,
        lastMessage,
        unreadCount,
        createdAt,
        updatedAt,
      ];
}
