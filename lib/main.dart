import 'package:alarm/alarm.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hosta/firebase_msg.dart';
import 'package:hosta/firebase_options.dart';
import 'package:hosta/presentation/widgets/bottomnav.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hosta/services/api_service.dart';
import 'package:permission_handler/permission_handler.dart'; // ✅ Added missing import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('ℹ️ Starting app initialization...');
    
    //  // ✅ Request permissions first
    //  await _requestPermissions();
    
    // ✅ Firebase initialization
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
    } catch (e) {
      if (e.toString().contains('duplicate-app')) {
        print('✅ Firebase already initialized, using existing instance');
      } else {
        throw e;
      }
    }
    
    // Initialize Hive
    await Hive.initFlutter();
    await Hive.openBox('donorsBox');
    await Hive.openBox('blood_cache');
    await Hive.openBox('ambulance_cache');
    print('✅ Hive initialized');
    
    // Initialize Alarm
    await Alarm.init();
    print('✅ Alarm initialized');
    
    // Initialize API Service
    await ApiService().init();
    print('✅ API Service initialized');
    
    // Initialize FCM
    final firebaseMsg = FirebaseMsg();
    await firebaseMsg.initFCM();
    print('✅ FCM initialized');
    
    // ✅ Request notification permissions
    await _requestNotificationPermissions();
   
    runApp(const ProviderScope(child: MyApp()));
    
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print(stackTrace);

    // Error screen
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Try again
                    runApp(const ProviderScope(child: MyApp()));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

// ✅ Moved these functions outside the main function

// Future<void> _requestPermissions() async {
//   try {
//     final statuses = await [
//       Permission.storage,
//     //  Permission.camera,
//     ].request();
    
//     print('✅ Storage permission: ${statuses[Permission.storage]}');
//     print('✅ Camera permission: ${statuses[Permission.camera]}');
//   } catch (e) {
//     print('❌ Error requesting permissions: $e');
//   }
// }

Future<void> requestPermissions() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
}

Future<void> _requestNotificationPermissions() async {
  try {
    // Request notification permissions using Firebase Messaging
    firebase.NotificationSettings settings = await firebase.FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print("✅ Notification permission status: ${settings.authorizationStatus}");
    
    // Wait for iOS APNS token
    await Future.delayed(const Duration(seconds: 2));
    
    // Get APNS token (iOS)
    String? apnsToken = await firebase.FirebaseMessaging.instance.getAPNSToken();
    if (apnsToken != null) {
      print("🍏 APNS TOKEN: $apnsToken");
    }
  } catch (e) {
    print('❌ Error requesting notification permissions: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hosta - Healthcare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.green,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          primary: Colors.green,
          secondary: Colors.green,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const Bottomnav(),
    );
  }
}