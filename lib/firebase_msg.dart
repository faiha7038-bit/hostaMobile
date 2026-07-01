// import 'dart:typed_data';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class FirebaseMsg {
//   // Singleton pattern with factory constructor
//   static final FirebaseMsg _instance = FirebaseMsg._internal();
  
//   factory FirebaseMsg() {
//     return _instance;
//   }
  
//   FirebaseMsg._internal();

//   final FirebaseMessaging msgService = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

//   String? _token; // cached FCM token

//   /// Global getter for the token
//   String? get token => _token;

//   /// Initialize FCM and local notifications
//   Future<String?> initFCM() async {
//     if (_token != null) return _token; // already initialized


// //  if (Firebase.apps.isEmpty) {
// //      await Firebase.initializeApp();
// //    // print('⚠️ No Firebase app, but continuing anyway...');
// //     // Don't initialize here - let the platform handle it
// //   }

//     try {
//       print('🔍 DEBUG: Starting FCM initialization...');
//  try {
//       if (Firebase.apps.isEmpty) {
//         // This should not happen, but just in case
//         print('⚠️ No Firebase app found, initializing...');
//         // You might need to add firebase_options.dart import
//         // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//       } else {
//         print('✅ Firebase app already exists: ${Firebase.apps.first.name}');
//       }
//     } catch (e) {
//       print('⚠️ Firebase check error: $e');
//     }
//       // Initialize local notifications
//       await _initializeLocalNotifications();

//       // Request permissions
//       NotificationSettings settings = await msgService.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//         provisional: false,
//         criticalAlert: true,
//       );

//       print('🔍 DEBUG: Notification permission: ${settings.authorizationStatus}');

//       // Configure platform-specific settings
//       await _configurePlatformSettings();

//       // Get FCM token
//       // Get FCM token with retry
// _token = await _getFcmToken();
// print('🪙 TOKEN DEBUG - FCM Token: ${_token ?? "NULL"}');

//       // Save token locally
//       if (_token != null) await _saveFCMToken(_token!);

//       // Listen for token refresh
//       msgService.onTokenRefresh.listen((newToken) {
//         print('🔄 TOKEN REFRESHED: $newToken');
//         _token = newToken;
//         _saveFCMToken(newToken);
//         _sendTokenToBackend(newToken);
//       });

//       // Handle background messages
//       FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);

//       // Handle foreground messages
//       FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

//       // Handle notification taps
//       FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

//       print('✅ DEBUG: FCM initialization completed');
//       return _token;
//     } catch (e) {
//       print('❌ ERROR in FCM initialization: $e');
//       return null;
//     }
//   }

  

//   // ================== Private Methods ==================

//   Future<void> _initializeLocalNotifications() async {
//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );

//     const InitializationSettings settings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );

//     await localNotifications.initialize(settings);
//   }

//   Future<void> _configurePlatformSettings() async {
//     // Android: create notification channel
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'high_importance_channel',
//       'High Importance Notifications',
//       description: 'This channel is used for important notifications.',
//       importance: Importance.max,
//       playSound: true,
//       sound: RawResourceAndroidNotificationSound('notification'),
//       enableVibration: true,
//     );

//     await localNotifications
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);

//     // iOS: foreground notification presentation
//     await msgService.setForegroundNotificationPresentationOptions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//   }

//   Future<void> _saveFCMToken(String token) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('fcm_token', token);
//     print('💾 FCM Token saved locally: $token');
//   }

//   Future<void> _sendTokenToBackend(String token) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getString('userId');
      
//       if (userId != null && userId.isNotEmpty) {
//         print('🚀 Sending FCM token to backend: $token');
//         // TODO: Call your backend API here
//         // await ApiService().updateFCMToken(userId, token);
//       }
//     } catch (e) {
//       print('❌ Error sending token to backend: $e');
//     }
//   }

//   Future<void> _handleForegroundMessage(RemoteMessage message) async {
//     print('\n📱 FOREGROUND MESSAGE RECEIVED');
//     print('📱 Message ID: ${message.messageId}');
//     print('📱 From: ${message.from}');
//     print('📱 Sent Time: ${message.sentTime}');
//     if (message.notification != null) {
//       print('📱 Notification - Title: ${message.notification!.title}');
//       print('📱 Notification - Body: ${message.notification!.body}');
//     }
//     if (message.data.isNotEmpty) print('📱 Data payload: ${message.data}');

//     // Show local notification
//     await _showLocalNotification(message);
//     print('📱 END OF FOREGROUND MESSAGE\n');
//   }
// Future<String?> _getFcmToken() async {
//   for (int i = 0; i < 3; i++) {
//     try {
//       final token = await msgService.getToken();

//       if (token != null) {
//         return token;
//       }
//     } catch (e) {
//       print("🔄 FCM retry ${i + 1}: $e");
//     }

//     await Future.delayed(const Duration(seconds: 2));
//   }

//   return null;
// }
//   Future<void> _showLocalNotification(RemoteMessage message) async {
//     final notification = message.notification;
//     if (notification == null) return;

//     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'high_importance_channel',
//       'High Importance Notifications',
//       channelDescription: 'This channel is used for important notifications.',
//       importance: Importance.max,
//       priority: Priority.high,
//       playSound: true,
//       sound: RawResourceAndroidNotificationSound('notification'),
//       enableVibration: true,
//     );

//     const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );

