import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static String? _fcmToken;
  static String? _userId;
  
  static Future<void> initialize() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      await _initializeLocalNotifications();
      
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('userId');
      
      await _getAndSaveToken();
      
      _setupMessageListeners();
      
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
      
    } catch (e) {
      // Handle error silently
    }
  }
  
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
    
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications',
      importance: Importance.max,
    );
    
    final plugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.createNotificationChannel(channel);
  }
  
  static Future<void> _getAndSaveToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcmToken', _fcmToken!);
        await _sendTokenToBackend(_fcmToken!);
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      // TODO: Call your backend API to save FCM token
      // final apiService = ApiService();
      // await apiService.saveFCMToken(_userId, token);
    } catch (e) {
      // Handle error silently
    }
  }
  
  static void _setupMessageListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });
    
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });
  }
  
  static void _handleMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'New Notification',
        body: notification.body ?? 'You have a new notification',
        payload: data.toString(),
      );
    }
  }
  
  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notifications = prefs.getStringList('notifications') ?? [];
    
    notifications.insert(0, message.data.toString());
    await prefs.setStringList('notifications', notifications);
  }
  
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
  
  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      // TODO: Navigate to notification screen
      // navigatorKey.currentState?.pushNamed('/notifications');
    }
  }
  
  static Future<String?> getToken() async {
    if (_fcmToken == null) {
      await _getAndSaveToken();
    }
    return _fcmToken;
  }
  
  static Future<void> refreshToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcmToken', _fcmToken!);
        await _sendTokenToBackend(_fcmToken!);
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  static Future<void> testSelfNotification() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('fcmToken');
    
    if (token == null) {
      return;
    }
    
    await _showLocalNotification(
      title: '🔔 FCM Test Notification',
      body: 'Your FCM token is ready to use!',
      payload: 'test_payload',
    );
  }
  
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
      // Handle error silently
    }
  }
  
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
      // Handle error silently
    }
  }
  
  static Future<void> sendTestNotification() async {
    try {
      // TODO: Call your backend API to send test notification
      // final apiService = ApiService();
      // await apiService.sendTestNotification(userId);
    } catch (e) {
      // Handle error silently
    }
  }
}