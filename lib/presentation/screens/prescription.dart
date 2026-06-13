import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hosta/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrescriptionDetailsScreen extends StatefulWidget {
  final String userId;
  const PrescriptionDetailsScreen({super.key, required this.userId});

  @override
  State<PrescriptionDetailsScreen> createState() =>
      _PrescriptionDetailsScreenState();
}

class _PrescriptionDetailsScreenState extends State<PrescriptionDetailsScreen> {
  int currentPage = 1;
  int totalPages = 1;
  bool isFetchingMore = false;
  ScrollController scrollController = ScrollController();
  final TextEditingController _dateController = TextEditingController();
  DateTime? selectedDate;
  List<dynamic> prescriptions = [];
  bool isLoading = true;
  final ApiService _apiService = ApiService();
  bool isRequestInProgress = false;
  bool _hasReachedEnd = false;
  Timer? _debounceTimer;
bool _noMoreData = false; // add this with other variables
  @override
  void initState() {
    super.initState();
    scrollController.addListener(_onScroll);
    fetchPrescriptions();
  }

  @override
  void dispose() {
    scrollController.dispose();
    _dateController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

void _clearDateFilter() {
  setState(() {
    selectedDate = null;
    _dateController.clear();
    prescriptions.clear();
    currentPage = 1;
    totalPages = 1;
    _hasReachedEnd = false;
    _noMoreData = false;   // add
  });
  fetchPrescriptions();
}

void _onScroll() {
  if (_debounceTimer?.isActive == true) return;
  if (!scrollController.hasClients) return;
  if (isFetchingMore || isRequestInProgress) return;
  if (_hasReachedEnd || _noMoreData) return;   // added _noMoreData
  if (currentPage >= totalPages) return;
  if (prescriptions.isEmpty) return;
  // ... rest unchanged
}

  Future<void> fetchPrescriptions() async {
   setState(() {
    isLoading = true;
    isFetchingMore = false;
    _hasReachedEnd = false;
    _noMoreData = false;   // reset
  });

    try {
      final response = await _apiService.getPrescriptions(
        userId: widget.userId,
        page: 1,
        limit: 10,
        // date: selectedDate != null
        //     ? DateFormat('yyyy-MM-dd').format(selectedDate!)
        //     : null,
      );

      if (response.statusCode == 200) {
        setState(() {
          prescriptions = response.data['data'];
          totalPages = response.data['pagination']['totalPages'];
          currentPage = 1;
          _hasReachedEnd = currentPage >= totalPages;
        });
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

Future<void> fetchMorePrescriptions() async {
  // Stop if already loading, reached end, or no more data
  if (isFetchingMore || isRequestInProgress) return;
  if (_hasReachedEnd || _noMoreData) return;
  if (currentPage >= totalPages) {
    setState(() => _hasReachedEnd = true);
    return;
  }

  setState(() {
    isFetchingMore = true;
    isRequestInProgress = true;
  });

  try {
    final nextPage = currentPage + 1;
    print("📡 Loading page $nextPage of $totalPages");
    final response = await _apiService.getPrescriptions(
      userId: widget.userId,
      page: nextPage,
      limit: 10,
      // date: selectedDate != null
      //     ? DateFormat('yyyy-MM-dd').format(selectedDate!)
      //     : null,
    );

    if (response.statusCode == 200) {
      final newData = response.data['data'] as List;
      final pagination = response.data['pagination'];
      final newTotalPages = pagination['totalPages'];

      // 🔥 CRITICAL: If the returned data has fewer than 10 items, it's the last page
      if (newData.length < 10) {
        _noMoreData = true;
      }

      setState(() {
        prescriptions.addAll(newData);
        currentPage = nextPage;
        totalPages = newTotalPages;
        _hasReachedEnd = currentPage >= totalPages || _noMoreData;
      });
    }
  } catch (e) {
    print(e);
    // On error, assume no more data to avoid endless retries
    setState(() => _noMoreData = true);
  } finally {
    if (mounted) {
      setState(() {
        isFetchingMore = false;
        isRequestInProgress = false;
      });
    }
  }
}

  Future<void> _downloadPrescription() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Medical Prescription",
                style: pw.TextStyle(fontSize: 20),
              ),
              pw.SizedBox(height: 20),
              ...prescriptions.map((prescription) {
                final createdAt = prescription['createdAt'];
                final formattedDate = createdAt != null
                    ? DateFormat('dd MMM yyyy').format(DateTime.parse(createdAt))
                    : 'N/A';
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Doctor: ${prescription['prescribedBy'] ?? 'N/A'}"),
                    pw.Text("Patient: ${prescription['patientName'] ?? 'N/A'}"),
                    pw.Text("Date: $formattedDate"),
                    pw.SizedBox(height: 10),
                    pw.Text("Complaint: ${prescription['complaint'] ?? ''}"),
                    pw.SizedBox(height: 10),
                    pw.Text("Medicines:", style: pw.TextStyle(fontSize: 16)),
                    pw.SizedBox(height: 10),
                    ...((prescription['medications'] ?? []) as List).map((med) {
                      return pw.Text(
                        "${med['name'] ?? med['medicine_name']} "
                        "- ${med['dosage']} "
                        "- ${med['frequency']} "
                        "- ${med['timing']}",
                      );
                    }),
                    pw.SizedBox(height: 25),
                    pw.Divider(),
                    pw.SizedBox(height: 15),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/prescription.pdf");
    await file.writeAsBytes(await pdf.save());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text("Prescription Preview"),
            backgroundColor: Colors.green,
          ),
          body: PdfPreview(build: (format) => pdf.save()),
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Prescription downloaded successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;

    final titleFontSize = isDesktop ? 22.0 : (isTablet ? 20.0 : 18.0);
    final subtitleFontSize = isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0);
    final bodyFontSize = isDesktop ? 14.0 : (isTablet ? 13.0 : 12.0);
    final smallFontSize = isDesktop ? 12.0 : (isTablet ? 11.0 : 10.0);
    final spacing = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Prescription Details',
          style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w600),
        ),
        actions: [
          _appBarAction(Icons.print, 'Print', isSmallScreen),
          _appBarAction(Icons.download, 'Download', isSmallScreen),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // Filter Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: TextField(
                controller: _dateController,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                if (picked != null) {
  setState(() {
    selectedDate = picked;
    _dateController.text = DateFormat('dd MMM yyyy').format(picked);
    prescriptions.clear();
    currentPage = 1;
    totalPages = 1;
    _hasReachedEnd = false;
    _noMoreData = false;   // add
  });
  fetchPrescriptions();
}
                },
                decoration: InputDecoration(
                  hintText: "Filter by date",
                  prefixIcon: Icon(Icons.calendar_today, color: Colors.green),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                  suffixIcon: selectedDate != null
                      ? IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: _clearDateFilter,
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(height: spacing),

            // Medical Center Card
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : prescriptions.isEmpty
                      ? const Center(child: Text("No prescriptions found"))
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: prescriptions.length +
                              (isFetchingMore || (_hasReachedEnd && prescriptions.isNotEmpty) ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < prescriptions.length) {
                              final prescription = prescriptions[index];
                              final meds = prescription['medications'] ?? [];
                              final createdAt = prescription['createdAt'];
                              final formattedDate = createdAt != null
                                  ? DateFormat('dd MMM yyyy').format(DateTime.parse(createdAt))
                                  : 'N/A';

                              return Padding(
                                padding: EdgeInsets.only(bottom: spacing),
                                child: _buildCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // HEADER
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.local_hospital,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                prescription['prescribedBy'] ?? "Doctor Not Available",
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: subtitleFontSize,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Prescription ID : ${prescription['id']}",
                                                style: TextStyle(
                                                  fontSize: bodyFontSize,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              Text(
                                                formattedDate,
                                                style: TextStyle(
                                                  fontSize: bodyFontSize,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: spacing),

                                      // COMPLAINT
                                      Text(
                                        "Complaint",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: bodyFontSize,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        prescription['complaint'] ?? "N/A",
                                        style: TextStyle(fontSize: bodyFontSize),
                                      ),
                                      SizedBox(height: spacing),

                                      // MEDICINES
                                      Text(
                                        "Medicines",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: subtitleFontSize,
                                          color: Colors.green,
                                        ),
                                      ),
                                      SizedBox(height: spacing * 0.5),
                                      Column(
                                        children: meds.map<Widget>((med) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12),
                                            child: _medicineCard(
                                              color: Colors.green,
                                              name: med['name'] ??
                                                  med['medicine_name'] ??
                                                  'Unknown Medicine',
                                              dosage: med['dosage'] ?? '',
                                              days: med['duration'] ?? '',
                                              time: med['timing'] ?? '',
                                              freq: med['frequency'] ?? '',
                                              bodyFontSize: bodyFontSize,
                                              smallFontSize: smallFontSize,
                                              isSmallScreen: isSmallScreen,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              // Bottom: loader or end message
                              if (isFetchingMore) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              } else if (_hasReachedEnd && prescriptions.isNotEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      "✨ No more prescriptions",
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }
                          },
                        ),
            ),

            // Download Button
            SizedBox(
              width: double.infinity,
              height: isSmallScreen ? 45 : 50,
              child: ElevatedButton.icon(
                onPressed: _downloadPrescription,
                icon: Icon(Icons.download, size: isSmallScreen ? 18 : 20),
                label: Text(
                  "Download Prescription (PDF)",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: bodyFontSize,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: spacing),
          ],
        ),
      ),
    );
  }

  Widget _appBarAction(IconData icon, String label, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isSmallScreen ? 18 : 20),
          Text(label, style: TextStyle(fontSize: isSmallScreen ? 9 : 11)),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _medicineCard({
    required Color color,
    required String name,
    required String dosage,
    required String days,
    required String time,
    required String freq,
    required double bodyFontSize,
    required double smallFontSize,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.medication,
                  color: color,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: bodyFontSize + 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      _chip(dosage, color, smallFontSize),
                      _chip(days, Colors.grey, smallFontSize),
                    ],
                  ),
                ],
              ),
              if (!isSmallScreen)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$days days",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: smallFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    time == "Morning"
                        ? Icons.wb_sunny_outlined
                        : Icons.nights_stay_outlined,
                    size: isSmallScreen ? 14 : 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(time, style: TextStyle(fontSize: bodyFontSize)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh,
                    size: isSmallScreen ? 14 : 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 6),
                  Text(freq, style: TextStyle(fontSize: bodyFontSize)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$days Days",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: smallFontSize - 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color, double fontSize) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}