import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  static Future<void> initialize() async {
    // Request permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Get token
    String? token = await _firebaseMessaging.getToken();
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 FCM Token: $token');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Save token
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcmToken', token);
    }
    
    // Listen for messages
    FirebaseMessaging.onMessage.listen((message) {
      print('📱 New notification: ${message.notification?.title}');
    });
  }
  
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
  }
}