import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/alarm.service.dart';

//  STATE CLASSES
class ReminderState {
  final TextEditingController medicineController;
  final TextEditingController notesController;
  final TimeOfDay? selectedTime;
  final List<TimeOfDay> selectedTimes;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int> selectedDays;

  ReminderState({
    required this.medicineController,
    required this.notesController,
    this.selectedTime,
    this.selectedTimes = const [],
    this.startDate,
    this.endDate,
    this.selectedDays = const [],
  });

  ReminderState copyWith({
    TextEditingController? medicineController,
    TextEditingController? notesController,
    TimeOfDay? selectedTime,
    List<TimeOfDay>? selectedTimes,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? selectedDays,
  }) {
    return ReminderState(
      medicineController: medicineController ?? this.medicineController,
      notesController: notesController ?? this.notesController,
      selectedTime: selectedTime ?? this.selectedTime,
      selectedTimes: selectedTimes ?? this.selectedTimes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedDays: selectedDays ?? this.selectedDays,
    );
  }
}

//  PROVIDERS
final reminderStateProvider = StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  return ReminderNotifier();
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

  void clearForm() {
    state.medicineController.clear();
    state.notesController.clear();
    state = state.copyWith(
      selectedTime: null,
      selectedTimes: [],
      startDate: null,
      endDate: null,
      selectedDays: [],
    );
  }
  
  @override
  void dispose() {
    state.medicineController.dispose();
    state.notesController.dispose();
    super.dispose();
  }
}

//  ALARM SERVICE PROVIDER
final alarmServiceProvider = Provider<AlarmService>((ref) {
  return AlarmService();
});

//  HELPER PROVIDERS
final weekDaysProvider = Provider<List<String>>((ref) {
  return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
});

// Global key for navigation context
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});