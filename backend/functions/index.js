const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * sendOrderStatusNotification
 * ────────────────────────────────────────────────────────────────────────────
 * Triggers whenever an order document is UPDATED in Firestore.
 * If the 'status' field changed, it looks up the customer's FCM token(s)
 * and sends a high-priority push notification to ALL their devices —
 * even when the phone screen is off or the app is killed.
 */
exports.sendOrderStatusNotification = functions.firestore
  .document("orders/{orderId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const orderId = context.params.orderId;

    // Only act when status actually changed
    if (before.status === after.status) return null;

    const newStatus = after.status;
    const userId = after.userId || after.customerId;
    if (!userId) return null;

    // Build notification title + body based on new status
    const itemName =
      (after.items && after.items.length > 0 && after.items[0].name) ||
      "Equipment";

    const { title, body } = getNotificationContent(newStatus, itemName, orderId);

    // Fetch user document to get FCM token(s)
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    if (!userDoc.exists) return null;

    const userData = userDoc.data();
    const tokens = [];

    // Collect all registered device tokens
    if (userData.fcmToken) tokens.push(userData.fcmToken);
    if (userData.fcmTokens && Array.isArray(userData.fcmTokens)) {
      for (const t of userData.fcmTokens) {
        if (!tokens.includes(t)) tokens.push(t);
      }
    }

    if (tokens.length === 0) {
      console.log(`No FCM tokens for user ${userId}`);
      return null;
    }

    // Build FCM message with high priority (same as WhatsApp)
    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        orderId: orderId,
        status: newStatus,
        type: "order_update",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "eventsphere_high_importance",
          sound: "default",
          priority: "high",
          defaultVibrateTimings: true,
          icon: "ic_launcher",
          color: "#5C1A1A",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            contentAvailable: true,
          },
        },
        headers: {
          "apns-priority": "10",
        },
      },
      tokens: tokens,
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(
        `Sent ${response.successCount} notifications for order ${orderId} (status: ${newStatus})`
      );

      // Remove invalid tokens to keep the list clean
      const invalidTokens = [];
      response.responses.forEach((resp, i) => {
        if (!resp.success) {
          const code = resp.error && resp.error.code;
          if (
            code === "messaging/invalid-registration-token" ||
            code === "messaging/registration-token-not-registered"
          ) {
            invalidTokens.push(tokens[i]);
          }
        }
      });

      if (invalidTokens.length > 0) {
        await admin.firestore().collection("users").doc(userId).update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
        });
      }

      // Also save to Firestore notifications collection (in-app bell icon)
      await admin.firestore().collection("notifications").add({
        userId: userId,
        title: title,
        body: body,
        type: "order_update",
        orderId: orderId,
        read: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: new Date().toISOString(),
      });

      return response;
    } catch (error) {
      console.error("Error sending FCM notification:", error);
      return null;
    }
  });

/**
 * sendNewOrderNotification
 * ────────────────────────────────────────────────────────────────────────────
 * Triggers when a NEW order is CREATED — notifies the vendor.
 */
exports.sendNewOrderNotification = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const vendorId = order.vendorId;
    if (!vendorId) return null;

    const customerName = order.customerName || "A customer";
    const itemName =
      (order.items && order.items.length > 0 && order.items[0].name) ||
      "equipment";

    const title = "🛎️ New Booking Request!";
    const body = `${customerName} wants to rent ${itemName}. Tap to accept or reject.`;

    // Fetch vendor's FCM tokens
    const vendorDoc = await admin
      .firestore()
      .collection("users")
      .doc(vendorId)
      .get();
    if (!vendorDoc.exists) return null;

    const vendorData = vendorDoc.data();
    const tokens = [];
    if (vendorData.fcmToken) tokens.push(vendorData.fcmToken);
    if (vendorData.fcmTokens && Array.isArray(vendorData.fcmTokens)) {
      for (const t of vendorData.fcmTokens) {
        if (!tokens.includes(t)) tokens.push(t);
      }
    }

    if (tokens.length === 0) return null;

    const message = {
      notification: { title, body },
      data: {
        orderId: context.params.orderId,
        type: "new_order",
        click_action: "FLUTTER_NOTIFICATION_CLICK",
      },
      android: {
        priority: "high",
        notification: {
          channelId: "eventsphere_high_importance",
          sound: "default",
          priority: "high",
          defaultVibrateTimings: true,
          color: "#5C1A1A",
        },
      },
      tokens: tokens,
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(
        `New order notification sent to vendor ${vendorId}: ${response.successCount} success`
      );

      // Also save in-app notification for the vendor
      await admin.firestore().collection("notifications").add({
        userId: vendorId,
        title: title,
        body: body,
        type: "new_order",
        orderId: context.params.orderId,
        read: false,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: new Date().toISOString(),
      });

      return response;
    } catch (error) {
      console.error("Error sending new order notification:", error);
      return null;
    }
  });

// ─── Helper: generate notification text per status ────────────────────────────
function getNotificationContent(status, itemName, orderId) {
  const short = orderId.slice(-6).toUpperCase();
  switch (status) {
    case "Placed":
    case "Processing":
      return {
        title: "🎉 Order Confirmed!",
        body: `Your booking for ${itemName} (#${short}) has been placed.`,
      };
    case "Confirmed":
      return {
        title: "✅ Vendor Accepted!",
        body: `Your order for ${itemName} (#${short}) is confirmed.`,
      };
    case "Prepared":
      return {
        title: "📦 Equipment Ready!",
        body: `${itemName} (#${short}) is packed and ready for delivery.`,
      };
    case "Out for Delivery":
      return {
        title: "🚚 Out for Delivery!",
        body: `${itemName} (#${short}) is on the way to your venue.`,
      };
    case "Delivered":
      return {
        title: "🎁 Delivered!",
        body: `${itemName} (#${short}) has been delivered. Enjoy your event!`,
      };
    case "Completed":
      return {
        title: "⭐ Order Completed!",
        body: `Thank you for using EventSphere. Rate your experience!`,
      };
    case "Rejected":
      return {
        title: "❌ Order Rejected",
        body: `Your order for ${itemName} (#${short}) was rejected by the vendor.`,
      };
    case "Return Requested":
      return {
        title: "🔄 Return Requested",
        body: `Return request for ${itemName} (#${short}) sent to vendor.`,
      };
    case "Returned":
      return {
        title: "🤝 Return Confirmed!",
        body: `${itemName} (#${short}) has been picked up. Please rate your experience!`,
      };
    default:
      return {
        title: "📋 Order Update",
        body: `Your order (#${short}) status changed to ${status}.`,
      };
  }
}
