import 'dart:html' as html;

Future<bool> requestWebNotificationPermission() async {
  try {
    if (html.Notification.permission != 'granted') {
      final res = await html.Notification.requestPermission();
      return res == 'granted';
    }
  } catch (_) {}
  return true;
}

void showWebNotification({required String title, required String body}) {
  try {
    if (html.Notification.permission == 'granted') {
      html.Notification(
        title,
        body: body,
        icon: '/icons/Icon-192.png',
      );
    }
  } catch (_) {}
}
