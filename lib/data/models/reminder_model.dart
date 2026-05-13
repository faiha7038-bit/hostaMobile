// lib/models/medicine_reminder_model.dart (New File)

class MedicineReminder {
  final String medicineName;
  final String? notes;
  final List<Map<String, int>> reminderTimes;
  final List<int> selectedDays;
  final DateTime? startDate;
  final DateTime? endDate;

  MedicineReminder({
    required this.medicineName,
    this.notes,
    required this.reminderTimes,
    required this.selectedDays,
    this.startDate,
    this.endDate,
  });

  // JSON ആക്കി മാറ്റാൻ - API-ക്ക് send ചെയ്യാൻ
  Map<String, dynamic> toJson() {
    return {
      'medicineName': medicineName,
      'notes': notes,
      'reminderTimes': reminderTimes,
      'selectedDays': selectedDays,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }
}

