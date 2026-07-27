import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/order_model.dart';
import '../models/user_model.dart';
import 'notification_service.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Orders ────────────────────────────────────────────────────────────────
  
  Future<String> placeOrder(OrderModel order) async {
    final docRef = _db.collection('orders').doc();
    final uid = _auth.currentUser?.uid ?? '';
    final orderWithId = order.toMap();
    orderWithId['id'] = docRef.id;
    orderWithId['customerId'] = order.customerId.isNotEmpty ? order.customerId : uid;
    await docRef.set(orderWithId);

    // Send push notification & save to Notifications screen
    if (uid.isNotEmpty) {
      final itemName = order.items.isNotEmpty ? order.items.first.name : 'Event Equipment';
      try {
        await NotificationService().sendNotification(
          userId: uid,
          title: '🎉 Order Placed Successfully!',
          body: 'Your booking for $itemName has been submitted. Awaiting vendor confirmation.',
          orderId: docRef.id,
        );
      } catch (e) {
        // Log notification error without stopping order creation success
      }
    }
    return docRef.id;
  }


  Stream<OrderModel?> getOrderByIdStream(String orderId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? OrderModel.fromMap(doc.data()!, doc.id) : null);
  }

  /// Orders that belong to this vendor — filtered and sorted client-side to avoid
  /// needing a Firestore composite index on (vendorId + createdAt), and to allow
  /// testing with mock or unassigned vendor IDs.

  /// Orders that belong to the logged-in customer.
  /// Matches on the `customerId` field (UID stored at order-placement time).
  Stream<List<OrderModel>> getCustomerOrders(String uid) {
    if (uid.isEmpty) return Stream.value([]);
    return _db.collection('orders').snapshots().map((s) {
      final list = s.docs
          .map((d) => OrderModel.fromMap(d.data(), d.id))
          .where((o) => o.customerId == uid)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Orders that belong to the specified vendor.
  Stream<List<OrderModel>> getOrdersForVendor(String vendorId) {
    if (vendorId.isEmpty) return Stream.value([]);
    return _db.collection('orders').snapshots().map((s) {
      final list = s.docs
          .map((d) => OrderModel.fromMap(d.data(), d.id))
          .where((o) => o.vendorId == vendorId)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({'status': status});
  }

  Future<void> acceptOrder(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'status': 'Confirmed',
      'trackingStep': 1,
    });
    final doc = await _db.collection('orders').doc(orderId).get();
    final customerId = doc.data()?['customerId'] ?? doc.data()?['userId'] ?? '';
    if (customerId.isNotEmpty) {
      await NotificationService().sendNotification(
        userId: customerId,
        title: '✅ Order Confirmed!',
        body: 'Vendor accepted your booking request.',
        orderId: orderId,
      );
    }
  }

  Future<void> rejectOrder(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'status': 'Rejected',
    });
    final doc = await _db.collection('orders').doc(orderId).get();
    final customerId = doc.data()?['customerId'] ?? doc.data()?['userId'] ?? '';
    if (customerId.isNotEmpty) {
      await NotificationService().sendNotification(
        userId: customerId,
        title: '❌ Order Rejected',
        body: 'Your booking request was rejected by vendor.',
        orderId: orderId,
      );
    }
  }

  Future<void> updateTracking(String orderId, int step, String note) async {
    final statuses = [
      'Processing',
      'Confirmed',
      'Prepared',
      'Out for Delivery',
      'Delivered',
    ];
    final status = statuses[step.clamp(0, 4)];
    await _db.collection('orders').doc(orderId).update({
      'trackingStep': step,
      'trackingNote': note,
      'status': status,
    });

    final doc = await _db.collection('orders').doc(orderId).get();
    final customerId = doc.data()?['customerId'] ?? doc.data()?['userId'] ?? '';
    if (customerId.isNotEmpty) {
      final titleMap = {
        'Prepared': '📦 Equipment Prepared!',
        'Out for Delivery': '🚚 Out for Delivery!',
        'Delivered': '🎁 Order Delivered!',
      };
      await NotificationService().sendNotification(
        userId: customerId,
        title: titleMap[status] ?? '📦 Order Status: $status',
        body: note.isNotEmpty ? note : 'Your order is now $status.',
        orderId: orderId,
      );
    }
  }

  /// Mark an order as delivered (via PIN confirmation).
  Future<void> markDelivered(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'status': 'Delivered',
      'trackingStep': 4,
    });
    final doc = await _db.collection('orders').doc(orderId).get();
    final customerId = doc.data()?['customerId'] ?? doc.data()?['userId'] ?? '';
    if (customerId.isNotEmpty) {
      await NotificationService().sendNotification(
        userId: customerId,
        title: '🎁 Order Delivered!',
        body: 'Equipment handed over and set up. Enjoy your event!',
        orderId: orderId,
      );
    }
  }

  /// Customer requests a return of the rented equipment.
  Future<void> requestReturn(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'returnRequested': true,
      'status': 'Return Requested',
    });
    final doc = await _db.collection('orders').doc(orderId).get();
    final vendorId = doc.data()?['vendorId'] ?? '';
    if (vendorId.isNotEmpty) {
      await NotificationService().sendNotification(
        userId: vendorId,
        title: '🔄 Return Pickup Requested',
        body: 'Customer is ready to return equipment for order #${orderId.substring(0, 8).toUpperCase()}.',
        orderId: orderId,
      );
    }
  }

  /// Vendor confirms the items were returned.
  Future<void> confirmReturn(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'returnConfirmed': true,
      'status': 'Returned',
    });
    final doc = await _db.collection('orders').doc(orderId).get();
    final customerId = doc.data()?['customerId'] ?? doc.data()?['userId'] ?? '';
    if (customerId.isNotEmpty) {
      await NotificationService().sendNotification(
        userId: customerId,
        title: '🤝 Return Confirmed!',
        body: 'Vendor confirmed equipment return. Please rate your experience!',
        orderId: orderId,
      );
    }
  }

  /// Customer rates the order (1-5 stars).
  Future<void> rateOrder(String orderId, double rating) async {
    await _db.collection('orders').doc(orderId).update({
      'rating': rating,
      'status': 'Completed',
    });
    final doc = await _db.collection('orders').doc(orderId).get();
    final vendorId = doc.data()?['vendorId'] ?? '';
    if (vendorId.isNotEmpty) {
      await NotificationService().sendNotification(
        userId: vendorId,
        title: '⭐ New Rating Received!',
        body: 'Customer rated order #${orderId.substring(0, 8).toUpperCase()} with ${rating.toStringAsFixed(0)} stars.',
        orderId: orderId,
      );
    }
  }

  // ─── Equipment (Example) ───────────────────────────────────────────────────
  
  Stream<List<Map<String, dynamic>>> getEquipment() {
    return _db.collection('equipment').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> getEquipmentByVendor(String vendorId) {
    return _db.collection('equipment').where('vendorId', isEqualTo: vendorId).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Stream<List<UserModel>> getVendorsByCity(String city) {
    return _db.collection('users').where('role', isEqualTo: 'Vendor').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => UserModel.fromMap(doc.id, doc.data())).toList();
      if (city.isEmpty) return list;
      final q = city.toLowerCase();
      return list.where((u) => u.location.toLowerCase().contains(q)).toList();
    });
  }

  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  // ─── User Profile ──────────────────────────────────────────────────────────

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      // Create a default profile if it doesn't exist
      final newUser = UserModel(
        id: user.uid,
        name: user.displayName ?? 'New User',
        email: user.email ?? '',
        phone: '',
        location: 'Not set',
        createdAt: DateTime.now(),
      );
      await updateUserProfile(newUser);
      return newUser;
    }
    return UserModel.fromMap(doc.id, doc.data()!);
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Stream<UserModel?> userProfileStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _db.collection('users').doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.id, doc.data()!);
    });
  }

  Future<void> addEquipment(Map<String, dynamic> item) async {
    await _db.collection('equipment').add(item);
  }

  Future<void> updateEquipment(String id, Map<String, dynamic> item) async {
    await _db.collection('equipment').doc(id).set(item, SetOptions(merge: true));
  }

  Future<void> deleteEquipment(String id) async {
    await _db.collection('equipment').doc(id).delete();
  }

  Future<Map<String, dynamic>?> getEquipmentById(String id) async {
    try {
      final doc = await _db.collection('equipment').doc(id).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      return null;
    }
  }


  // ─── Chat System ─────────────────────────────────────────────────────────────
  
  String getChatId(String uid1, String uid2) {
    final ids = [uid1, uid2];
    ids.sort();
    return ids.join('_');
  }

  Stream<List<Map<String, dynamic>>> getUserChats(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
          list.sort((a, b) {
            final timeA = a['lastMessageTime'] as String? ?? '';
            final timeB = b['lastMessageTime'] as String? ?? '';
            return timeB.compareTo(timeA);
          });
          return list;
        });
  }

  Stream<List<Map<String, dynamic>>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> sendMessage({
    required String uid1,
    required String uid2,
    required String text,
    required String senderName,
    required String receiverName,
    Map<String, dynamic>? replyTo,
  }) async {
    final chatId = getChatId(uid1, uid2);
    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();

    final now = DateTime.now().toIso8601String();

    await _db.runTransaction((tx) async {
      final chatDoc = await tx.get(chatRef);
      if (!chatDoc.exists) {
        tx.set(chatRef, {
          'participants': [uid1, uid2],
          'participantNames': {uid1: senderName, uid2: receiverName},
          'lastMessage': text,
          'lastMessageTime': now,
        });
      } else {
        tx.update(chatRef, {
          'lastMessage': text,
          'lastMessageTime': now,
          'participantNames.$uid1': senderName,
          'participantNames.$uid2': receiverName,
        });
      }

      tx.set(msgRef, {
        'senderId': uid1,
        'text': text,
        'timestamp': now,
        'readBy': [uid1],
        if (replyTo != null) 'replyTo': replyTo,
      });
    });
  }

  Future<void> markMessagesRead(String chatId, String uid) async {
    final snapshot = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('readBy', whereNotIn: [[uid]])
        .get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      final readBy = List<String>.from(doc.data()['readBy'] as List? ?? []);
      if (!readBy.contains(uid)) {
        batch.update(doc.reference, {
          'readBy': [...readBy, uid],
        });
      }
    }
    await batch.commit();
  }

  Future<void> clearChatMessages(String chatId) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final messagesSnapshot = await chatRef.collection('messages').get();

    final batch = _db.batch();
    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.update(chatRef, {
      'lastMessage': '',
      'lastMessageTime': DateTime.now().toIso8601String(),
    });

    await batch.commit();
  }

  Future<void> deleteChat(String chatId) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final messagesSnapshot = await chatRef.collection('messages').get();

    final batch = _db.batch();
    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(chatRef);

    await batch.commit();
  }
}

