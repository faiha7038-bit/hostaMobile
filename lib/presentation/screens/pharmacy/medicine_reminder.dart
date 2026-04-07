// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;

// class PillReminder extends StatelessWidget {
//   const PillReminder({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Pill Reminder',
//       theme: ThemeData(primarySwatch: Colors.green),
//       home: const ReminderScreen(),
//     );
//   }
// }

// // ================= NOTIFICATION SERVICE =================
// class NotificationService {
//   static final FlutterLocalNotificationsPlugin _notifications =
//       FlutterLocalNotificationsPlugin();

//   static Future<void> init() async {
//     const android = AndroidInitializationSettings('@mipmap/ic_launcher');

//     const settings = InitializationSettings(android: android);

//     await _notifications.initialize(settings);

//     tz.initializeTimeZones();
//   }

//   static Future<void> scheduleDailyReminder({
//     required int id,
//     required String title,
//     required String body,
//     required int hour,
//     required int minute,
//   }) async {
//     await _notifications.zonedSchedule(
//       id,
//       title,
//       body,
//       _nextInstanceOfTime(hour, minute),
//       const NotificationDetails(
//         android: AndroidNotificationDetails(
//           'medicine_channel',
//           'Medicine Reminder',
//           importance: Importance.max,
//           priority: Priority.high,
//         ),
//       ),
//       matchDateTimeComponents: DateTimeComponents.time, // 🔥 repeat daily
//       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.absoluteTime,
//     );
//   }

//   static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
//     final now = tz.TZDateTime.now(tz.local);

//     var scheduled = tz.TZDateTime(
//       tz.local,
//       now.year,
//       now.month,
//       now.day,
//       hour,
//       minute,
//     );

//     if (scheduled.isBefore(now)) {
//       scheduled = scheduled.add(const Duration(days: 1));
//     }

//     return scheduled;
//   }
// }

// // ================= UI SCREEN =================
// class ReminderScreen extends StatefulWidget {
//   const ReminderScreen({super.key});

//   @override
//   State<ReminderScreen> createState() => _ReminderScreenState();
// }

// class _ReminderScreenState extends State<ReminderScreen> {
//   TimeOfDay? selectedTime;
//   final TextEditingController medicineController = TextEditingController();

//   Future<void> pickTime() async {
//     final picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay.now(),
//     );

//     if (picked != null) {
//       setState(() => selectedTime = picked);
//     }
//   }

//   Future<void> setReminder() async {
//     if (selectedTime == null || medicineController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Fill all fields")),
//       );
//       return;
//     }

//     await NotificationService.scheduleDailyReminder(
//       id: 1,
//       title: "Medicine Reminder 💊",
//       body: "Take ${medicineController.text}",
//       hour: selectedTime!.hour,
//       minute: selectedTime!.minute,
//     );

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Reminder Set Successfully")),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Pill Reminder"),
//         centerTitle: true,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             TextField(
//               controller: medicineController,
//               decoration: const InputDecoration(
//                 labelText: "Medicine Name",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Time Picker
//             InkWell(
//               onTap: pickTime,
//               child: Container(
//                 padding: const EdgeInsets.all(15),
//                 decoration: BoxDecoration(
//                   border: Border.all(),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       selectedTime == null
//                           ? "Select Time"
//                           : selectedTime!.format(context),
//                     ),
//                     const Icon(Icons.access_time),
//                   ],
//                 ),
//               ),
//             ),

//             const SizedBox(height: 30),

//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: setReminder,
//                 child: const Text("SET REMINDER"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;


class PillReminder extends StatelessWidget {
  const PillReminder({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pill Reminder',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const ReminderScreen(),
    );
  }
}

// ================= NOTIFICATION SERVICE =================
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await _notifications.initialize(settings);

    tz.initializeTimeZones();
  }

  static Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medicine_channel',
          'Medicine Reminder',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}

// ================= UI SCREEN =================
class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  TimeOfDay? selectedTime;
  final TextEditingController medicineController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  List<TimeOfDay> selectedTimes = [];

  // Pick time
  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  // Add time to list
  void addTime() {
    if (selectedTime == null) return;

    bool exists = selectedTimes.any((t) =>
        t.hour == selectedTime!.hour && t.minute == selectedTime!.minute);

    if (!exists) {
      setState(() {
        selectedTimes.add(selectedTime!);
      });
    }
  }

  // Remove time
  void removeTime(TimeOfDay time) {
    setState(() => selectedTimes.remove(time));
  }

  // Schedule reminders
  Future<void> setReminder() async {
    if (selectedTimes.isEmpty || medicineController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add medicine & time")),
      );
      return;
    }

    for (int i = 0; i < selectedTimes.length; i++) {
      final t = selectedTimes[i];

      await NotificationService.scheduleDailyReminder(
        id: i,
        title: "Medicine Reminder 💊",
        body: "Take ${medicineController.text}",
        hour: t.hour,
        minute: t.minute,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reminders Set Successfully")),
    );
  }

  String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Registering medications"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Medicine input
            _buildInput(
              controller: medicineController,
              hint: "Medicine name",
              icon: Icons.medication,
            ),

            const SizedBox(height: 12),

            // Notes
            _buildInput(
              controller: notesController,
              hint: "Add notes like dosage or instructions",
              icon: Icons.notes,
            ),

            const SizedBox(height: 20),

            // Title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Reminder Time",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 12),

            // Time picker box
            GestureDetector(
              onTap: pickTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedTime == null
                          ? "Select time"
                          : formatTime(selectedTime!),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.access_time),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Add time button
            ElevatedButton.icon(
              onPressed: addTime,
              icon: const Icon(Icons.add),
              label: const Text("Add Time"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade100,
                foregroundColor: Colors.green,
                elevation: 0,
              ),
            ),

            const SizedBox(height: 10),

            // Time chips
            Wrap(
              spacing: 8,
              children: selectedTimes.map((time) {
                return Chip(
                  label: Text(formatTime(time)),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => removeTime(time),
                  backgroundColor: Colors.green,
                  labelStyle: const TextStyle(color: Colors.white),
                );
              }).toList(),
            ),

            const Spacer(),

            // Next button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: setReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Next",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Input UI
  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}