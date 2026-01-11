import 'package:flutter/foundation.dart';
import '../../data/models/chatbot_model.dart';
import '../../data/repositories/chatbot_repository.dart';

class ChatbotProvider extends ChangeNotifier {
  final ChatbotRepository _repository;

  ChatbotProvider(this._repository);

  List<ChatbotMessageModel> _messages = [];
  bool _isLoading = false;
  String? _error;

  List<ChatbotMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load chat history from server
  Future<void> loadChatHistory() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _messages = await _repository.getChatHistory();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Send a message to the chatbot
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    try {
      // Add user message immediately
      final userMessage = ChatbotMessageModel(
        role: 'user',
        content: message,
        timestamp: DateTime.now(),
      );
      _messages.add(userMessage);
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Send to API and get response
      final response = await _repository.sendMessage(message);

      // Add bot response
      final botMessage = ChatbotMessageModel(
        role: 'assistant',
        content: response.message,
        timestamp: response.timestamp,
        structuredData: response.structuredData,
      );
      _messages.add(botMessage);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();

      // Add error message as bot response
      final errorMessage = ChatbotMessageModel(
        role: 'assistant',
        content: 'Xin lỗi, có lỗi xảy ra. Vui lòng thử lại sau.',
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
      notifyListeners();
    }
  }

  /// Clear chat history
  Future<void> clearHistory() async {
    try {
      await _repository.clearChatHistory();
      _messages = [];
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear local messages only
  void clearLocalMessages() {
    _messages = [];
    _error = null;
    notifyListeners();
  }
}
