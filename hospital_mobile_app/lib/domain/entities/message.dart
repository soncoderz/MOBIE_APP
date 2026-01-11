import 'package:equatable/equatable.dart';

class ChatParticipant extends Equatable {
  final String id;
  final String fullName;
  final String? avatarUrl;
  final String roleType; // 'patient' or 'doctor'

  const ChatParticipant({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.roleType,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    // Handle avatar which can be avatarUrl, profileImage, or avatar.url
    String? avatarUrl;
    if (json['avatarUrl'] != null) {
      avatarUrl = json['avatarUrl'];
    } else if (json['profileImage'] != null) {
      avatarUrl = json['profileImage'];
    } else if (json['avatar'] != null && json['avatar'] is Map) {
      avatarUrl = json['avatar']['url'];
    }
    
    return ChatParticipant(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      avatarUrl: avatarUrl,
      roleType: json['roleType'] ?? 'patient',
    );
  }

  @override
  List<Object?> get props => [id, fullName, avatarUrl, roleType];
}

class Message extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final List<MessageAttachment>? attachments;
  final Map<String, dynamic>? appointmentData;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.attachments,
    this.appointmentData,
    this.isRead = false,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Handle senderId which can be string or object
    String senderId;
    if (json['senderId'] is Map) {
      senderId = json['senderId']['_id'] ?? json['senderId']['id'] ?? '';
    } else {
      senderId = json['senderId'] ?? '';
    }

    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: senderId,
      content: json['content'] ?? '',
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((a) => MessageAttachment.fromJson(a))
              .toList()
          : null,
      appointmentData: json['appointmentData'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        content,
        attachments,
        appointmentData,
        isRead,
        createdAt,
      ];
}

class MessageAttachment extends Equatable {
  final String url;
  final String publicId;
  final String resourceType; // 'image' or 'video'
  final int? width;
  final int? height;

  const MessageAttachment({
    required this.url,
    required this.publicId,
    required this.resourceType,
    this.width,
    this.height,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      url: json['url'] ?? '',
      publicId: json['publicId'] ?? '',
      resourceType: json['resourceType'] ?? 'image',
      width: json['width'],
      height: json['height'],
    );
  }

  @override
  List<Object?> get props => [url, publicId, resourceType, width, height];
}