//     const NotificationDetails details = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );
// await localNotifications.show(
//   DateTime.now().millisecondsSinceEpoch.remainder(100000).toInt(),
//   notification.title ?? 'New Notification',
//   notification.body ?? 'You have a new message',
//   details,
//   payload: message.data.isNotEmpty ? message.data.toString() : null,
// );
//   }

//   Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
//     print('\n📱 MESSAGE OPENED APP');
//     print('📱 Message ID: ${message.messageId}');
//     if (message.notification != null) {
//       print('📱 Notification - Title: ${message.notification!.title}');
//       print('📱 Notification - Body: ${message.notification!.body}');
//     }
//     if (message.data.isNotEmpty) print('📱 Data payload: ${message.data}');
//     print('📱 END OF MESSAGE OPENED\n');
//   }

//   // ================== Background Handler ==================
//   @pragma('vm:entry-point')
// static Future<void> _firebaseBackgroundMessageHandler(
//   RemoteMessage message) async {
  
//   // ✅ CRITICAL: Ensure Firebase is initialized in background isolate
//   if (Firebase.apps.isEmpty) {
//     await Firebase.initializeApp();
//     print('✅ Firebase initialized in background handler');
//   }
  
//   print('\n📱 BACKGROUND MESSAGE RECEIVED');
//   print('📱 Message ID: ${message.messageId}');
  
//   final FlutterLocalNotificationsPlugin localNotifications = 
//       FlutterLocalNotificationsPlugin();
  
//   // Initialize local notifications if not already
//   const AndroidInitializationSettings androidSettings = 
//       AndroidInitializationSettings('@mipmap/ic_launcher');
//   const DarwinInitializationSettings iosSettings = 
//       DarwinInitializationSettings();
//   const InitializationSettings settings = InitializationSettings(
//     android: androidSettings,
//     iOS: iosSettings,
//   );
  
//   await localNotifications.initialize(settings);
  
//   if (message.notification != null) {
//     const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//       'high_importance_channel',
//       'High Importance Notifications',
//       channelDescription: 'This channel is used for important notifications.',
//       importance: Importance.max,
//       priority: Priority.high,
//       playSound: true,
//     );
    
//     const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    
//     const NotificationDetails details = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );
    
//     await localNotifications.show(
//       DateTime.now().millisecondsSinceEpoch.remainder(100000).toInt(),
//       message.notification?.title ?? 'New Notification',
//       message.notification?.body ?? 'You have a new message',
//       details,
//     );
//   }
  
//   print('📱 END OF BACKGROUND MESSAGE\n');
// }
// }



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
      print('🔍 DEBUG: Starting FCM initialization...');
      
      if (Firebase.apps.isEmpty) {
        print('⚠️ No Firebase app found, initializing...');
      } else {
        print('✅ Firebase app already exists: ${Firebase.apps.first.name}');
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

      print('🔍 DEBUG: Notification permission: ${settings.authorizationStatus}');

      _token = await _getFcmToken();
      print('🪙 TOKEN DEBUG - FCM Token: ${_token ?? "NULL"}');

      if (_token != null) await _saveFCMToken(_token!);

      msgService.onTokenRefresh.listen((newToken) {
        print('🔄 TOKEN REFRESHED: $newToken');
        _token = newToken;
        _saveFCMToken(newToken);
        _sendTokenToBackend(newToken);
      });

      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      print('✅ DEBUG: FCM initialization completed');
      return _token;
    } catch (e) {
      print('❌ ERROR in FCM initialization: $e');
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
          print('✅ Notification tapped: ${response.payload}');
        },
      );
      
      print('✅ Local notifications initialized');
    } catch (e) {
      print('❌ Error initializing local notifications: $e');
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
            
        print('✅ Android notification channel created');
      }

      await msgService.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      
      print('✅ Platform settings configured');
    } catch (e) {
      print('❌ Error configuring platform settings: $e');
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      print('💾 FCM Token saved locally: $token');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      
      if (userId != null && userId.isNotEmpty) {
        print('🚀 Sending FCM token to backend: $token');
      }
    } catch (e) {
      print('❌ Error sending token to backend: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('\n📱 FOREGROUND MESSAGE RECEIVED');
    print('📱 Message ID: ${message.messageId}');
    
    if (message.notification != null) {
      print('📱 Notification - Title: ${message.notification!.title}');
      print('📱 Notification - Body: ${message.notification!.body}');
    }
    
    if (message.data.isNotEmpty) {
      print('📱 Data payload: ${message.data}');
    }

    await _showLocalNotification(message);
    print('📱 END OF FOREGROUND MESSAGE\n');
  }

  Future<String?> _getFcmToken() async {
    for (int i = 0; i < 3; i++) {
      try {
        final token = await msgService.getToken();
        if (token != null && token.isNotEmpty) {
          return token;
        }
      } catch (e) {
        print("🔄 FCM retry ${i + 1}: $e");
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
      
      print('✅ Local notification shown with sound');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
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

  @pragma('vm:entry-point')
  static Future<void> _firebaseBackgroundMessageHandler(
    RemoteMessage message) async {
    
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
      print('✅ Firebase initialized in background handler');
    }
    
    print('\n📱 BACKGROUND MESSAGE RECEIVED');
    print('📱 Message ID: ${message.messageId}');
    
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
        
        print('✅ Background notification shown with sound');
      } catch (error) {
        print('❌ Error showing background notification: $error');
      }
    }
    
    print('📱 END OF BACKGROUND MESSAGE\n');
  }
}