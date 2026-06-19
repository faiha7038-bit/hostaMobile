// import 'package:alarm/alarm.dart';

// class AlarmService {
//   static Future<void> init() async {
//     await Alarm.init();
//   }

//   /// Schedule a one-shot alarm at [hour]:[minute].
//   /// Automatically pushed to tomorrow if time already passed today.
//   static Future<void> scheduleAlarm({
//     required int id,
//     required String medicineName,
//     required int hour,
//     required int minute,
//   }) async {
//     final now = DateTime.now();
//     var alarmTime = DateTime(now.year, now.month, now.day, hour, minute);

//     if (alarmTime.isBefore(now)) {
//       alarmTime = alarmTime.add(const Duration(days: 1));
//     }

//     final settings = AlarmSettings(
//       id: id,
//       dateTime: alarmTime,
//       assetAudioPath: 'assets/alarm.mp3.wav',
//       loopAudio: true,
//       vibrate: true,
//       warningNotificationOnKill: true,
//       androidFullScreenIntent: true,
//       volumeSettings: VolumeSettings.fade(
//         volume: 0.9,
//         fadeDuration: const Duration(seconds: 4),
//         volumeEnforced: true,
//       ),
//       notificationSettings: NotificationSettings(
//         title: 'Medicine Reminder 💊',
//         body: 'Time to take $medicineName',
//         stopButton: 'Dismiss',
//         icon: 'notification_icon',
//       ),
//     );

//     await Alarm.set(alarmSettings: settings);
//   }

// static Future<void> cancelAlarm(int id) async {
//     await Alarm.stop(id);
//   }
//   static Future<void> cancelAlarms() async {
//     await Alarm.stopAll();
//   }
// }
import 'package:alarm/alarm.dart';
import 'package:flutter/services.dart' show rootBundle;

// ALARM SERVICE
class AlarmService {
  static const String defaultAlarmPath = 'assets/alarm.mp3.wav';
  
  // Available alarm sounds
  static const List<AlarmSound> availableSounds = [
    AlarmSound(
      id: 'default',
      name: 'Default Alarm',
      path: 'assets/alarm.mp3.wav',
    ),
    AlarmSound(
      id: 'alarm music',
      name: 'Gentle Bell',
      path: 'assets/sounds/alarm_music.mp3',
    ),
    AlarmSound(
      id: 'melody',
      name: 'Melody',
      path: 'assets/sounds/melody.mp3',
    ),
    AlarmSound(
      id: 'urgent',
      name: 'Urgent Beep',
      path: 'assets/sounds/urgent_beep.mp3',
    ),
    AlarmSound(
      id: 'medicine_sound',
      name: 'Nature Sound',
      path: 'assets/sounds/medicine_sound.mp3',
    ),
  ];

  /// Call once from main() before runApp()
  static Future<void> init() async {
    await Alarm.init();
  }

  /// Schedule a one-shot alarm at [hour]:[minute] with custom sound
  static Future<void> scheduleAlarm({
    required int id,
    required String medicineName,
    required int hour,
    required int minute,
    String soundPath = defaultAlarmPath, // Add sound path parameter
  }) async {
    final now = DateTime.now();
    var alarmTime = DateTime(now.year, now.month, now.day, hour, minute);

    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

   try {
      final data = await rootBundle.load(soundPath);
      print('✅ Sound file loaded: $soundPath');
    } catch (e) {
      print('❌ Sound file NOT found: $soundPath');
      print('Using default path: $defaultAlarmPath');
      soundPath = defaultAlarmPath;
    }

    final settings = AlarmSettings(
      id: id,
      dateTime: alarmTime,
      assetAudioPath: soundPath, // Use custom sound path
      loopAudio: true,
      vibrate: true,
        // playOnStartup: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: const Duration(seconds: 4),
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: 'Medicine Reminder 💊',
        body: 'Time to take $medicineName',
        stopButton: 'Dismiss',       
        icon: 'notification_icon',
        ///playSound: true, 
        //sound: soundPath,
      ),
    );

    await Alarm.set(alarmSettings: settings);
  }

  static Future<void> cancelAlarm(int id) async {
    await Alarm.stop(id);
  }
  
  static Future<void> cancelAlarms() async {
    await Alarm.stopAll();
  }
}

// Alarm Sound Model
class AlarmSound {
  final String id;
  final String name;
  final String path;

  const AlarmSound({
    required this.id,
    required this.name,
    required this.path,
  });
}