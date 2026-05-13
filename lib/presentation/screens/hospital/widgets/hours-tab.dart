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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 👇 Check all possible working hours formats
    final workingHoursClinic = hospital["working_hours_clinic"] as List?;
    final workingHoursGeneral = hospital["working_hours_general"] as List?;
    final workingHoursClinicNoBreak = hospital["working_hours_clinic_nobreak"] as List?;

    if (workingHoursClinic != null && workingHoursClinic.isNotEmpty) {
      return _buildHoursTabClinicFormat(workingHoursClinic, screenWidth, screenHeight);
    } else if (workingHoursGeneral != null && workingHoursGeneral.isNotEmpty) {
      return _buildHoursTabGeneralFormat(workingHoursGeneral, screenWidth, screenHeight);
    } else if (workingHoursClinicNoBreak != null && workingHoursClinicNoBreak.isNotEmpty) {
      return _buildHoursTabClinicNoBreakFormat(workingHoursClinicNoBreak, screenWidth, screenHeight);
    } else {
      return Center(
        child: Text(
          "No working hours available",
          style: TextStyle(fontSize: screenWidth * 0.04),
        ),
      );
    }
  }

  // ✅ Clinic format with morning/evening sessions (has_break possible)
  Widget _buildHoursTabClinicFormat(List<dynamic> hoursList, double screenWidth, double screenHeight) {
    return ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.04),
      itemCount: hoursList.length,
      itemBuilder: (context, index) {
        final item = hoursList[index];
        final isHoliday = item["is_holiday"] == true;
        final morningSession = item["morning_session"];
        final eveningSession = item["evening_session"];

        return Card(
          elevation: screenWidth * 0.005,
          margin: EdgeInsets.only(bottom: screenHeight * 0.0125),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
          child: ListTile(
            title: Text(
              item["day"] ?? "Unknown",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.0375,
                color: isHoliday ? Colors.red : Colors.black,
              ),
            ),
            subtitle: isHoliday
                ? Text(
                    "Holiday",
                    style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.035),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 👇 Safe null check for morning session
                      if (morningSession != null &&
                          morningSession["open"] != null &&
                          morningSession["open"].toString().isNotEmpty)
                        Text(
                          "🌅 Morning: ${formatTime(morningSession["open"])} - ${formatTime(morningSession["close"])}",
                          style: TextStyle(fontSize: screenWidth * 0.0325),
                        ),
                      // 👇 Safe null check for evening session
                      if (eveningSession != null &&
                          eveningSession["open"] != null &&
                          eveningSession["open"].toString().isNotEmpty)
                        Text(
                          "🌇 Evening: ${formatTime(eveningSession["open"])} - ${formatTime(eveningSession["close"])}",
                          style: TextStyle(fontSize: screenWidth * 0.0325),
                        ),
                      if (item["has_break"] == true)
                        Text(
                          "⏸️ Has break time",
                          style: TextStyle(color: Colors.orange, fontSize: screenWidth * 0.0325),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // ✅ General format (single slot per day)
  Widget _buildHoursTabGeneralFormat(List<dynamic> hoursList, double screenWidth, double screenHeight) {
    return ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.04),
      itemCount: hoursList.length,
      itemBuilder: (context, index) {
        final item = hoursList[index];
        final isHoliday = item["is_holiday"] == true;
        
        // 👇 Some entries have "hours" string (e.g., "09:00-17:00") instead of opening_time/closing_time
        String displayText = "";
        if (item["opening_time"] != null && item["closing_time"] != null) {
          displayText = "🕒 ${formatTime(item["opening_time"])} - ${formatTime(item["closing_time"])}";
        } else if (item["hours"] != null && item["hours"].toString().contains("-")) {
          final parts = item["hours"].split("-");
          if (parts.length == 2) {
            displayText = "🕒 ${formatTime(parts[0].trim())} - ${formatTime(parts[1].trim())}";
          } else {
            displayText = item["hours"];
          }
        } else {
          displayText = "Timings not specified";
        }

        return Card(
          elevation: screenWidth * 0.005,
          margin: EdgeInsets.only(bottom: screenHeight * 0.0125),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
          child: ListTile(
            title: Text(
              item["day"] ?? "Unknown",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.0375,
                color: isHoliday ? Colors.red : Colors.black,
              ),
            ),
            subtitle: isHoliday
                ? Text("Holiday", style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.035))
                : Text(displayText, style: TextStyle(fontSize: screenWidth * 0.0325)),
          ),
        );
      },
    );
  }

  // ✅ Clinic no-break format (similar to general but field name may differ)
  Widget _buildHoursTabClinicNoBreakFormat(List<dynamic> hoursList, double screenWidth, double screenHeight) {
    return ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.04),
      itemCount: hoursList.length,
      itemBuilder: (context, index) {
        final item = hoursList[index];
        final isHoliday = item["is_holiday"] == true;

        return Card(
          elevation: screenWidth * 0.005,
          margin: EdgeInsets.only(bottom: screenHeight * 0.0125),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
          child: ListTile(
            title: Text(
              item["day"] ?? "Unknown",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.0375,
                color: isHoliday ? Colors.red : Colors.black,
              ),
            ),
            subtitle: isHoliday
                ? Text("Holiday", style: TextStyle(color: Colors.red, fontSize: screenWidth * 0.035))
                : Text(
                    "🕒 ${formatTime(item["opening_time"])} - ${formatTime(item["closing_time"])}",
                    style: TextStyle(fontSize: screenWidth * 0.0325),
                  ),
          ),
        );
      },
    );
  }
}