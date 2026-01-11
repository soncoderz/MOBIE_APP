import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import '../../core/constants/api_constants.dart';
import '../../core/services/token_storage_service.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import 'dart:io';

class ChatProvider extends ChangeNotifier {
  final ChatRepositoryImpl _chatRepository;
  final TokenStorageService _tokenStorage;
  String? _userId;

  ChatProvider({
    required ChatRepositoryImpl chatRepository,
    required TokenStorageService tokenStorage,
  })  : _chatRepository = chatRepository,
        _tokenStorage = tokenStorage;

  // Socket
  IO.Socket? _socket;
  bool _isSocketConnected = false;

  // State
  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  Conversation? _currentConversation;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isTyping = false;
  Set<String> _onlineUsers = {};

  // Getters
  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  Conversation? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isTyping => _isTyping;
  bool get isSocketConnected => _isSocketConnected;
  String? get currentUserId => _userId;

  /// Set current user ID (called from auth state)
  void setUserId(String? userId) {
    _userId = userId;
  }

  bool isUserOnline(String? userId) {
    if (userId == null) return false;
    return _onlineUsers.contains(userId);
  }

  /// Initialize socket connection
  Future<void> initSocket() async {
    if (_socket != null) {
      // Socket already exists, check if connected
      if (_isSocketConnected) {
        debugPrint('🔌 [Socket] Already connected, skipping init');
        return;
      }
      // Socket exists but not connected, reconnect
      debugPrint('🔌 [Socket] Socket exists but not connected, reconnecting...');
    }

    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      debugPrint('🔌 No token for socket auth');
      return;
    }

    try {
      debugPrint('🔌 Initializing socket connection to ${ApiConstants.socketUrl}');

      // Create a completer to wait for connection
      final completer = Completer<void>();

      _socket = IO.io(
        ApiConstants.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .setPath('/socket.io')
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('🔌 [Socket] CONNECTED successfully!');
        _isSocketConnected = true;
        notifyListeners();
        // Complete the completer if not already done
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      _socket!.onDisconnect((_) {
        debugPrint('🔌 [Socket] DISCONNECTED');
        _isSocketConnected = false;
        notifyListeners();
      });

      _socket!.onConnectError((error) {
        debugPrint('🔌 [Socket] Connection ERROR: $error');
        // Complete with error if not already done
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });
      
      // Debug: Listen to all events (for debugging only)
      _socket!.onAny((event, data) {
        debugPrint('🔌 [Socket] Event received: $event');
      });

      // Listen for online users
      _socket!.on('online_users', (users) {
        if (users is List) {
          _onlineUsers = Set<String>.from(users.map((u) => u.toString()));
          notifyListeners();
        }
      });

      _socket!.on('user_online', (data) {
        if (data['userId'] != null) {
          _onlineUsers.add(data['userId']);
          notifyListeners();
        }
      });

      _socket!.on('user_offline', (data) {
        if (data['userId'] != null) {
          _onlineUsers.remove(data['userId']);
          notifyListeners();
        }
      });

      // Listen for new messages (from conversation room)
      _socket!.on('new_message', (data) {
        debugPrint('🔌 [Socket] new_message event received!');
        _handleNewMessage(data);
      });
      
      // Listen for message notifications (from personal room - always received)
      // This is a fallback in case conversation room join fails
      _socket!.on('message_notification', (data) {
        debugPrint('🔌 [Socket] message_notification event received!');
        debugPrint('🔌 [Socket] Notification data: $data');
        
        // Extract message from notification data
        if (data != null && data['message'] != null) {
          _handleNewMessage(data['message']);
        }
      });

      // Listen for typing events
      _socket!.on('user_typing', (data) {
        if (data['conversationId'] == _currentConversation?.id) {
          _isTyping = true;
          notifyListeners();
          // Auto hide after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            _isTyping = false;
            notifyListeners();
          });
        }
      });

      _socket!.on('user_stop_typing', (data) {
        if (data['conversationId'] == _currentConversation?.id) {
          _isTyping = false;
          notifyListeners();
        }
      });

      _socket!.on('messages_read', (data) {
        // Refresh conversations to update unread count
        fetchConversations();
      });

      _socket!.connect();
      
