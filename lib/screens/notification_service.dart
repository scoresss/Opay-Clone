import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call this on app start to request permission and save token
  static Future<void> initializeFCM() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Request permission for notifications
    await _messaging.requestPermission();

    // Get device token
    final token = await _messaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': token,
      });
    }

    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final title = message.notification?.title ?? 'Notification';
      final body = message.notification?.body ?? 'You have a new message';

      print("🔔 Push Received: $title - $body");
    });

    // Handle messages when app is opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🔁 App opened from notification");
      // You can navigate to a screen here if needed
    });
  }
}
