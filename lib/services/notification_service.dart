import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background notification received: ${message.messageId}');
}

class NotificationService {
  static const String _webVapidKey =
      'BOM_Ci9qdwttK05bn8h1MW176GN8FXU7VyhJC4nDpWRD1Hl3i73JmwlEUF-3w1jrUYqMgEtrHd3P0wEAAQt9ph4';

  static Future<void> initialize() async {
    if (Firebase.apps.isEmpty) return;

    final messaging = FirebaseMessaging.instance;
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Web notifications were denied by the user.');
      return;
    }

    final token = kIsWeb
        ? await messaging.getToken(vapidKey: _webVapidKey)
        : await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _saveToken(token);
    }

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground notification received: ${message.notification?.title}');
    });

    messaging.onTokenRefresh.listen((newToken) {
      _saveToken(newToken);
    });
  }

  static Future<void> _saveToken(String token) async {
    final tokenId = base64Url.encode(utf8.encode(token));
    await FirebaseFirestore.instance.collection('notification_tokens').doc(tokenId).set({
      'token': token,
      'platform': kIsWeb ? 'web' : 'android',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
