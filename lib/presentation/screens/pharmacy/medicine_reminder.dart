












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
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
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
  List<TimeOfDay> selectedTimes = [];

  final TextEditingController medicineController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  List<bool> selectedDays = List.generate(7, (_) => true);
  final List<String> days = ["S", "M", "T", "W", "T", "F", "S"];

  // ================= TIME PICKER =================
  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),

      // ✅ GREEN THEME FIX
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  void addTime() {
    if (selectedTime == null) return;

    bool exists = selectedTimes.any((t) =>
        t.hour == selectedTime!.hour && t.minute == selectedTime!.minute);

    if (!exists) {
      setState(() => selectedTimes.add(selectedTime!));
    }
  }

  void removeTime(TimeOfDay time) {
    setState(() => selectedTimes.remove(time));
  }

  String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  // ================= DATE PICKERS =================
  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) setState(() => endDate = picked);
  }

  // ================= REMINDER =================
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

  // ================= UI =================
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
            _buildInput(
              controller: medicineController,
              hint: "Medicine name",
              icon: Icons.medication,
            ),
            const SizedBox(height: 10),
            _buildInput(
              controller: notesController,
              hint: "Add notes",
              icon: Icons.notes,
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Reminder Time",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 10),

            GestureDetector(
              onTap: pickTime,
              child: _card(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(selectedTime == null
                        ? "Select time"
                        : formatTime(selectedTime!)),
                    const Icon(Icons.access_time, color: Colors.green),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: addTime,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade100,
                foregroundColor: Colors.green,
              ),
              child: const Text("+ Add Time"),
            ),

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

            const SizedBox(height: 20),

            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Days of Week",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDays[index] = !selectedDays[index];
                          });
                        },
                        child: CircleAvatar(
                          backgroundColor: selectedDays[index]
                              ? Colors.green
                              : Colors.grey.shade300,
                          child: Text(
                            days[index],
                            style: TextStyle(
                              color: selectedDays[index]
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: pickStartDate,
                    child: _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Start Date"),
                          const SizedBox(height: 5),
                          Text(startDate == null
                              ? "Select"
                              : "${startDate!.day}/${startDate!.month}"),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: pickEndDate,
                    child: _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("End Date"),
                          const SizedBox(height: 5),
                          Text(endDate == null
                              ? "None"
                              : "${endDate!.day}/${endDate!.month}"),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: setReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text("Next",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: child,
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return _card(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }
}



































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

// // ================= NOTIFICATION =================
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
//       matchDateTimeComponents: DateTimeComponents.time,
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

// // ================= SCREEN =================
// class ReminderScreen extends StatefulWidget {
//   const ReminderScreen({super.key});

//   @override
//   State<ReminderScreen> createState() => _ReminderScreenState();
// }

// class _ReminderScreenState extends State<ReminderScreen> {
//   TimeOfDay? selectedTime;
//   List<TimeOfDay> selectedTimes = [];

//   final medicineController = TextEditingController();
//   final notesController = TextEditingController();

//   List<int> selectedDays = [];
//   DateTime? startDate;
//   DateTime? endDate;

//   final List<String> weekDays = ["S", "M", "T", "W", "T", "F", "S"];

//   // TIME PICKER
//   Future<void> pickTime() async {
//     final picked =
//         await showTimePicker(context: context, initialTime: TimeOfDay.now());

//     if (picked != null) {
//       setState(() => selectedTime = picked);
//     }
//   }

//   void addTime() {
//     if (selectedTime == null) return;

//     if (!selectedTimes.contains(selectedTime)) {
//       setState(() => selectedTimes.add(selectedTime!));
//     }
//   }

//   void removeTime(TimeOfDay t) {
//     setState(() => selectedTimes.remove(t));
//   }

//   // DATE PICKER
//   Future<void> pickDate(bool isStart) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2100),
//     );

//     if (picked != null) {
//       setState(() {
//         if (isStart) {
//           startDate = picked;
//         } else {
//           endDate = picked;
//         }
//       });
//     }
//   }

//   String formatTime(TimeOfDay t) {
//     final now = DateTime.now();
//     final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
//     return TimeOfDay.fromDateTime(dt).format(context);
//   }

//   String month(int m) {
//     const months = [
//       "Jan","Feb","Mar","Apr","May","Jun",
//       "Jul","Aug","Sep","Oct","Nov","Dec"
//     ];
//     return months[m - 1];
//   }

//   // NEXT BUTTON
//   void goNext() async {
//     if (medicineController.text.isEmpty ||
//         selectedTimes.isEmpty ||
//         selectedDays.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Fill all required fields")),
//       );
//       return;
//     }

//     for (int i = 0; i < selectedTimes.length; i++) {
//       final t = selectedTimes[i];

//       await NotificationService.scheduleDailyReminder(
//         id: i,
//         title: "Medicine Reminder 💊",
//         body: "Take ${medicineController.text}",
//         hour: t.hour,
//         minute: t.minute,
//       );
//     }

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => SummaryScreen(
//           name: medicineController.text,
//           notes: notesController.text,
//           times: selectedTimes,
//           days: selectedDays,
//           start: startDate,
//           end: endDate,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         title: const Text("Registering medications"),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         foregroundColor: Colors.black,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             _input(medicineController, "Medicine name", Icons.medication),
//             const SizedBox(height: 10),
//             _input(notesController, "Notes", Icons.notes),

//             const SizedBox(height: 20),

//             // TIME
//             GestureDetector(
//               onTap: pickTime,
//               child: _box(
//                 selectedTime == null
//                     ? "Select time"
//                     : formatTime(selectedTime!),
//               ),
//             ),

//             const SizedBox(height: 10),

//             ElevatedButton(
//               onPressed: addTime,
//               child: const Text("Add Time"),
//             ),

//             Wrap(
//               spacing: 8,
//               children: selectedTimes.map((t) {
//                 return Chip(
//                   label: Text(formatTime(t)),
//                   onDeleted: () => removeTime(t),
//                 );
//               }).toList(),
//             ),

//             const SizedBox(height: 20),

//             // FREQUENCY
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: _card(),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text("Frequency",
//                       style:
//                           TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

//                   const SizedBox(height: 10),

//                   const Text("Days of Week"),

//                   const SizedBox(height: 10),

//                   Wrap(
//                     spacing: 10,
//                     children: List.generate(7, (i) {
//                       final selected = selectedDays.contains(i);
//                       return ChoiceChip(
//                         label: Text(weekDays[i]),
//                         selected: selected,
//                         selectedColor: Colors.green,
//                         labelStyle: TextStyle(
//                           color: selected ? Colors.white : Colors.black,
//                         ),
//                         onSelected: (_) {
//                           setState(() {
//                             selected
//                                 ? selectedDays.remove(i)
//                                 : selectedDays.add(i);
//                           });
//                         },
//                       );
//                     }),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             // DATE
//             Row(
//               children: [
//                 Expanded(
//                   child: GestureDetector(
//                     onTap: () => pickDate(true),
//                     child: _dateBox(
//                       "Start date",
//                       startDate == null
//                           ? "Select"
//                           : "${startDate!.day} ${month(startDate!.month)}",
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: GestureDetector(
//                     onTap: () => pickDate(false),
//                     child: _dateBox(
//                       "End Date",
//                       endDate == null
//                           ? "None"
//                           : "${endDate!.day} ${month(endDate!.month)}",
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 30),

//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: goNext,
//                 child: const Text("Next"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _dateBox(String title, String value) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: _card(),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: const TextStyle(color: Colors.grey)),
//           const SizedBox(height: 5),
//           Text(value,
//               style:
//                   const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }

//   Widget _box(String text) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: _card(),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(text),
//           const Icon(Icons.access_time),
//         ],
//       ),
//     );
//   }

//   BoxDecoration _card() {
//     return BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(15),
//     );
//   }

//   Widget _input(controller, hint, icon) {
//     return Container(
//       decoration: _card(),
//       child: TextField(
//         controller: controller,
//         decoration: InputDecoration(
//           prefixIcon: Icon(icon),
//           hintText: hint,
//           border: InputBorder.none,
//           contentPadding: const EdgeInsets.all(16),
//         ),
//       ),
//     );
//   }
// }

// // ================= SUMMARY =================
// class SummaryScreen extends StatelessWidget {
//   final String name;
//   final String notes;
//   final List<TimeOfDay> times;
//   final List<int> days;
//   final DateTime? start;
//   final DateTime? end;

//   const SummaryScreen({
//     super.key,
//     required this.name,
//     required this.notes,
//     required this.times,
//     required this.days,
//     required this.start,
//     required this.end,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final weekDays = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];

//     return Scaffold(
//       appBar: AppBar(title: const Text("Saved Reminder")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Card(
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(name,
//                     style: const TextStyle(
//                         fontSize: 20, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 10),
//                 Text("Notes: $notes"),
//                 const SizedBox(height: 10),
//                 Text("Times: ${times.map((e) => e.format(context)).join(", ")}"),
//                 const SizedBox(height: 10),
//                 Text("Days: ${days.map((i) => weekDays[i]).join(", ")}"),
//                 const SizedBox(height: 10),
//                 Text("Start: ${start ?? "-"}"),
//                 Text("End: ${end ?? "-"}"),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }