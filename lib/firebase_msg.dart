import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseMsg {
  // Singleton pattern with factory constructor
  static final FirebaseMsg _instance = FirebaseMsg._internal();
  
  factory FirebaseMsg() {
    return _instance;
  }
  
  FirebaseMsg._internal();

  final FirebaseMessaging msgService = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

  String? _token; // cached FCM token

  /// Global getter for the token
  String? get token => _token;

  /// Initialize FCM and local notifications
  Future<String?> initFCM() async {
    if (_token != null) return _token; // already initialized

    try {
      print('🔍 DEBUG: Starting FCM initialization...');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions
      NotificationSettings settings = await msgService.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
      );

      print('🔍 DEBUG: Notification permission: ${settings.authorizationStatus}');

      // Configure platform-specific settings
      await _configurePlatformSettings();

      // Get FCM token
      _token = await msgService.getToken();
      print('🪙 TOKEN DEBUG - FCM Token: ${_token ?? "NULL"}');

      // Save token locally
      if (_token != null) await _saveFCMToken(_token!);

      // Listen for token refresh
      msgService.onTokenRefresh.listen((newToken) {
        print('🔄 TOKEN REFRESHED: $newToken');
        _token = newToken;
        _saveFCMToken(newToken);
        _sendTokenToBackend(newToken);
      });

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      print('✅ DEBUG: FCM initialization completed');
      return _token;
    } catch (e) {
      print('❌ ERROR in FCM initialization: $e');
      return null;
    }
  }

  

  // ================== Private Methods ==================

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await localNotifications.initialize(settings);
  }

  Future<void> _configurePlatformSettings() async {
    // Android: create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // iOS: foreground notification presentation
    await msgService.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _saveFCMToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
    print('💾 FCM Token saved locally: $token');
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId != null && userId.isNotEmpty) {
        print('🚀 Sending FCM token to backend: $token');
        // TODO: Call your backend API here
        // await ApiService().updateFCMToken(userId, token);
      }
    } catch (e) {
      print('❌ Error sending token to backend: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('\n📱 FOREGROUND MESSAGE RECEIVED');
    print('📱 Message ID: ${message.messageId}');
    print('📱 From: ${message.from}');
    print('📱 Sent Time: ${message.sentTime}');
    if (message.notification != null) {
      print('📱 Notification - Title: ${message.notification!.title}');
      print('📱 Notification - Body: ${message.notification!.body}');
    }
    if (message.data.isNotEmpty) print('📱 Data payload: ${message.data}');

    // Show local notification
    await _showLocalNotification(message);
    print('📱 END OF FOREGROUND MESSAGE\n');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      notification.title ?? 'New Notification',
      notification.body ?? 'You have a new message',
      details,
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('\n📱 MESSAGE OPENED APP');
    print('📱 Message ID: ${message.messageId}');
    if (message.notification != null) {
      print('📱 Notification - Title: ${message.notification!.title}');
      print('📱 Notification - Body: ${message.notification!.body}');
    }
    if (message.data.isNotEmpty) print('📱 Data payload: ${message.data}');
    print('📱 END OF MESSAGE OPENED\n');
  }

  // ================== Background Handler ==================
  @pragma('vm:entry-point')
  static Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
    print('\n📱 BACKGROUND MESSAGE RECEIVED');
    print('📱 Message ID: ${message.messageId}');
    print('📱 From: ${message.from}');
    print('📱 Sent Time: ${message.sentTime}');

    final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await localNotifications.initialize(settings);

    if (message.notification != null) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        message.notification?.title ?? 'New Notification',
        message.notification?.body ?? 'You have a new message',
        details,
      );
    }

    if (message.data.isNotEmpty) print('📱 Data payload: ${message.data}');
    print('📱 END OF BACKGROUND MESSAGE\n');
  }
}