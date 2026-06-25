class MedicineReminder {
  final String medicineName;
  final String? notes;
  final List<Map<String, int>> reminderTimes;
  final List<int> selectedDays;
  final DateTime? startDate;
  final DateTime? endDate;
   final String selectedSoundId; 
  final String selectedSoundPath;

  MedicineReminder({
    required this.medicineName,
    this.notes,
    required this.reminderTimes,
    required this.selectedDays,
    this.startDate,
    this.endDate,
      this.selectedSoundId = 'default', 
    this.selectedSoundPath = 'assets/alarm.mp3.wav'
  });

  Map<String, dynamic> toJson() {
    return {
      'medicineName': medicineName,
      'notes': notes,
      'reminderTimes': reminderTimes,
      'selectedDays': selectedDays,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'selectedSoundId': selectedSoundId,
      'selectedSoundPath': selectedSoundPath,
    };
  }
   factory MedicineReminder.fromJson(Map<String, dynamic> json) {
    return MedicineReminder(
      medicineName: json['medicineName'] ?? '',
      notes: json['notes'],
      reminderTimes: List<Map<String, int>>.from(json['reminderTimes'] ?? []),
      selectedDays: List<int>.from(json['selectedDays'] ?? []),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      selectedSoundId: json['selectedSoundId'] ?? 'default',
      selectedSoundPath: json['selectedSoundPath'] ?? 'assets/alarm.mp3.wav',
    );
  }
   MedicineReminder copyWith({
    String? medicineName,
    String? notes,
    List<Map<String, int>>? reminderTimes,
    List<int>? selectedDays,
    DateTime? startDate,
    DateTime? endDate,
    String? selectedSoundId,
    String? selectedSoundPath,
  }) {
       return MedicineReminder(
      medicineName: medicineName ?? this.medicineName,
      notes: notes ?? this.notes,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      selectedDays: selectedDays ?? this.selectedDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedSoundId: selectedSoundId ?? this.selectedSoundId,
      selectedSoundPath: selectedSoundPath ?? this.selectedSoundPath,
    );
  }
}

