import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../../domain/entities/conversation.dart';
import '../../../domain/entities/message.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/chat/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String? conversationId;
  final String? doctorId;
  final String? doctorName;

  const ChatScreen({
    super.key,
    this.conversationId,
    this.doctorId,
    this.doctorName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  Timer? _typingTimer;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi', null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChat();
    });
  }

  Future<void> _initChat() async {
    final chatProvider = context.read<ChatProvider>();
    final authProvider = context.read<AuthProvider>();
    
    // Set userId from AuthProvider
    chatProvider.setUserId(authProvider.user?.id);
    
    // Initialize socket if not connected
    if (!chatProvider.isSocketConnected) {
      await chatProvider.initSocket();
    }

    // Start conversation with doctor or open existing conversation
    if (widget.doctorId != null) {
      await chatProvider.startConversation(widget.doctorId!);
    } else if (widget.conversationId != null) {
      // Fetch conversation details and messages
      await chatProvider.fetchConversations();
      final conv = chatProvider.conversations.firstWhere(
        (c) => c.id == widget.conversationId,
        orElse: () => throw Exception('Conversation not found'),
      );
      await chatProvider.openConversation(conv);
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _handleTyping() {
    final chatProvider = context.read<ChatProvider>();
    final otherParticipant = chatProvider.currentConversation
        ?.getOtherParticipant(chatProvider.currentUserId ?? '');
    
    if (otherParticipant == null) return;

    chatProvider.emitTypingStart(otherParticipant.id);

    // Clear previous timer
    _typingTimer?.cancel();

    // Stop typing after 2 seconds of no input
    _typingTimer = Timer(const Duration(seconds: 2), () {
      chatProvider.emitTypingStop(otherParticipant.id);
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final chatProvider = context.read<ChatProvider>();
    final otherParticipant = chatProvider.currentConversation
        ?.getOtherParticipant(chatProvider.currentUserId ?? '');
    
    if (otherParticipant != null) {
      chatProvider.emitTypingStop(otherParticipant.id);
    }

    await chatProvider.sendMessage(content);
    
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile == null) return;

    setState(() => _isSending = true);
    
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.sendMediaMessage(File(pickedFile.path), null);
    
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    context.read<ChatProvider>().clearCurrentConversation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoading && chatProvider.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (chatProvider.errorMessage != null && 
                    chatProvider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text(
                          chatProvider.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initChat,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (chatProvider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, 
                             size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có tin nhắn',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hãy bắt đầu cuộc trò chuyện!',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Get other participant info
                final otherParticipant = chatProvider.currentConversation
                    ?.getOtherParticipant(chatProvider.currentUserId ?? '');

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    final isOwnMessage = 
                        message.senderId == chatProvider.currentUserId;

                    return MessageBubble(
                      message: message,
                      isOwnMessage: isOwnMessage,
                      senderName: isOwnMessage ? null : otherParticipant?.fullName,
                      senderAvatar: isOwnMessage ? null : otherParticipant?.avatarUrl,
                    );
                  },
                );
              },
            ),
          ),
          // Typing indicator
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              if (!chatProvider.isTyping) return const SizedBox.shrink();
              
              final otherParticipant = chatProvider.currentConversation
                  ?.getOtherParticipant(chatProvider.currentUserId ?? '');
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${otherParticipant?.fullName ?? 'Bác sĩ'} đang gõ',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      height: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(3, (i) => _buildTypingDot(i)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      title: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final otherParticipant = chatProvider.currentConversation
              ?.getOtherParticipant(chatProvider.currentUserId ?? '');
          
          if (otherParticipant == null && widget.doctorName != null) {
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    widget.doctorName![0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.doctorName!,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }

          final isOnline = chatProvider.isUserOnline(otherParticipant?.id);

          return Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: otherParticipant?.avatarUrl != null
                        ? NetworkImage(otherParticipant!.avatarUrl!)
                        : null,
                    child: otherParticipant?.avatarUrl == null
                        ? Text(
                            otherParticipant?.fullName.isNotEmpty == true
                                ? otherParticipant!.fullName[0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherParticipant?.fullName ?? 'Đang tải...',
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isOnline ? 'Đang hoạt động' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOnline ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button
          IconButton(
            onPressed: _isSending ? null : _pickAndSendImage,
            icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          // Message text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                onChanged: (_) => _handleTyping(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          Material(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: _isSending ? null : _sendMessage,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
