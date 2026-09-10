import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final fcmTokenProvider = StateProvider<String?>((ref) => null);

// Top-level background message handler required by FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Function(String route)? onNotificationNavigation;

  static Future<void> initialize() async {
    try {
      // Firebase initialization
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Local notifications initialization for foreground display
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _handleDeepLink(payload);
          }
        },
      );

      // Create Android Notification Channel
      if (Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important CRM alerts.',
          importance: Importance.high,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // Request FCM permissions
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Retrieve and sync token
        try {
          final token = await _safelyGetFcmToken();
          debugPrint('FCM Registration Token: $token');
          if (token != null) {
            await _syncTokenToSupabase(token);
          }
        } catch (tokenErr) {
          debugPrint('Error getting initial FCM token: $tokenErr');
        }

        // Listen for token refresh
        messaging.onTokenRefresh.listen((newToken) {
          debugPrint('FCM Token Refreshed: $newToken');
          _syncTokenToSupabase(newToken);
        });

        // Listen for foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _showForegroundNotification(message);
        });

        // Handle background tap
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          final route = message.data['route'] as String?;
          if (route != null) {
            _handleDeepLink(route);
          }
        });

        // Handle terminated state launch
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          final route = initialMessage.data['route'] as String?;
          if (route != null) {
            _handleDeepLink(route);
          }
        }
        // Listen for Supabase auth changes to sync token immediately upon login
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
          if (data.session != null) {
            syncCurrentUserToken();
          }
        });
      }
    } catch (e) {
      debugPrint('FCM / Notification initialization error: $e');
    }
  }

  static Future<String?> _safelyGetFcmToken() async {
    final messaging = FirebaseMessaging.instance;
    try {
      if (Platform.isIOS) {
        String? apnsToken = await messaging.getAPNSToken();
        int retries = 0;
        while (apnsToken == null && retries < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          apnsToken = await messaging.getAPNSToken();
          retries++;
        }
        if (apnsToken == null) {
          debugPrint('APNs token not yet available. Will sync when ready.');
          return null;
        }
      }
      return await messaging.getToken();
    } catch (e) {
      debugPrint('Error in _safelyGetFcmToken: $e');
      return null;
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      final route = message.data['route'] as String? ?? '';

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important CRM alerts.',
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: route,
      );
    }
  }

  static Future<void> syncCurrentUserToken() async {
    try {
      final token = await _safelyGetFcmToken();
      if (token != null) {
        await _syncTokenToSupabase(token);
      }
    } catch (e) {
      debugPrint('Error in syncCurrentUserToken: $e');
    }
  }

  static Future<void> _syncTokenToSupabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final platform = Platform.isIOS ? 'ios' : 'android';
        await Supabase.instance.client.from('device_tokens').upsert(
          {
            'user_id': user.id,
            'token': token,
            'platform': platform,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'token',
        );
      }
    } catch (e) {
      debugPrint('Error syncing push token to Supabase: $e');
    }
  }

  static void _handleDeepLink(String route) {
    if (onNotificationNavigation != null) {
      onNotificationNavigation!(route);
    }
  }
}
