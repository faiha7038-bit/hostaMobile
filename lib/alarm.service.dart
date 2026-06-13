import 'package:alarm/alarm.dart';

//  ALARM SERVICE
class AlarmService {
  /// Call once from main() before runApp()
  static Future<void> init() async {
    await Alarm.init();
  }

  /// Schedule a one-shot alarm at [hour]:[minute].
  /// Automatically pushed to tomorrow if time already passed today.
  static Future<void> scheduleAlarm({
    required int id,
    required String medicineName,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    var alarmTime = DateTime(now.year, now.month, now.day, hour, minute);

    if (alarmTime.isBefore(now)) {
      alarmTime = alarmTime.add(const Duration(days: 1));
    }

    final settings = AlarmSettings(
      id: id,
      dateTime: alarmTime,
      assetAudioPath: 'assets/alarm.mp3.wav',
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: 0.9,
        fadeDuration: const Duration(seconds: 4),
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: 'Medicine Reminder 💊',
        body: 'Time to take $medicineName',
        stopButton: 'Dismiss',
        icon: 'notification_icon',
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