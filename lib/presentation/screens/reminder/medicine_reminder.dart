
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
  late Future<void> _permissionFuture;

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
    _permissionFuture = requestPermissions();
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
    final state = ref.read(reminderStateProvider);
    final medicineName = state.medicineController.text.trim();
    final selectedTimes = state.selectedTimes;
    
    if (medicineName.isEmpty) {
      _showSnackBar('Please enter a medicine name', Colors.red);
      return;
    }

    if (selectedTimes.isEmpty) {
      _showSnackBar('Please add at least one reminder time', Colors.red);
      return;
    }

    try {
      final selectedSoundId = state.selectedSoundId;
      final alarmSounds = ref.read(alarmSoundsProvider);
      final selectedSound = alarmSounds.firstWhere(
        (sound) => sound.id == selectedSoundId,
        orElse: () => alarmSounds.first,
      );
      
      for (int i = 0; i < selectedTimes.length; i++) {
        final alarmId =
            (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 2147483647 + i;

        await AlarmService.scheduleAlarm(
          id: alarmId,
          medicineName: medicineName,
          hour: selectedTimes[i].hour,
          minute: selectedTimes[i].minute,
          soundPath: selectedSound.path,
        );
      }

      if (!mounted) return;

      _showSnackBar('✅ Reminders set successfully!', Colors.green);

      ref.read(reminderStateProvider.notifier).clearForm();
      Navigator.of(context).pop();

    } catch (e) {
      if (mounted) {
        _showSnackBar('Error setting reminder: $e', Colors.red);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.015,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reminderStateProvider);
    final weekDays = ref.watch(weekDaysProvider);
    final alarmSounds = ref.watch(alarmSoundsProvider);
    final currentSound = alarmSounds.firstWhere(
      (sound) => sound.id == state.selectedSoundId,
      orElse: () => alarmSounds.first,
    );
    
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;
    
    final horizontalPadding = isSmallScreen 
        ? screenWidth * 0.04 
        : (isTablet ? screenWidth * 0.06 : screenWidth * 0.08);
    final verticalPadding = screenHeight * 0.02;
    final inputHeight = isSmallScreen 
        ? screenHeight * 0.07 
        : (isTablet ? screenHeight * 0.065 : screenHeight * 0.06);
    final avatarRadius = isSmallScreen 
        ? screenWidth * 0.045 
        : (isTablet ? screenWidth * 0.035 : screenWidth * 0.028);
    final cardPadding = isSmallScreen 
        ? screenWidth * 0.04 
        : screenWidth * 0.035;
    final spacingSmall = screenHeight * 0.015;
    final spacingMedium = screenHeight * 0.025;
    final spacingLarge = screenHeight * 0.035;
    final buttonPadding = isSmallScreen 
        ? screenHeight * 0.02 
        : screenHeight * 0.025;
    final fontSizeTitle = isSmallScreen 
        ? screenWidth * 0.05 
        : (isTablet ? screenWidth * 0.04 : screenWidth * 0.032);
    final fontSizeBody = isSmallScreen 
        ? screenWidth * 0.04 
        : (isTablet ? screenWidth * 0.032 : screenWidth * 0.025);
    final fontSizeSmall = isSmallScreen 
        ? screenWidth * 0.035 
        : (isTablet ? screenWidth * 0.028 : screenWidth * 0.022);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Medicine Reminder',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: fontSizeTitle,
          ),
        ),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: isSmallScreen 
                ? screenWidth * 0.055 
                : (isTablet ? screenWidth * 0.04 : screenWidth * 0.032),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: isSmallScreen 
            ? kToolbarHeight 
            : (isTablet 
                ? kToolbarHeight * 1.1 
                : kToolbarHeight * 1.2),
        elevation: isSmallScreen ? 0 : 2,
      ),
      
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? screenWidth * 0.7 : screenWidth,
          ),
          child: Padding(
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
                    isSmallScreen: isSmallScreen,
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
                    isSmallScreen: isSmallScreen,
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
                          Icon(
                            Icons.access_time,
                            color: Colors.green,
                            size: isSmallScreen 
                                ? screenWidth * 0.055 
                                : screenWidth * 0.045,
                          ),
                        ],
                      ),
                      isSmallScreen: isSmallScreen,
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                    child: Text(
                      '+ Add Time',
                      style: TextStyle(
                        fontSize: fontSizeBody,
                        fontWeight: FontWeight.w500,
                      ),
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
                          style: TextStyle(
                            fontSize: fontSizeSmall,
                          ),
                        ),
                        deleteIcon: Icon(
                          Icons.close,
                          size: fontSizeBody * 1.2,
                        ),
                        onDeleted: () => removeTime(time),
                        backgroundColor: Colors.green,
                        labelStyle: const TextStyle(
                          color: Colors.white,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: screenHeight * 0.005,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            isSmallScreen ? 8 : 10,
                          ),
                        ),
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
                              child: Container(
                                width: avatarRadius * 2.2,
                                height: avatarRadius * 2.2,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    weekDays[index][0],
                                    style: TextStyle(
                                      fontSize: avatarRadius * 0.9,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    isSmallScreen: isSmallScreen,
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
                            isSmallScreen: isSmallScreen,
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
                            isSmallScreen: isSmallScreen,
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
                          borderRadius: BorderRadius.circular(
                            isSmallScreen ? 12 : 14,
                          ),
                        ),
                        elevation: isSmallScreen ? 2 : 4,
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
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────
  Widget _card({
    required Widget child,
    required double padding,
    required bool isSmallScreen,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 15 : 18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: isSmallScreen ? 6 : 8,
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
    required bool isSmallScreen,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.035,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 15 : 18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: isSmallScreen ? 6 : 8,
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
          hintStyle: TextStyle(
            fontSize: fontSize,
            color: Colors.grey[400],
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: screenWidth * 0.035,
          ),
        ),
        style: TextStyle(
          fontSize: fontSize,
          color: Colors.black87,
        ),
      ),
    );
  }
}