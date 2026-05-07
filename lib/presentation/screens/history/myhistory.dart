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
    List<String> selectedReports =
        selectedDay == null ? [] : getReportsForDay(selectedDay!);

    Map<String, String>? visit =
        selectedDay == null ? null : getVisitForDay(selectedDay!);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.green,
        title: const Text(
          "My History",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            // 📅 CALENDAR
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 5)
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
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.green.shade200,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            // 📅 Selected Date
            if (selectedDay != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      "${selectedDay!.day}-${selectedDay!.month}-${selectedDay!.year}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // 📄 REPORT CARD
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [

                  if (selectedReports.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 5)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            children: const [
                              Icon(Icons.description, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                "Report Details",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                          const Divider(height: 20),

                          ...selectedReports.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle,
                                      size: 8, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(e)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("No reports"),
                    ),

                  // 🏥 VISIT CARD
                  if (visit != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 5)
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            children: const [
                              Icon(Icons.local_hospital,
                                  color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                "Hospital Visit",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),

                          const Divider(height: 20),

                          Row(
                            children: [
                              const Icon(Icons.business,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(visit["hospital"] ?? "")),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Icon(Icons.person,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(visit["doctor"] ?? ""),
                            ],
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              const Icon(Icons.science,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(visit["type"] ?? ""),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text(
                        "No hospital visit",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}