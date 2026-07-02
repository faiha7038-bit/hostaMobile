// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hosta/alarm.service.dart';
// import 'package:hosta/data/models/reminder_model.dart';

// //  STATE CLASSES
// class ReminderState {
//   final TextEditingController medicineController;
//   final TextEditingController notesController;
//   final TimeOfDay? selectedTime;
//   final List<TimeOfDay> selectedTimes;
//   final DateTime? startDate;
//   final DateTime? endDate;
//   final List<int> selectedDays;
//    final String selectedSoundId;
//   final String selectedSoundPath;

//   ReminderState({
//     required this.medicineController,
//     required this.notesController,
//     this.selectedTime,
//     this.selectedTimes = const [],
//     this.startDate,
//     this.endDate,
//     this.selectedDays = const [],
//      this.selectedSoundId = 'default',
//       this.selectedSoundPath = 'assets/alarm.mp3.wav',
//   });

//   ReminderState copyWith({
//     TextEditingController? medicineController,
//     TextEditingController? notesController,
//     TimeOfDay? selectedTime,
//     List<TimeOfDay>? selectedTimes,
//     DateTime? startDate,
//     DateTime? endDate,
//     List<int>? selectedDays,
//     String? selectedSoundId,
//     String? selectedSoundPath,
//   }) {
//     return ReminderState(
//       medicineController: medicineController ?? this.medicineController,
//       notesController: notesController ?? this.notesController,
//       selectedTime: selectedTime ?? this.selectedTime,
//       selectedTimes: selectedTimes ?? this.selectedTimes,
//       startDate: startDate ?? this.startDate,
//       endDate: endDate ?? this.endDate,
//       selectedDays: selectedDays ?? this.selectedDays,
//         selectedSoundId: selectedSoundId ?? this.selectedSoundId,
//       selectedSoundPath: selectedSoundPath ?? this.selectedSoundPath,
//     );
//   }
//   // Convert to MedicineReminder model
//   MedicineReminder toMedicineReminder() {
//     return MedicineReminder(
//       medicineName: medicineController.text.trim(),
//       notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
//       reminderTimes: selectedTimes.map((time) => {
//         'hour': time.hour,
//         'minute': time.minute,
//       }).toList(),
//       selectedDays: selectedDays,
//       startDate: startDate,
//       endDate: endDate,
//       selectedSoundId: selectedSoundId,
//       selectedSoundPath: selectedSoundPath,
//     );
//   }
// }


// //  PROVIDERS
// final reminderStateProvider = StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
//   return ReminderNotifier();
// });
// // Add a provider for available alarm sounds
// final alarmSoundsProvider = Provider<List<AlarmSound>>((ref) {
//   return AlarmService.availableSounds;
// });

// class ReminderNotifier extends StateNotifier<ReminderState> {
//   ReminderNotifier() : super(
//     ReminderState(
//       medicineController: TextEditingController(),
//       notesController: TextEditingController(),
//     ),
//   );

//   void setSelectedTime(TimeOfDay? time) {
//     state = state.copyWith(selectedTime: time);
//   }

//   void addTime() {
//     if (state.selectedTime == null) return;
//     final exists = state.selectedTimes.any(
//       (t) => t.hour == state.selectedTime!.hour && t.minute == state.selectedTime!.minute,
//     );
//     if (!exists) {
//       state = state.copyWith(
//         selectedTimes: [...state.selectedTimes, state.selectedTime!],
//       );
//     }
//   }

//   void removeTime(TimeOfDay time) {
//     state = state.copyWith(
//       selectedTimes: state.selectedTimes.where((t) => t != time).toList(),
//     );
//   }

//   void setStartDate(DateTime? date) {
//     state = state.copyWith(startDate: date);
//   }

//   void setEndDate(DateTime? date) {
//     state = state.copyWith(endDate: date);
//   }

//   void toggleDay(int index) {
//     final newDays = List<int>.from(state.selectedDays);
//     if (newDays.contains(index)) {
//       newDays.remove(index);
//     } else {
//       newDays.add(index);
//     }
//     state = state.copyWith(selectedDays: newDays);
//   }

//   void updateMedicineName(String value) {
//     state.medicineController.text = value;
//   }

//   void updateNotes(String value) {
//     state.notesController.text = value;
//   }
//   void setSelectedSound(String soundId, String soundPath) {
//     state = state.copyWith(
//       selectedSoundId: soundId,
//       selectedSoundPath: soundPath,
//     );
//   }

//   void clearForm() {
//     state.medicineController.clear();
//     state.notesController.clear();
//     state = state.copyWith(
//       selectedTime: null,
//       selectedTimes: [],
//       startDate: null,
//       endDate: null,
//       selectedDays: [],
//     );
//   }
  
