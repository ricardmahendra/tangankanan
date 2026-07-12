import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../pocketbase/pb.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('Notification permission status: ${settings.authorizationStatus}');
    }

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(initializationSettings);

    // Get FCM token
    String? token = await _messaging.getToken();
    if (token != null) {
      await _saveFcmToken(token);
      if (kDebugMode) print('FCM Token: $token');
    }

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _saveFcmToken(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });
  }

  // Save FCM token to PocketBase
  Future<void> _saveFcmToken(String token) async {
    try {
      final record = pb.authStore.record;
      if (record != null) {
        final userId = record.id;
        final collectionName = record.collectionName;
        
        // Update user or partner with FCM token
        await pb.collection(collectionName).update(userId, body: {
          'fcm_token': token,
        });
      }
    } catch (e) {
      if (kDebugMode) print('Failed to save FCM token: $e');
    }
  }

  // Show local notification when app is in foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'tangankanan_channel',
      'TanganKanan Notifications',
      channelDescription: 'Notifications for TanganKanan app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      message.notification?.hashCode ?? 0,
      message.notification?.title ?? 'TanganKanan',
      message.notification?.body ?? '',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    // Navigate based on notification type
    final type = message.data['type'];
    final id = message.data['id'];

    if (kDebugMode) {
      print('Notification tapped: type=$type, id=$id');
    }

    // Navigation logic will be handled by the app using go_router
    // This is just a placeholder for the logic
  }

  // Subscribe to topic (for role-based notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) print('Subscribed to topic: $topic');
    } catch (e) {
      if (kDebugMode) print('Failed to subscribe to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) print('Unsubscribed from topic: $topic');
    } catch (e) {
      if (kDebugMode) print('Failed to unsubscribe from topic: $e');
    }
  }
}
