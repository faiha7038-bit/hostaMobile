import 'package:flutter/material.dart';

class LabReport extends StatefulWidget {
  const LabReport({super.key});

  @override
  State<LabReport> createState() => _LabReportState();
}

class _LabReportState extends State<LabReport> {
  DateTime? selectedDate;

  // 👉 Date Picker
  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // 👉 Date compare
  bool isSameDate(DateTime d1, DateTime d2) {
    return d1.day == d2.day && d1.month == d2.month && d1.year == d2.year;
  }

  @override
  Widget build(BuildContext context) {
    // 👉 demo report date (Collected on)
    DateTime reportDate = DateTime(2024, 6, 17);

    Widget _cell(String text, {bool isHeader = false, bool isHigh = false}) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          text,
          style: TextStyle(
            color: isHeader
                ? Colors.white
                : isHigh
                ? Colors.red
                : Colors.black87,
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    TableRow _row(
      String name,
      String result,
      String range,
      String unit, {
      bool isHigh = false,
    }) {
      return TableRow(
        children: [
          _cell(name),
          _cell(result, isHigh: isHigh),
          _cell(range),
          _cell(unit),
        ],
      );
    }

    // 👉 Filter condition
    bool showReport =
        selectedDate == null || isSameDate(selectedDate!, reportDate);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Lab Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👉 FILTER UI
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  //color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color:Colors.grey),
                  // boxShadow: [ BoxShadow(
                  //     color: Colors.black12,
                  //     blurRadius: 4,
                  //     offset: Offset(0, 2),
                  //   ),
                  // ],
                   
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.green, size: 20),
                    SizedBox(width: 10),

                    // 📅 Selected Date Text
                    Expanded(
                      child: Text(
                        selectedDate == null
                            ? "Select report date"
                            : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                        style: TextStyle(
                          fontSize: 14,
                          color: selectedDate == null
                              ? Colors.grey
                              : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // 🔁 Clear Button (optional but nice)
                    if (selectedDate != null)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDate = null;
                          });
                        },
                        child: Icon(Icons.close, size: 18, color: Colors.grey),
                      ),

                    SizedBox(width: 8),

                    // 🔍 Filter Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: pickDate,
                      child: Text(
                        "Filter",
                        style: TextStyle(fontSize: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
               SizedBox(height: 10),
              Divider(color: Colors.grey,),
             

              SizedBox(height: 10),

              // 👉 If date match → show report
              if (showReport) ...[
                Center(
                  child: Text(
                    "Dreams's Medical center",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    "123 Healthcare Avenue Medical District,City\n Phone +1(564)123-5676 | Email:info@dream.com",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                Divider(indent: 30, endIndent: 30, color: Colors.grey),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    "Pathology Laboratory Report",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                  ),
                ),
                Center(
                  child: Text(
                    "Accredited by NABL | ISO 15185:2024 certified",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                SizedBox(height: 15),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Doctor:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Dr.Jhon",
                                style: TextStyle(color: Colors.blueGrey),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "Type:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Blood Test",
                                style: TextStyle(color: Colors.blueGrey),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "LabNo:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                " #TE0025",
                                style: TextStyle(color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text(
                                "Collected on:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                " 17th June",
                                style: TextStyle(color: Colors.blueGrey),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "Reported on:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                " 17th June",
                                style: TextStyle(color: Colors.blueGrey),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                "Status:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Final",
                                style: TextStyle(color: Colors.blueGrey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 15),

                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Patient Information",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "PatientName",
                                  style: TextStyle(color: Colors.blueGrey),
                                ),
                                Text("James"),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  "PatientId",
                                  style: TextStyle(color: Colors.blueGrey),
                                ),
                                Text("PT008"),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  "Age/Gender",
                                  style: TextStyle(color: Colors.blueGrey),
                                ),
                                Text("34y/Male"),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  "BloodGroup",
                                  style: TextStyle(color: Colors.blueGrey),
                                ),
                                Text("AB+ve"),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Text(
                    "Test Result",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                // 👉 your table same
                Container(
                  margin: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Table(
                    columnWidths: {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(2),
                      3: FlexColumnWidth(1),
                    },
                    border: TableBorder(
                      horizontalInside: BorderSide(color: Colors.grey),
                    ),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.black),
                        children: [
                          _cell("Investigation", isHeader: true),
                          _cell("Result", isHeader: true),
                          _cell("Reference Range", isHeader: true),
                          _cell("Unit", isHeader: true),
                        ],
                      ),
                      _row("Neutrophils", "75", "50 - 62", "%", isHigh: true),
                      _row("Lymphocytes", "90", "20 - 40", "%", isHigh: true),
                      _row("Eosinophils", "60", "0 - 6", "%", isHigh: true),
                    ],
                  ),
                ),
              ] else ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "No reports found for selected date",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10))
                ),
                onPressed: (){}, child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    
                    Text("Download",style: TextStyle(color: Colors.white),),
                    Icon(Icons.download,color: Colors.white,)
                  ],
                ))
            ],
          ),
        ),
      ),
    );
  }
}
