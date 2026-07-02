

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static String? _fcmToken;
  static String? _userId;
  
  // Initialize FCM
  static Future<void> initialize() async {
    try {
      print('🚀 Initializing FCM Service...');
      
      // 1. Request permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      print('📱 Permission status: ${settings.authorizationStatus}');
      
      // 2. Initialize local notifications
      await _initializeLocalNotifications();
      
      // 3. Get userId
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('userId');
      
      // 4. Get and save FCM token
      await _getAndSaveToken();
      
      // 5. Setup message listeners
      _setupMessageListeners();
      
      // 6. Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      
      print('✅ FCM Service initialized successfully');
      
    } catch (e) {
      print('❌ FCM initialization error: $e');
    }
  }
  
  // ✅ FIXED: Initialize local notifications - SoundResource removed
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    
    // ✅ FIXED: SoundResource നീക്കം ചെയ്തു
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.max,
      // sound: SoundResource('default'), // ❌ ഇത് നീക്കം ചെയ്യുക
    );
    
    final plugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.createNotificationChannel(channel);
  }
  
  // Get and save FCM token
  static Future<void> _getAndSaveToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcmToken', _fcmToken!);
        
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📱 FCM Token:');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print(_fcmToken);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        
        // Send token to backend
        await _sendTokenToBackend(_fcmToken!);
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }
  
  // Send token to backend
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      // TODO: Call your backend API to save FCM token
      // final apiService = ApiService();
      // await apiService.saveFCMToken(_userId, token);
      
      print('📤 Sending token to backend...');
      // await apiService.saveFCMToken(_userId, token);
      
    } catch (e) {
      print('❌ Error sending token to backend: $e');
    }
  }
  
  // Setup message listeners
  static void _setupMessageListeners() {
    // Foreground message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Received foreground message: ${message.notification?.title}');
      _handleMessage(message);
    });
    
    // Background message (when app is in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📨 App opened from notification: ${message.notification?.title}');
      _handleMessage(message);
    });
  }
  
  // Handle message
  static void _handleMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    
    print('📨 Notification Data: $data');
    
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'New Notification',
        body: notification.body ?? 'You have a new notification',
        payload: data.toString(),
      );
    }
  }
  
  // Handle background messages
  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('📨 Background message: ${message.notification?.title}');
    
    // Save notification to local storage if needed
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList('notifications') ?? [];
    
    notifications.insert(0, message.data.toString());
    await prefs.setStringList('notifications', notifications);
  }
  
  // ✅ FIXED: Show local notification - SoundResource removed
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      // ✅ FIXED: SoundResource നീക്കം ചെയ്തു (default sound വരും)
      // sound: SoundResource('default'), // ❌ ഇത് നീക്കം ചെയ്യുക
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
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000).toInt(),
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  // Notification tap handler
  static void _onNotificationTap(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    
    // Navigate to notification details
    if (response.payload != null) {
      // TODO: Navigate to notification screen
      // navigatorKey.currentState?.pushNamed('/notifications');
    }
  }
  
  // Get FCM token
  static Future<String?> getToken() async {
    if (_fcmToken == null) {
      await _getAndSaveToken();
    }
    return _fcmToken;
  }
  
  // Refresh token
  static Future<void> refreshToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcmToken', _fcmToken!);
        await _sendTokenToBackend(_fcmToken!);
        print('🔄 FCM token refreshed');
      }
    } catch (e) {
      print('❌ Error refreshing token: $e');
    }
  }
  
  // Test self notification
  static Future<void> testSelfNotification() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('fcmToken');
    
    if (token == null) {
      print('⚠️ No token found. Please call initialize() first.');
      return;
    }
    
    print('═══════════════════════════════════════════════════');
    print('📱 YOUR FCM TOKEN (Share with backend team):');
    print('═══════════════════════════════════════════════════');
    print(token);
    print('═══════════════════════════════════════════════════');
    
    // Show local test notification
    await _showLocalNotification(
      title: '🔔 FCM Test Notification',
      body: 'Your FCM token is ready to use!',
      payload: 'test_payload',
    );
  }
  
  // ✅ Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('📡 Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }
  
  // ✅ Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('📡 Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }
  
  // Send test notification via backend (for debugging)
  static Future<void> sendTestNotification() async {
    try {
      // TODO: Call your backend API to send test notification
      // final apiService = ApiService();
      // await apiService.sendTestNotification(userId);
      
      print('📤 Sending test notification...');
      
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }
}