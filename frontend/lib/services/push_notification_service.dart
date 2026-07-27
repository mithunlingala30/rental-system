import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ─── Background message handler (must be top-level) ──────────────────────────
// Called by FCM when app is in BACKGROUND or TERMINATED (killed/screen off)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Show local notification when app is in background/killed
  await PushNotificationService._showLocalNotification(message);
}

// ─── Android notification channel ────────────────────────────────────────────
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'eventsphere_high_importance', // id
  'EventSphere Notifications',   // name
  description: 'Order updates and alerts from EventSphere',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

// ─── Push Notification Service ────────────────────────────────────────────────
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Initialize FCM — call once from main() after Firebase.initializeApp()
  Future<void> initialize() async {
    if (kIsWeb) return; // FCM on web uses a different flow

    // 1. Set the background handler (must be registered before any other setup)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request permissions (Android 13+ and iOS require explicit permission)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: false,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    // 3. Create the high-importance Android notification channel
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 4. Initialize flutter_local_notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false, // Already requested via FCM
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(initSettings);

    // 5. Show heads-up notification when app is in FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // 6. Save this device's FCM token to Firestore so the server can target it
    await _saveTokenToFirestore();

    // 7. Refresh token if it rotates
    _fcm.onTokenRefresh.listen((newToken) async {
      await _saveTokenToFirestore(token: newToken);
    });
  }

  /// Save the FCM token to Firestore under the current user's document
  Future<void> _saveTokenToFirestore({String? token}) async {
    try {
      if (kIsWeb) return;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final fcmToken = token ?? await _fcm.getToken();
      if (fcmToken == null) return;

      await _db.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([fcmToken]),
        'fcmToken': fcmToken, // Latest token (convenience field)
      }, SetOptions(merge: true));
      debugPrint('FCM token saved: $fcmToken');
    } catch (e) {
      debugPrint('Warning: Could not save FCM token to Firestore: $e');
    }
  }

  /// Called when user logs in — saves the token for the newly authenticated user
  Future<void> onUserLogin() async {
    try {
      await _saveTokenToFirestore();
    } catch (e) {
      debugPrint('Warning: Error in onUserLogin push notification setup: $e');
    }
  }

  /// Show a local notification (heads-up banner with sound + vibration)
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;
    final title = notification?.title ?? message.data['title'] ?? 'EventSphere';
    final body = notification?.body ?? message.data['body'] ?? '';

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          color: const Color(0xFF5C1A1A),
          playSound: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Save notification to Firestore (for the in-app Notifications screen)
  Future<void> saveNotificationToFirestore({
    required String userId,
    required String title,
    required String body,
    String type = 'order_update',
    String? orderId,
  }) async {
    try {
      await _db.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'orderId': orderId,
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Warning: Could not save notification to Firestore: $e');
    }
  }

  /// Stream of saved notifications for a user (in-app Notifications screen)
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list =
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      list.sort((a, b) {
        final aTime = a['createdAt'] as String? ?? '';
        final bTime = b['createdAt'] as String? ?? '';
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  /// Stream of unread notification count for the badge on the home screen
  Stream<int> getUnreadNotificationCount(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
