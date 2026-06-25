import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/school_models.dart';
import 'supabase_service.dart';

class CommunicationService {
  static final CommunicationService _instance = CommunicationService._internal();
  factory CommunicationService() => _instance;
  CommunicationService._internal();

  // The stream now comes directly from Supabase for cloud-wide sync
  Stream<List<Map<String, dynamic>>> get notificationStream => SupabaseService.instance.notificationStream;

  Future<void> sendNotification(Map<String, dynamic> notificationData) async {
    try {
      // 1. Post to Supabase Cloud
      await SupabaseService.instance.postAnnouncement(
        notificationData['title'],
        notificationData['message'],
        notificationData['target_role'],
      );
      
      // 2. Simulated External Gateway (SMS/Email)
      _dispatchExternal(notificationData);
    } catch (e) {
      debugPrint("Error sending notification: $e");
    }
  }

  Future<void> broadcastNotification(NotificationModel notification) async {
    await sendNotification({
      'title': notification.title,
      'message': notification.message,
      'target_role': notification.targetRole,
    });
  }

  void _dispatchExternal(Map<String, dynamic> notification) {
    debugPrint('--- CLOUD COMMUNICATION GATEWAY ---');
    debugPrint('TO: ${notification['target_role']}');
    debugPrint('SUBJECT: ${notification['title']}');
    debugPrint('----------------------------------');
  }

  /// Direct Message to specific user or role
  Future<void> sendMessage({
    required String senderId,
    required String targetId,
    required String targetRole,
    required String title,
    required String message,
  }) async {
    await SupabaseService.instance.client.from('notifications').insert({
      'title': title,
      'message': message,
      'target_role': targetRole,
      'target_id': targetId,
      'sender_id': senderId,
    });
  }

  /// Get messages received by a specific user from Cloud
  Future<List<NotificationModel>> getMyMessages(String userId, String role) async {
    try {
      final result = await SupabaseService.instance.getNotifications(role);
      return result.map((json) => NotificationModel.fromMap(json)).toList();
    } catch (e) {
      debugPrint("Error fetching messages: $e");
      return [];
    }
  }
}
