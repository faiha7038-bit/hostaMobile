import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseMsg {
  static final FirebaseMsg _instance = FirebaseMsg._internal();
  
  factory FirebaseMsg() {
    return _instance;
  }
  
  FirebaseMsg._internal();

  final FirebaseMessaging msgService = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin localNotifications = 
      FlutterLocalNotificationsPlugin();

  String? _token;

  String? get token => _token;

  Future<String?> initFCM() async {
    if (_token != null) return _token;

    try {
     
      
      if (Firebase.apps.isEmpty) {
       
      } else {
       
      }
      
      await _initializeLocalNotifications();
      await _configurePlatformSettings();

      NotificationSettings settings = await msgService.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
      );
      _token = await _getFcmToken();
    

      if (_token != null) await _saveFCMToken(_token!);

      msgService.onTokenRefresh.listen((newToken) {
      
        _token = newToken;
        _saveFCMToken(newToken);
        _sendTokenToBackend(newToken);
      });

      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

   
      return _token;
    } catch (e) {
     
      return null;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    try {
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

      await localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
        
        },
      );
      
     
    } catch (e) {
     
    }
  }

  Future<void> _configurePlatformSettings() async {
    try {
      // ✅ Now Platform is available because we imported dart:io
      if (Platform.isAndroid) {
        final vibrationPattern = Int64List(5)
          ..[0] = 0
          ..[1] = 500
          ..[2] = 200
          ..[3] = 500
          ..[4] = 0;
        
        final AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          sound: const RawResourceAndroidNotificationSound('notification_sound'),
        );

        await localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
            
      
      }

      await msgService.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      
    } catch (e) {
     
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
    
    } catch (e) {
    
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId != null && userId.isNotEmpty) {
       
      }
    } catch (e) {
    
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
  
    
    if (message.notification != null) {
    
    }
    
    if (message.data.isNotEmpty) {
    
    }

    await _showLocalNotification(message);
  
  }

  Future<String?> _getFcmToken() async {
    for (int i = 0; i < 3; i++) {
      try {
        final token = await msgService.getToken();
        if (token != null && token.isNotEmpty) {
          return token;
        }
      } catch (e) {
      
      }
      await Future.delayed(const Duration(seconds: 2));
    }
    return null;
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    try {
      final vibrationPattern = Int64List(5)
        ..[0] = 0
        ..[1] = 500
        ..[2] = 200
        ..[3] = 500
        ..[4] = 0;

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        styleInformation: BigTextStyleInformation(
          notification.body ?? 'You have a new message',
        ),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000).toInt();
      
      await localNotifications.show(
        id,
        notification.title ?? 'New Notification',
        notification.body ?? 'You have a new message',
        details,
        payload: message.data.isNotEmpty ? message.data.toString() : null,
      );
      
    
    } catch (e) {
      
    }
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
  
    if (message.notification != null) {
    
    }
    if (message.data.isNotEmpty);
  
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseBackgroundMessageHandler(
    RemoteMessage message) async {
    
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    
    }
    
 
    
    final FlutterLocalNotificationsPlugin localNotifications = 
        FlutterLocalNotificationsPlugin();
    
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
    
    await localNotifications.initialize(settings);
    
    if (message.notification != null) {
      try {
        final vibrationPattern = Int64List(5)
          ..[0] = 0
          ..[1] = 500
          ..[2] = 200
          ..[3] = 500
          ..[4] = 0;
          
        final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('notification_sound'),
          enableVibration: true,
          vibrationPattern: vibrationPattern,
          styleInformation: BigTextStyleInformation(
            message.notification?.body ?? 'You have a new message',
          ),
        );
        
        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );
        
        final NotificationDetails details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );
        
        await localNotifications.show(
          DateTime.now().millisecondsSinceEpoch.remainder(100000).toInt(),
          message.notification?.title ?? 'New Notification',
          message.notification?.body ?? 'You have a new message',
          details,
        );
        
    
      } catch (error) {
      
      }
    }
    
   
  }
}