      // Wait for connection with timeout
      debugPrint('🔌 [Socket] Waiting for connection...');
      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('🔌 [Socket] Connection timeout after 5 seconds');
        },
      );
      debugPrint('🔌 [Socket] initSocket completed, connected: $_isSocketConnected');
    } catch (e) {
      debugPrint('🔌 Socket init error: $e');
    }
  }

  /// Disconnect socket
  void disconnectSocket() {
    if (_socket != null) {
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isSocketConnected = false;
    }
  }

  /// Handle incoming new message
  void _handleNewMessage(dynamic data) {
    try {
      debugPrint('📨 [Socket] Received new_message event');
      debugPrint('📨 [Socket] Raw data: $data');
      
      final message = Message.fromJson(data);
      
      debugPrint('📨 [Socket] Parsed message - id: ${message.id}, conversationId: ${message.conversationId}');
      debugPrint('📨 [Socket] Current conversation id: ${_currentConversation?.id}');
      debugPrint('📨 [Socket] Message sender: ${message.senderId}, Current user: $_userId');
      
      // If it's for the current conversation, add to messages
      // Use string comparison to handle potential ObjectId vs String issues
      final isForCurrentConversation = _currentConversation != null && 
          message.conversationId.toString() == _currentConversation!.id.toString();
      
      debugPrint('📨 [Socket] Is for current conversation: $isForCurrentConversation');
      
      if (isForCurrentConversation) {
        // Check if message already exists to avoid duplicates
        final exists = _messages.any((m) => m.id == message.id);
        debugPrint('📨 [Socket] Message already exists: $exists');
        
        if (!exists) {
          _messages.add(message);
          debugPrint('📨 [Socket] Message added to list. Total messages: ${_messages.length}');
          
          // Mark as read if not from current user
          if (message.senderId != _userId) {
            _markMessagesAsRead([message.id]);
          }
          notifyListeners();
        }
      }
      
      // Refresh conversations list
      fetchConversations();
    } catch (e, stackTrace) {
      debugPrint('❌ [Socket] Error handling new message: $e');
      debugPrint('❌ [Socket] Stack trace: $stackTrace');
    }
  }

  /// Join a conversation room
  Future<void> joinConversation(String conversationId) async {
    debugPrint('🚪 [Socket] Attempting to join conversation: $conversationId');
    debugPrint('🚪 [Socket] Socket null: ${_socket == null}, Connected: $_isSocketConnected');
    
    // If socket is not connected, wait a bit and check again
    if (_socket == null || !_isSocketConnected) {
      debugPrint('🚪 [Socket] Socket not ready, waiting 500ms...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check again after delay
      if (_socket == null || !_isSocketConnected) {
        debugPrint('🚪 [Socket] Still not connected after wait, cannot join');
        return;
      }
    }
    
    _socket!.emit('join_conversation', {'conversationId': conversationId});
    debugPrint('🚪 [Socket] Joined conversation room: conversation:$conversationId');
  }

  /// Leave a conversation room
  void leaveConversation(String conversationId) {
    if (_socket == null || !_isSocketConnected) return;
    
    _socket!.emit('leave_conversation', {'conversationId': conversationId});
    debugPrint('🚪 Left conversation: $conversationId');
  }

  /// Emit typing start event
  void emitTypingStart(String receiverId) {
    if (_socket == null || !_isSocketConnected || _currentConversation == null) return;
    
    _socket!.emit('typing_start', {
      'conversationId': _currentConversation!.id,
      'receiverId': receiverId,
    });
  }

  /// Emit typing stop event
  void emitTypingStop(String receiverId) {
    if (_socket == null || !_isSocketConnected || _currentConversation == null) return;
    
    _socket!.emit('typing_stop', {
      'conversationId': _currentConversation!.id,
      'receiverId': receiverId,
    });
  }

  /// Mark messages as read via socket
  void _markMessagesAsRead(List<String> messageIds) {
    if (_socket == null || !_isSocketConnected || _currentConversation == null) return;
    
    _socket!.emit('mark_as_read', {
      'conversationId': _currentConversation!.id,
      'messageIds': messageIds,
    });
  }

  /// Fetch all conversations
  Future<void> fetchConversations() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _conversations = await _chatRepository.getConversations();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Fetch messages for a conversation
  Future<void> fetchMessages(String conversationId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _messages = await _chatRepository.getMessages(conversationId);
      
      // Mark unread messages as read
      if (_userId != null) {
        final unreadIds = _messages
            .where((m) => m.senderId != _userId && !m.isRead)
            .map((m) => m.id)
            .toList();
        if (unreadIds.isNotEmpty) {
          _markMessagesAsRead(unreadIds);
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Start or get existing conversation with a doctor
  Future<Conversation?> startConversation(String doctorId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final conversation = await _chatRepository.startConversation(doctorId);
      if (conversation != null) {
        _currentConversation = conversation;
        await joinConversation(conversation.id);
        await fetchMessages(conversation.id);
      }
      
      _isLoading = false;
      notifyListeners();
      return conversation;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Set current conversation and fetch messages
  Future<void> openConversation(Conversation conversation) async {
    // Leave previous conversation if any
    if (_currentConversation != null) {
      leaveConversation(_currentConversation!.id);
    }
    
    _currentConversation = conversation;
    await joinConversation(conversation.id);
    await fetchMessages(conversation.id);
  }

  /// Send a text message
  Future<bool> sendMessage(String content) async {
    if (_currentConversation == null) return false;
    
    try {
      final message = await _chatRepository.sendMessage(
        _currentConversation!.id,
        content,
      );
      
      if (message != null) {
        // Add message immediately to the local list for instant UI update
        // Check if message already exists to avoid duplicates from socket
        final exists = _messages.any((m) => m.id == message.id);
        if (!exists) {
          _messages.add(message);
          notifyListeners();
        }
      }
      
      return message != null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Send message with media attachment
  Future<bool> sendMediaMessage(File file, String? caption) async {
    if (_currentConversation == null) return false;
    
    try {
      // Upload media first
      final mediaData = await _chatRepository.uploadMedia(file);
      if (mediaData == null) return false;
      
      // Send message with attachment
      final message = await _chatRepository.sendMessageWithAttachment(
        _currentConversation!.id,
        caption ?? (mediaData['resourceType'] == 'image' ? 'Đã gửi ảnh' : 'Đã gửi video'),
        mediaData,
      );
      
      if (message != null) {
        // Add message immediately to the local list for instant UI update
        final exists = _messages.any((m) => m.id == message.id);
        if (!exists) {
          _messages.add(message);
          notifyListeners();
        }
      }
      
      return message != null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Clear current conversation
  void clearCurrentConversation() {
    if (_currentConversation != null) {
      leaveConversation(_currentConversation!.id);
    }
    _currentConversation = null;
    _messages = [];
    _isTyping = false;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnectSocket();
    super.dispose();
  }
}
