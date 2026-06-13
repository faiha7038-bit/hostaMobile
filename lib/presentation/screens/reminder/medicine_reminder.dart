import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/alarm.service.dart';
import 'package:hosta/providers/reminder_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  Future<void> requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }
    @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  void _goBack() => Navigator.of(context).pop();

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.green),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(reminderStateProvider.notifier).setSelectedTime(picked);
    }
  }

  void addTime() {
    ref.read(reminderStateProvider.notifier).addTime();
  }

  void removeTime(TimeOfDay time) {
    ref.read(reminderStateProvider.notifier).removeTime(time);
  }

  String formatTime(TimeOfDay time) {
    final now = DateTime.now();
    return TimeOfDay.fromDateTime(
      DateTime(now.year, now.month, now.day, time.hour, time.minute),
    ).format(context);
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ref.read(reminderStateProvider.notifier).setStartDate(picked);
    }
  }

  Future<void> pickEndDate() async {
    final startDate = ref.read(reminderStateProvider).startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ref.read(reminderStateProvider.notifier).setEndDate(picked);
    }
  }

  Future<void> setReminder() async {
    print("🔥 BUTTON PRESSED");
    
    final state = ref.read(reminderStateProvider);
    final medicineName = state.medicineController.text.trim();
    final selectedTimes = state.selectedTimes;
    
    if (medicineName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a medicine name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one reminder time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      for (int i = 0; i < selectedTimes.length; i++) {
        final alarmId =
            (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 2147483647 + i;

        await AlarmService.scheduleAlarm(
          id: alarmId,
          medicineName: medicineName,
          hour: selectedTimes[i].hour,
          minute: selectedTimes[i].minute,
        );
      }

      print("✅ ALARM SET SUCCESS");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reminders set successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form after successful submission
      ref.read(reminderStateProvider.notifier).clearForm();
      Navigator.of(context).pop();

    } catch (e) {
      print("❌ ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting reminder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reminderStateProvider);
    final weekDays = ref.watch(weekDaysProvider);
    
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    
    // Responsive values
    final horizontalPadding = screenWidth * 0.04; // 4% of screen width
    final verticalPadding = screenHeight * 0.02; // 2% of screen height
    final inputHeight = screenHeight * 0.07; // 7% of screen height (min 50, max 65)
    final avatarRadius = screenWidth * 0.045; // Responsive avatar size
    final cardPadding = screenWidth * 0.04;
    final spacingSmall = screenHeight * 0.015;
    final spacingMedium = screenHeight * 0.025;
    final spacingLarge = screenHeight * 0.035;
    final buttonPadding = screenHeight * 0.02;
    final fontSizeTitle = screenWidth * 0.045;
    final fontSizeBody = screenWidth * 0.04;
    final fontSizeSmall = screenWidth * 0.035;

      return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Registering medications'),
        backgroundColor: Colors.green,
        elevation: 0,
        foregroundColor: Colors.white,
        // ✅ FIX: Instant back — no lag, no canPop check needed
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      
      body: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Medicine name ──
              _buildInput(
                controller: state.medicineController,
                hint: 'Medicine name',
                icon: Icons.medication, 
                height: inputHeight,
                fontSize: fontSizeBody,
                onChanged: (value) {
                  ref.read(reminderStateProvider.notifier).updateMedicineName(value);
                },
              ),
              SizedBox(height: spacingSmall),

              // ── Notes ──
              _buildInput(
                controller: state.notesController,
                hint: 'Add notes',
                icon: Icons.notes, 
                height: inputHeight,
                fontSize: fontSizeBody,
                onChanged: (value) {
                  ref.read(reminderStateProvider.notifier).updateNotes(value);
                },
              ),
              SizedBox(height: spacingMedium),

              // ── Time picker ──
              Text(
                'Reminder Time',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSizeBody,
                ),
              ),
              SizedBox(height: spacingSmall),
              GestureDetector(
                onTap: pickTime,
                child: _card(
                  padding: cardPadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        state.selectedTime == null
                            ? 'Select time'
                            : formatTime(state.selectedTime!),
                        style: TextStyle(
                          color: state.selectedTime == null
                              ? Colors.grey
                              : Colors.black,
                          fontSize: fontSizeBody,
                        ),
                      ),
                      const Icon(Icons.access_time, color: Colors.green),
                    ],
                  ),
                ),
              ),
              SizedBox(height: spacingSmall),
              ElevatedButton(
                onPressed: addTime,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade100,
                  foregroundColor: Colors.green,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.012,
                  ), 
                ),
                child: Text(
                  '+ Add Time',
                  style: TextStyle(fontSize: fontSizeBody),
                ),
              ),
              SizedBox(height: spacingSmall),

              // ── Added times list ──
              Wrap(
                spacing: screenWidth * 0.02,
                runSpacing: screenHeight * 0.01,
                children: state.selectedTimes.map((time) {
                  return Chip(
                    label: Text(
                      formatTime(time),
                      style: TextStyle(fontSize: fontSizeSmall),
                    ),
                    deleteIcon: Icon(Icons.close, size: fontSizeBody * 1.2),
                    onDeleted: () => removeTime(time),
                    backgroundColor: Colors.green,
                    labelStyle: const TextStyle(color: Colors.white),
                  );
                }).toList(),
              ),
              SizedBox(height: spacingMedium),

              // ── Days of week ──
              _card(
                padding: cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Days of Week',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: fontSizeBody,
                      ),
                    ),
                    SizedBox(height: spacingSmall),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final isSelected = state.selectedDays.contains(index);
                        return GestureDetector(
                          onTap: () {
                            ref.read(reminderStateProvider.notifier).toggleDay(index);
                          },
                          child: CircleAvatar(
                            radius: avatarRadius,
                            backgroundColor: isSelected
                                ? Colors.green
                                : Colors.grey.shade200,
                            child: Text(
                              weekDays[index][0],
                              style: TextStyle(
                                fontSize: avatarRadius * 0.8,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              SizedBox(height: spacingMedium),

              // ── Start / End date ──
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: pickStartDate,
                      child: _card(
                        padding: cardPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Date',
                              style: TextStyle(
                                fontSize: fontSizeSmall,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              state.startDate == null
                                  ? 'Select'
                                  : '${state.startDate!.day}/${state.startDate!.month}/${state.startDate!.year}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: fontSizeBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.025),
                  Expanded(
                    child: GestureDetector(
                      onTap: pickEndDate,
                      child: _card(
                        padding: cardPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End Date',
                              style: TextStyle(
                                fontSize: fontSizeSmall,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              state.endDate == null
                                  ? 'None'
                                  : '${state.endDate!.day}/${state.endDate!.month}/${state.endDate!.year}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: fontSizeBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: spacingLarge),

              // ── Set Reminder button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: setReminder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.all(buttonPadding),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Next',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSizeBody * 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: spacingLarge),
            ],
          ),
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────
  Widget _card({required Widget child, required double padding}) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required double height,
    required double fontSize,
    required Function(String) onChanged,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Colors.grey,
            size: fontSize * 1.2,
          ),
          hintText: hint,
          hintStyle: TextStyle(fontSize: fontSize),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
          ),
        ),
        style: TextStyle(fontSize: fontSize),
      ),
    );
  }
}

