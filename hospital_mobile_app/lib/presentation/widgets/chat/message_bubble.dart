import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwnMessage;
  final String? senderName;
  final String? senderAvatar;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.senderName,
    this.senderAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for received messages (left side)
          if (!isOwnMessage) ...[
            _buildAvatar(isOwn: false),
            const SizedBox(width: 8),
          ],
          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isOwnMessage
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isOwnMessage ? 18 : 4),
                  bottomRight: Radius.circular(isOwnMessage ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isOwnMessage
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Attachments
                  if (message.attachments != null &&
                      message.attachments!.isNotEmpty)
                    _buildAttachments(context),
                  // Message content
                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isOwnMessage ? Colors.white : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Timestamp
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: isOwnMessage
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Avatar for own messages (right side)
          if (isOwnMessage) ...[
            const SizedBox(width: 8),
            _buildAvatar(isOwn: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar({bool isOwn = false}) {
    if (senderAvatar != null && senderAvatar!.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: CachedNetworkImageProvider(senderAvatar!),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: isOwn ? Colors.green.shade100 : Colors.blue.shade100,
      child: Text(
        senderName?.isNotEmpty == true ? senderName![0].toUpperCase() : (isOwn ? 'T' : 'U'),
        style: TextStyle(
          color: isOwn ? Colors.green.shade700 : Colors.blue.shade700,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAttachments(BuildContext context) {
    return Column(
      children: message.attachments!.map((attachment) {
        if (attachment.resourceType == 'image') {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: attachment.url,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 150,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 150,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.error),
                ),
              ),
            ),
          );
        } else if (attachment.resourceType == 'video') {
          return Container(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  String _formatTime(DateTime dateTime) {
    // Convert UTC to local timezone
    final localTime = dateTime.toLocal();
    final now = DateTime.now();
    final diff = now.difference(localTime);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(localTime);
    } else if (diff.inDays == 1) {
      return 'Hôm qua ${DateFormat('HH:mm').format(localTime)}';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE HH:mm', 'vi').format(localTime);
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(localTime);
    }
  }
}
