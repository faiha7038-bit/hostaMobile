
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime today = DateTime.now();
  DateTime? selectedDay;

  // 🔥 Report Data
  Map<DateTime, List<String>> reports = {
    DateTime(2024, 6, 17): ["Blood Test - Dreams Medical", "Urine Test"],
    DateTime(2024, 6, 18): ["X-Ray - City Hospital"],
    DateTime(2024, 6, 20): ["MRI Scan"],
    DateTime(2026, 5, 5): ["Blood Test - Aster Lab"],
  };

  // 🔥 Hospital Visit Data
  Map<DateTime, Map<String, String>> visits = {
    DateTime(2024, 6, 17): {
      "hospital": "Dreams Medical Center",
      "doctor": "Dr. John",
      "type": "Blood Test"
    },
    DateTime(2024, 6, 18): {
      "hospital": "City Hospital",
      "doctor": "Dr. Alex",
      "type": "X-Ray"
    },
    DateTime(2026, 5, 5): {
      "hospital": "Aster Hospital",
      "doctor": "Dr. Rahul",
      "type": "Blood Test"
    },
  };

  @override
  void initState() {
    super.initState();

    // 👉 Default select first available date
    if (reports.isNotEmpty) {
      selectedDay = reports.keys.first;
      today = selectedDay!;
    }
  }

  List<String> getReportsForDay(DateTime day) {
    return reports[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Map<String, String>? getVisitForDay(DateTime day) {
    return visits[DateTime(day.year, day.month, day.day)];
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final padding = MediaQuery.of(context).padding;
    final isSmallScreen = screenWidth < 600;
    final isLargeScreen = screenWidth > 1200;

    List<String> selectedReports =
        selectedDay == null ? [] : getReportsForDay(selectedDay!);

    Map<String, String>? visit =
        selectedDay == null ? null : getVisitForDay(selectedDay!);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green,
        toolbarHeight: isSmallScreen ? 56 : 70,
        title: Text(
          "My History",
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 20 : 24,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new, 
            color: Colors.white,
            size: isSmallScreen ? 24 : 28,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? screenWidth * 0.1 : 0,
          ),
          child: Column(
            children: [
              // 📅 CALENDAR
              Container(
                margin: EdgeInsets.all(screenWidth * 0.025),
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 15 : 20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12, 
                      blurRadius: isSmallScreen ? 5 : 8,
                      spreadRadius: isSmallScreen ? 0 : 1,
                    )
                  ],
                ),
                child: TableCalendar(
                  focusedDay: today,
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2030),
                  selectedDayPredicate: (day) =>
                      isSameDay(selectedDay, day),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      selectedDay = selected;
                      today = focused;
                    });
                  },
                  daysOfWeekHeight: isSmallScreen ? 30 : 40,
                  calendarStyle: CalendarStyle(
                    cellMargin: EdgeInsets.all(isSmallScreen ? 4 : 6),
                    defaultTextStyle: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                    weekendTextStyle: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                    todayTextStyle: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                    selectedTextStyle: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                    outsideTextStyle: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.grey,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Colors.green.shade200,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                    leftChevronIcon: Icon(
                      Icons.chevron_left,
                      size: isSmallScreen ? 28 : 32,
                    ),
                    rightChevronIcon: Icon(
                      Icons.chevron_right,
                      size: isSmallScreen ? 28 : 32,
                    ),
                  ),
                ),
              ),

              // 📅 Selected Date
              if (selectedDay != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.0375),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month, 
                        color: Colors.green,
                        size: isSmallScreen ? 24 : 28,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        "${selectedDay!.day}-${selectedDay!.month}-${selectedDay!.year}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: isSmallScreen ? 16 : 18,
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: screenHeight * 0.015),

              // 📄 REPORT CARD
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.03),
                child: Column(
                  children: [
                    if (selectedReports.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.035),
                        margin: EdgeInsets.only(bottom: screenHeight * 0.015),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12, 
                              blurRadius: isSmallScreen ? 5 : 8,
                              spreadRadius: isSmallScreen ? 0 : 1,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.description, 
                                  color: Colors.green,
                                  size: isSmallScreen ? 24 : 28,
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  "Report Details",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 16 : 18,
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              height: screenHeight * 0.025,
                              thickness: isSmallScreen ? 1 : 1.5,
                            ),
                            ...selectedReports.map(
                              (e) => Padding(
                                padding: EdgeInsets.only(bottom: screenHeight * 0.01),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: isSmallScreen ? 8 : 10, 
                                      color: Colors.green
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Expanded(
                                      child: Text(
                                        e,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 14 : 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.all(screenHeight * 0.025),
                        child: Text(
                          "No reports",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),

                    // 🏥 VISIT CARD
                    if (visit != null)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.035),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12, 
                              blurRadius: isSmallScreen ? 5 : 8,
                              spreadRadius: isSmallScreen ? 0 : 1,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.local_hospital,
                                  color: Colors.green,
                                  size: isSmallScreen ? 24 : 28,
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  "Hospital Visit",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 16 : 18,
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              height: screenHeight * 0.025,
                              thickness: isSmallScreen ? 1 : 1.5,
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.business,
                                  size: isSmallScreen ? 18 : 20, 
                                  color: Colors.grey
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Expanded(
                                  child: Text(
                                    visit["hospital"] ?? "",
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: isSmallScreen ? 18 : 20, 
                                  color: Colors.grey
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  visit["doctor"] ?? "",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Row(
                              children: [
                                Icon(
                                  Icons.science,
                                  size: isSmallScreen ? 18 : 20, 
                                  color: Colors.grey
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Text(
                                  visit["type"] ?? "",
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.025),
                        child: Text(
                          "No hospital visit",
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}