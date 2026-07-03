import 'package:flutter/material.dart';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

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

    // Responsive clamped values used throughout
    final double padding = _clamp(screenWidth * 0.04, 12, 24);
    final double cardMarginBottom = _clamp(screenHeight * 0.0125, 8, 20);
    final double cardRadius = _clamp(screenWidth * 0.03, 8, 20);
    final double titleFontSize = _clamp(screenWidth * 0.0375, 14, 22);
    final double subtitleFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double detailsFontSize = _clamp(screenWidth * 0.0325, 11, 17);
    final double elevation = _clamp(screenWidth * 0.005, 2, 6);
    final double emptyFontSize = _clamp(screenWidth * 0.04, 14, 22);

    // 👇 Check all possible working hours formats
    final workingHoursClinic = hospital["working_hours_clinic"] as List?;
    final workingHoursGeneral = hospital["working_hours_general"] as List?;
    final workingHoursClinicNoBreak = hospital["working_hours_clinic_nobreak"] as List?;

    if (workingHoursClinic != null && workingHoursClinic.isNotEmpty) {
      return _buildHoursTabClinicFormat(
        workingHoursClinic,
        padding,
        cardMarginBottom,
        cardRadius,
        titleFontSize,
        subtitleFontSize,
        detailsFontSize,
        elevation,
      );
    } else if (workingHoursClinicNoBreak != null &&
        workingHoursClinicNoBreak.isNotEmpty) {
      return _buildHoursTabClinicNoBreakFormat(
        workingHoursClinicNoBreak,
        padding,
        cardMarginBottom,
        cardRadius,
        titleFontSize,
        subtitleFontSize,
        detailsFontSize,
        elevation,
      );
    } else if (workingHoursGeneral != null && workingHoursGeneral.isNotEmpty) {
      return _buildHoursTabGeneralFormat(
        workingHoursGeneral,
        padding,
        cardMarginBottom,
        cardRadius,
        titleFontSize,
        subtitleFontSize,
        detailsFontSize,
        elevation,
      );
    } else {
      return Center(
        child: Text(
          "No working hours available",
          style: TextStyle(fontSize: emptyFontSize),
        ),
      );
    }
  }

  // ✅ Clinic format with morning/evening sessions (has_break possible)
  Widget _buildHoursTabClinicFormat(
    List<dynamic> hoursList,
    double padding,
    double cardMarginBottom,
    double cardRadius,
    double titleFontSize,
    double subtitleFontSize,
    double detailsFontSize,
    double elevation,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(padding),
      itemCount: hoursList.length,
      itemBuilder: (context, index) {
        final item = hoursList[index];
        final isHoliday = item["is_holiday"] == true;
        final morningSession = item["morning_session"];
        final eveningSession = item["evening_session"];

        return Card(
          elevation: elevation,
          margin: EdgeInsets.only(bottom: cardMarginBottom),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          child: ListTile(
            title: Text(
              item["day"] ?? "Unknown",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: titleFontSize,
                color: isHoliday ? Colors.red : Colors.black,
              ),
            ),
            subtitle: isHoliday
                ? Text(
                    "Holiday",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: subtitleFontSize,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (morningSession != null &&
                          morningSession["open"] != null &&
                          morningSession["open"].toString().isNotEmpty)
                        Text(
                          "🌅 Morning: ${formatTime(morningSession["open"])} - ${formatTime(morningSession["close"])}",
                          style: TextStyle(fontSize: detailsFontSize),
                        ),
                      if (eveningSession != null &&
                          eveningSession["open"] != null &&
                          eveningSession["open"].toString().isNotEmpty)
                        Text(
                          "🌇 Evening: ${formatTime(eveningSession["open"])} - ${formatTime(eveningSession["close"])}",
                          style: TextStyle(fontSize: detailsFontSize),
                        ),
                      if (item["has_break"] == true)
                        Text(
                          "⏸️ Has break time",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: detailsFontSize,
                          ),
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // ✅ General format (single slot per day)
  Widget _buildHoursTabGeneralFormat(
    List<dynamic> hoursList,
    double padding,
    double cardMarginBottom,
    double cardRadius,
    double titleFontSize,
    double subtitleFontSize,
    double detailsFontSize,
    double elevation,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(padding),
      itemCount: hoursList.length,
      itemBuilder: (context, index) {
        final item = hoursList[index];
        final isHoliday = item["is_holiday"] == true;

        String displayText = "";
        if (item["opening_time"] != null && item["closing_time"] != null) {
          displayText =
              "🕒 ${formatTime(item["opening_time"])} - ${formatTime(item["closing_time"])}";
        } else if (item["hours"] != null && item["hours"].toString().contains("-")) {
          final parts = item["hours"].split("-");
          if (parts.length == 2) {
            displayText =
                "🕒 ${formatTime(parts[0].trim())} - ${formatTime(parts[1].trim())}";
          } else {
            displayText = item["hours"];
          }
        } else {
          displayText = "Timings not specified";
        }

        return Card(
          elevation: elevation,
          margin: EdgeInsets.only(bottom: cardMarginBottom),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          child: ListTile(
            title: Text(
              item["day"] ?? "Unknown",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: titleFontSize,
                color: isHoliday ? Colors.red : Colors.black,
              ),
            ),
            subtitle: isHoliday
                ? Text(
                    "Holiday",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: subtitleFontSize,
                    ),
                  )
                : Text(
                    displayText,
                    style: TextStyle(fontSize: detailsFontSize),
                  ),
          ),
        );
      },
    );
  }

  // ✅ Clinic no-break format (similar to general but field name may differ)
  Widget _buildHoursTabClinicNoBreakFormat(
    List<dynamic> hoursList,
    double padding,
    double cardMarginBottom,
    double cardRadius,
    double titleFontSize,
    double subtitleFontSize,
    double detailsFontSize,
    double elevation,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(padding),
      itemCount: hoursList.length,
      itemBuilder: (context, index) {
        final item = hoursList[index];
        final isHoliday = item["is_holiday"] == true;

        return Card(
          elevation: elevation,
          margin: EdgeInsets.only(bottom: cardMarginBottom),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          child: ListTile(
            title: Text(
              item["day"] ?? "Unknown",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: titleFontSize,
                color: isHoliday ? Colors.red : Colors.black,
              ),
            ),
            subtitle: isHoliday
                ? Text(
                    "Holiday",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: subtitleFontSize,
                    ),
                  )
                : Text(
                    "🕒 ${formatTime(item["opening_time"])} - ${formatTime(item["closing_time"])}",
                    style: TextStyle(fontSize: detailsFontSize),
                  ),
          ),
        );
      },
    );
  }
}