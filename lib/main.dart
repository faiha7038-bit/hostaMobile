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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('ℹ️ Starting app initialization...');
    
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
    final messaging = firebase.FirebaseMessaging.instance;
    // Initialize Alarm
    await Alarm.init();
    print('✅ Alarm initialized');
    await ApiService().init();
    // Request notification permissions (using prefix)
    firebase.NotificationSettings settings = await firebase.FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print("✅ Permission: ${settings.authorizationStatus}");
    
    // Wait for iOS APNS token
  await Future.delayed(const Duration(seconds: 2));
    
//    String? apnsToken = await messaging.getAPNSToken();
// print("🍏 APNS TOKEN: $apnsToken");



    // Initialize FCM
    final firebaseMsg = FirebaseMsg();
    await firebaseMsg.initFCM();
    print('✅ FCM initialized');
   
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
                    runApp(const ProviderScope(child: MyApp()));
                  },
                  child: const Text('Continue Anyway'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
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

