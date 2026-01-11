import '../datasources/chatbot_remote_data_source.dart';
import '../models/chatbot_model.dart';

abstract class ChatbotRepository {
  Future<ChatbotResponseModel> sendMessage(String message);
  Future<List<ChatbotMessageModel>> getChatHistory();
  Future<void> clearChatHistory();
}

class ChatbotRepositoryImpl implements ChatbotRepository {
  final ChatbotRemoteDataSource _remoteDataSource;

  ChatbotRepositoryImpl(this._remoteDataSource);

  @override
  Future<ChatbotResponseModel> sendMessage(String message) async {
    return await _remoteDataSource.sendMessage(message);
  }

  @override
  Future<List<ChatbotMessageModel>> getChatHistory() async {
    return await _remoteDataSource.getChatHistory();
  }

  @override
  Future<void> clearChatHistory() async {
    await _remoteDataSource.clearChatHistory();
  }
}
