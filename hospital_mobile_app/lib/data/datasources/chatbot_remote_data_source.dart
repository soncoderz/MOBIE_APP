import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/chatbot_model.dart';

abstract class ChatbotRemoteDataSource {
  Future<ChatbotResponseModel> sendMessage(String message);
  Future<List<ChatbotMessageModel>> getChatHistory();
  Future<void> clearChatHistory();
}

class ChatbotRemoteDataSourceImpl implements ChatbotRemoteDataSource {
  final DioClient _dioClient;

  ChatbotRemoteDataSourceImpl(this._dioClient);

  @override
  Future<ChatbotResponseModel> sendMessage(String message) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.chatbotMessage,
        data: {'message': message},
      );

      if (response.statusCode == 200) {
        return ChatbotResponseModel.fromJson(response.data);
      } else {
        throw ServerException('Gửi tin nhắn thất bại');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Gửi tin nhắn thất bại: ${e.toString()}');
    }
  }

  @override
  Future<List<ChatbotMessageModel>> getChatHistory() async {
    try {
      final response = await _dioClient.get(ApiConstants.chatbotHistory);

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        final List<dynamic> messages = data['messages'] ?? [];
        return messages
            .map((json) => ChatbotMessageModel.fromJson(json))
            .toList();
      } else {
        throw ServerException('Lấy lịch sử chat thất bại');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Lấy lịch sử chat thất bại: ${e.toString()}');
    }
  }

  @override
  Future<void> clearChatHistory() async {
    try {
      final response = await _dioClient.delete(ApiConstants.chatbotHistory);

      if (response.statusCode != 200) {
        throw ServerException('Xóa lịch sử chat thất bại');
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Xóa lịch sử chat thất bại: ${e.toString()}');
    }
  }
}