//   @override
//   void dispose() {
//     state.medicineController.dispose();
//     state.notesController.dispose();
//     super.dispose();
//   }
// }

// //  ALARM SERVICE PROVIDER
// final alarmServiceProvider = Provider<AlarmService>((ref) {
//   return AlarmService();
// });

// //  HELPER PROVIDERS
// final weekDaysProvider = Provider<List<String>>((ref) {
//   return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
// });

// // Global key for navigation context
// final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
//   return GlobalKey<NavigatorState>();
// });



import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/alarm.service.dart';

class ReminderState {
  final TextEditingController medicineController;
  final TextEditingController notesController;
  final TimeOfDay? selectedTime;
  final List<TimeOfDay> selectedTimes;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int> selectedDays;
  final String selectedSoundId;
  final String selectedSoundPath;

  ReminderState({
    required this.medicineController,
    required this.notesController,
    this.selectedTime,
    this.selectedTimes = const [],
    this.startDate,
    this.endDate,
    this.selectedDays = const [],
    this.selectedSoundId = 'default',  // ✅ fixed
    this.selectedSoundPath = 'assets/alarm.mp3.wav',  // ✅ fixed
  });

  ReminderState copyWith({
    TextEditingController? medicineController,
    TextEditingController? notesController,
    TimeOfDay? selectedTime,
    List<TimeOfDay>? selectedTimes,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? selectedDays,
    String? selectedSoundId,
    String? selectedSoundPath,
  }) {
    return ReminderState(
      medicineController: medicineController ?? this.medicineController,
      notesController: notesController ?? this.notesController,
      selectedTime: selectedTime ?? this.selectedTime,
      selectedTimes: selectedTimes ?? this.selectedTimes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedDays: selectedDays ?? this.selectedDays,
      selectedSoundId: selectedSoundId ?? this.selectedSoundId,
      selectedSoundPath: selectedSoundPath ?? this.selectedSoundPath,
    );
  }
}

final reminderStateProvider = StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  return ReminderNotifier();
});

// ✅ Alarm sounds provider - ഒറ്റ sound മാത്രം
final alarmSoundsProvider = Provider<List<AlarmSound>>((ref) {
  return const [
    AlarmSound(
      id: 'default',
      name: 'Alarm',
      path: 'assets/alarm.mp3.wav',
    ),
  ];
});

class ReminderNotifier extends StateNotifier<ReminderState> {
  ReminderNotifier() : super(
    ReminderState(
      medicineController: TextEditingController(),
      notesController: TextEditingController(),
    ),
  );

  void setSelectedTime(TimeOfDay? time) {
    state = state.copyWith(selectedTime: time);
  }

  void addTime() {
    if (state.selectedTime == null) return;
    final exists = state.selectedTimes.any(
      (t) => t.hour == state.selectedTime!.hour && t.minute == state.selectedTime!.minute,
    );
    if (!exists) {
      state = state.copyWith(
        selectedTimes: [...state.selectedTimes, state.selectedTime!],
      );
    }
  }

  void removeTime(TimeOfDay time) {
    state = state.copyWith(
      selectedTimes: state.selectedTimes.where((t) => t != time).toList(),
    );
  }

  void setStartDate(DateTime? date) {
    state = state.copyWith(startDate: date);
  }

  void setEndDate(DateTime? date) {
    state = state.copyWith(endDate: date);
  }

  void toggleDay(int index) {
    final newDays = List<int>.from(state.selectedDays);
    if (newDays.contains(index)) {
      newDays.remove(index);
    } else {
      newDays.add(index);
    }
    state = state.copyWith(selectedDays: newDays);
  }

  void updateMedicineName(String value) {
    state.medicineController.text = value;
  }

  void updateNotes(String value) {
    state.notesController.text = value;
  }

  // ✅ Sound selection - ഒറ്റ sound ആയതിനാൽ ഇത് ആവശ്യമില്ല, പക്ഷേ വേണമെങ്കിൽ വെക്കാം
  void setSelectedSound(String soundId, String soundPath) {
    state = state.copyWith(
      selectedSoundId: soundId,
      selectedSoundPath: soundPath,
    );
  }

  void clearForm() {
    state.medicineController.clear();
    state.notesController.clear();
    state = state.copyWith(
      selectedTime: null,
      selectedTimes: [],
      startDate: null,
      endDate: null,
      selectedDays: [],
      selectedSoundId: 'default',  // ✅ Reset to default
      selectedSoundPath: 'assets/alarm.mp3.wav',  // ✅ Reset to default
    );
  }

  @override
  void dispose() {
    state.medicineController.dispose();
    state.notesController.dispose();
    super.dispose();
  }
}

final weekDaysProvider = Provider<List<String>>((ref) {
  return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
});