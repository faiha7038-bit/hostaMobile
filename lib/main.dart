import 'package:alarm/alarm.dart' show Alarm;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/firebase_msg.dart';
import 'package:hosta/presentation/screens/pharmacy/medicine_reminder.dart';
import 'package:hosta/presentation/widgets/bottomnav.dart';
import 'package:firebase_core/firebase_core.dart';
//import 'package:hosta/presentation/screens/home/home.dart';

void main() async {
   WidgetsFlutterBinding.ensureInitialized(); // ✅ required
  //await AlarmService.init();  
  await Alarm.init();
  runApp(MyApp());               // ✅ your line
  //runApp(const ReminderScreen());  
  // WidgetsFlutterBinding.ensureInitialized();
  //   await AlarmService.init();
  await Firebase.initializeApp();

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission FIRST
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print("Permission: ${settings.authorizationStatus}");

  // Wait a little for iOS to generate APNS token
  await Future.delayed(const Duration(seconds: 2));

  String? apnsToken = await messaging.getAPNSToken();
  print("APNS TOKEN: $apnsToken");

  final firebaseMsg = FirebaseMsg();
  await firebaseMsg.initFCM();

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return ProviderScope(
      child: MaterialApp(
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
      ),
    );
  }
}



