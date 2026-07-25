// This file re-exports the unified PushNotificationService.
// Kept for backward compatibility — screens that import NotificationService
// should migrate to PushNotificationService directly.
export 'push_notification_service.dart' show PushNotificationService;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'push_notification_service.dart';

/// Legacy wrapper — delegates to PushNotificationService.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _orderSubscription;
  final Map<String, String> _lastKnownStatuses = {};

  Future<void> initialize() async {
    await PushNotificationService().initialize();
    listenToOrderUpdates();
  }

  /// Real-time listener for order status changes → writes notification to Firestore
  /// The Firebase Cloud Function (functions/index.js) then sends the FCM push.
  void listenToOrderUpdates() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _orderSubscription?.cancel();
    _orderSubscription = _db
        .collection('orders')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final orderId = doc.id;
        final status = data['status'] as String? ?? 'Processing';
        final items = data['items'] as List<dynamic>? ?? [];
        final itemName = items.isNotEmpty
            ? (items.first['name'] ?? 'Equipment')
            : 'Equipment';

        if (_lastKnownStatuses.containsKey(orderId)) {
          final oldStatus = _lastKnownStatuses[orderId];
          if (oldStatus != status) {
            _handleStatusChange(
              userId: currentUser.uid,
              orderId: orderId,
              status: status,
              itemName: itemName as String,
            );
          }
        }
        _lastKnownStatuses[orderId] = status;
      }
    });
  }

  void _handleStatusChange({
    required String userId,
    required String orderId,
    required String status,
    required String itemName,
  }) {
    String title = 'Order Update';
    String body = 'Your order status changed to $status.';

    switch (status) {
      case 'Processing':
      case 'Placed':
        title = '🎉 Order Confirmed!';
        body = 'Your booking for $itemName has been placed successfully.';
        break;
      case 'Confirmed':
        title = '✅ Vendor Accepted!';
        body = 'The vendor confirmed your booking for $itemName.';
        break;
      case 'Prepared':
        title = '📦 Equipment Prepared!';
        body = '$itemName is ready for delivery.';
        break;
      case 'Out for Delivery':
        title = '🚚 Out for Delivery!';
        body = '$itemName is on the way to your venue.';
        break;
      case 'Delivered':
        title = '🎁 Delivered!';
        body = 'Your equipment $itemName has been delivered.';
        break;
      case 'Completed':
        title = '⭐ Order Completed!';
        body = 'Thank you for using EventSphere!';
        break;
      case 'Rejected':
        title = '❌ Order Rejected';
        body = 'Your order for $itemName was rejected by the vendor.';
        break;
    }

    // Save to Firestore — the Cloud Function will deliver the FCM push
    PushNotificationService().saveNotificationToFirestore(
      userId: userId,
      title: title,
      body: body,
      orderId: orderId,
    );
  }

  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return PushNotificationService().getUserNotifications(userId);
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'order_update',
    String? orderId,
  }) async {
    await PushNotificationService().saveNotificationToFirestore(
      userId: userId,
      title: title,
      body: body,
      type: type,
      orderId: orderId,
    );
  }

  void dispose() {
    _orderSubscription?.cancel();
  }
}
