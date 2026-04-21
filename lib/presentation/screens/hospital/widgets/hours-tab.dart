import 'package:flutter/material.dart';

class HoursTab extends StatelessWidget {
  final Map<String, dynamic> hospital;
  final String Function(String) formatTime;

  const HoursTab({
    super.key,
    required this.hospital,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final workingHoursClinic = hospital["working_hours_clinic"] as List?;
    final workingHours = hospital["working_hours"] as List?;

    if (workingHoursClinic != null && workingHoursClinic.isNotEmpty) {
      return _buildHoursTabNewFormat(workingHoursClinic);
    } else if (workingHours != null && workingHours.isNotEmpty) {
      return _buildHoursTabOldFormat(workingHours);
    } else {
      return const Center(
        child: Text("No working hours available", style: TextStyle(fontSize: 16)),
      );
    }
  }

  Widget _buildHoursTabNewFormat(List<dynamic> workingHoursClinic) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workingHoursClinic.length,
      itemBuilder: (context, index) {
        final item = workingHoursClinic[index];
        final isHoliday = item["is_holiday"] == true;
        final morningSession = item["morning_session"];
        final eveningSession = item["evening_session"];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(
              item["day"],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isHoliday ? Colors.red : Colors.black,
              ),
            ),
            subtitle: isHoliday
                ? const Text("Holiday", style: TextStyle(color: Colors.red))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (morningSession["open"] != null && morningSession["open"].isNotEmpty)
                        Text("🌅 Morning: ${formatTime(morningSession["open"])} - ${formatTime(morningSession["close"])}"),
                      if (eveningSession["open"] != null && eveningSession["open"].isNotEmpty)
                        Text("🌇 Evening: ${formatTime(eveningSession["open"])} - ${formatTime(eveningSession["close"])}"),
                      if (item["has_break"] == true)
                        const Text("⏸️ Has break time", style: TextStyle(color: Colors.orange)),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHoursTabOldFormat(List<dynamic> workingHours) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workingHours.length,
      itemBuilder: (context, index) {
        final item = workingHours[index];
        final isHoliday = item["is_holiday"] == true;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(
              item["day"],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isHoliday ? Colors.red : Colors.black,
              ),
            ),
            subtitle: isHoliday
                ? const Text("Holiday", style: TextStyle(color: Colors.red))
                : Text(
                    "🕒 ${formatTime(item["opening_time"])} - ${formatTime(item["closing_time"])}",
                    style: const TextStyle(fontSize: 13),
                  ),
          ),
        );
      },
    );
  }
}