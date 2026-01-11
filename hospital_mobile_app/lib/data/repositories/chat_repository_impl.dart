import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

class ChatRepositoryImpl {
  final DioClient _dioClient;

  ChatRepositoryImpl(this._dioClient);

  /// Get all conversations for the current user
  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _dioClient.get(ApiConstants.conversations);
      final data = response.data;
      
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((json) => Conversation.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch conversations: $e');
    }
  }

  /// Get messages for a specific conversation
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.conversationMessages(conversationId),
      );
      final data = response.data;
      
      if (data['success'] == true && data['data'] != null) {
        return (data['data'] as List)
            .map((json) => Message.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  /// Send a text message
  Future<Message?> sendMessage(String conversationId, String content) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.conversationMessages(conversationId),
        data: {'content': content},
      );
      final data = response.data;
      
      if (data['success'] == true && data['data'] != null) {
        return Message.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Start or get existing conversation with a doctor
  Future<Conversation?> startConversation(String doctorId) async {
    try {
      print('[ChatRepo] Starting conversation with doctorId: $doctorId');
      print('[ChatRepo] Endpoint: ${ApiConstants.createConversation}');
      print('[ChatRepo] Full URL: ${ApiConstants.baseUrl}${ApiConstants.createConversation}');
      
      final response = await _dioClient.post(
        ApiConstants.createConversation,
        data: {'participantId': doctorId},
      );
      final data = response.data;
      
      print('[ChatRepo] Response: $data');
      
      if (data['success'] == true && data['data'] != null) {
        return Conversation.fromJson(data['data']);
      }
      return null;
    } on DioException catch (e) {
      print('[ChatRepo] DioException: ${e.type}');
      print('[ChatRepo] Status code: ${e.response?.statusCode}');
      print('[ChatRepo] Response data: ${e.response?.data}');
      print('[ChatRepo] Request path: ${e.requestOptions.path}');
      print('[ChatRepo] Request URL: ${e.requestOptions.uri}');
      throw Exception('Failed to start conversation: ${e.response?.data ?? e.message}');
    } catch (e) {
      print('[ChatRepo] Error: $e');
      throw Exception('Failed to start conversation: $e');
    }
  }

  /// Upload media (image/video) for chat
  Future<Map<String, dynamic>?> uploadMedia(File file) async {
    try {
      final formData = FormData.fromMap({
        'media': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dioClient.post(
        ApiConstants.uploadChatMedia,
        data: formData,
      );
      final data = response.data;
      
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      return null;
    } catch (e) {
      throw Exception('Failed to upload media: $e');
    }
  }

  /// Send message with attachment
  Future<Message?> sendMessageWithAttachment(
    String conversationId,
    String content,
    Map<String, dynamic> attachment,
  ) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.conversationMessages(conversationId),
        data: {
          'content': content,
          'attachments': [attachment],
        },
      );
      final data = response.data;
      
      if (data['success'] == true && data['data'] != null) {
        return Message.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to send message with attachment: $e');
    }
  }
}
