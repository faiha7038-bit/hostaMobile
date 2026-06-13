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
  
  // Store ALL prescriptions from API
  List<dynamic> allPrescriptions = [];
  // Display filtered prescriptions
  List<dynamic> prescriptions = [];
  
  bool isLoading = true;
  final ApiService _apiService = ApiService();
  bool isRequestInProgress = false;
  bool _hasReachedEnd = false;
  Timer? _debounceTimer;
  bool _noMoreData = false;
  
  Map<int, String> patientNames = {};

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
      _applyLocalDateFilter();  // ✅ Local filter re-apply
    });
  }

  void _onScroll() {
    if (_debounceTimer?.isActive == true) return;
    if (!scrollController.hasClients) return;
    if (isFetchingMore || isRequestInProgress) return;
    if (_hasReachedEnd || _noMoreData) return;
    if (currentPage >= totalPages) return;
    if (prescriptions.isEmpty) return;
    
    if (scrollController.position.pixels >= 
        scrollController.position.maxScrollExtent - 200) {
      fetchMorePrescriptions();
    }
  }

  // ✅✅✅ LOCAL FILTER FUNCTION ✅✅✅
  void _applyLocalDateFilter() {
    print("🔍 Applying local filter...");
    print("📅 Selected date: $selectedDate");
    
    if (selectedDate == null) {
      // No filter - show all prescriptions
      prescriptions = List.from(allPrescriptions);
      print("📊 No filter - showing all ${prescriptions.length} items");
    } else {
      // Filter by selected date
      final filterDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      print("📅 Filter date: $filterDate");
      
      prescriptions = allPrescriptions.where((prescription) {
        final createdAt = prescription['createdAt'];
        if (createdAt == null) return false;
        
        final prescriptionDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(createdAt));
        final isMatch = prescriptionDate == filterDate;
        
        if (isMatch) {
          print("  ✅ Match: ID ${prescription['id']} - Date: $prescriptionDate");
        }
        
        return isMatch;
      }).toList();
      
      print("📊 Local filter found ${prescriptions.length} items for $filterDate");
    }
    
    // Reset pagination for filtered results
    currentPage = 1;
    totalPages = (prescriptions.length / 10).ceil();
    if (totalPages == 0) totalPages = 1;
    _hasReachedEnd = currentPage >= totalPages;
    _noMoreData = false;
    
    setState(() {});
  }

  Future<void> fetchPrescriptions() async {
    setState(() {
      isLoading = true;
      isFetchingMore = false;
      _hasReachedEnd = false;
      _noMoreData = false;
    });

    try {
      // Send date to API (optional, may not work)
      String? dateParam;
      if (selectedDate != null) {
        dateParam = DateFormat('yyyy-MM-dd').format(selectedDate!);
        print("📅 Sending date to API: $dateParam");
      }
      
      final response = await _apiService.getPrescriptions(
        userId: widget.userId,
        page: 1,
        limit: 100,  // Get all prescriptions
        date: dateParam,
      );

      print("✅ API Status: ${response.statusCode}");
      
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        print("📊 Total items from API: ${data.length}");
        
        // Store all data
        allPrescriptions = data;
        _fetchPatientNames(allPrescriptions);
        
        // ✅✅ Apply local filter (THIS IS THE KEY!) ✅✅
        _applyLocalDateFilter();
        
        print("📊 After local filter: ${prescriptions.length} items");
      }
    } catch (e) {
      print("❌ Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  void _fetchPatientNames(List<dynamic> prescriptionsList) {
    for (var prescription in prescriptionsList) {
      final patientId = prescription['patientId'];
      if (patientId != null && !patientNames.containsKey(patientId)) {
        if (prescription['patientName'] != null) {
          patientNames[patientId] = prescription['patientName'];
        } else {
          patientNames[patientId] = 'Patient $patientId';
        }
      }
    }
  }

  Future<void> fetchMorePrescriptions() async {
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

    // Simulate loading for pagination
    await Future.delayed(const Duration(milliseconds: 300));
    
    setState(() {
      currentPage++;
      _hasReachedEnd = currentPage >= totalPages;
      isFetchingMore = false;
      isRequestInProgress = false;
    });
  }

  List<dynamic> getCurrentPageItems() {
    int start = (currentPage - 1) * 10;
    int end = start + 10;
    if (start >= prescriptions.length) return [];
    if (end > prescriptions.length) end = prescriptions.length;
    return prescriptions.sublist(start, end);
  }

  Future<void> _downloadPrescription() async {
    if (prescriptions.isEmpty) return;
    
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Medical Prescription",
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              ...prescriptions.map((prescription) {
                final createdAt = prescription['createdAt'];
                final formattedDate = createdAt != null
                    ? DateFormat('dd MMM yyyy').format(DateTime.parse(createdAt))
                    : 'N/A';
                    
                // final doctorName = prescription['prescribedBy'] != null 
                //     ? prescription['prescribedBy'] 
                //     : 'Doctor ID: ${prescription['doctorId'] ?? 'N/A'}';
                final doctorName =
    prescription['prescribedBy'] ??
    prescription['doctorName'] ??
    'Doctor ID: ${prescription['doctorId'] ?? 'N/A'}';
                    
                final patientId = prescription['patientId'] ?? 'N/A';
                final patientName = patientNames[patientId] ?? 
                                    prescription['patientName'] ?? 
                                    'Patient $patientId';
                
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Doctor: $doctorName", 
                           style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text("Patient: $patientName", 
                           style: pw.TextStyle(fontSize: 12)),
                    pw.Text("Patient ID: $patientId", 
                           style: pw.TextStyle(fontSize: 12)),
                    pw.Text("Prescription ID: ${prescription['id']}", 
                           style: pw.TextStyle(fontSize: 12)),
                    pw.Text("Date: $formattedDate", 
                           style: pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 10),
                    pw.Text("Complaint: ${prescription['complaint'] ?? ''}",
                           style: pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 10),
                    pw.Text("Medicines:", 
                           style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    ...((prescription['medications'] ?? []) as List).map((med) {
                      return pw.Text(
                        "- ${med['name'] ?? med['medicine_name']} "
                        "(${med['dosage']}mg) "
                        "${med['frequency']} - ${med['timing']}",
                        style: pw.TextStyle(fontSize: 11),
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

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text("Prescription Preview"),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            body: PdfPreview(build: (format) => pdf.save()),
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Prescription PDF ready")),
      );
    }
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

    final currentItems = getCurrentPageItems();

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
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _dateController,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    print("📅 Date selected: ${DateFormat('yyyy-MM-dd').format(picked)}");
                    setState(() {
                      selectedDate = picked;
                      _dateController.text = DateFormat('dd MMM yyyy').format(picked);
                    });
                    // ✅ Apply local filter when date selected
                    _applyLocalDateFilter();
                  }
                },
                decoration: InputDecoration(
                  hintText: "Filter by date",
                  prefixIcon: const Icon(Icons.calendar_today, color: Colors.green),
                  suffixIcon: selectedDate != null
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: _clearDateFilter,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter indicator
            if (selectedDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_alt, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      "Filtered: ${DateFormat('dd MMM yyyy').format(selectedDate!)}",
                      style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 12),

            // Prescriptions List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : currentItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.medical_information, 
                                   size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                selectedDate != null 
                                    ? "No prescriptions found for ${DateFormat('dd MMM yyyy').format(selectedDate!)}"
                                    : "No prescriptions found",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                              ),
                              if (selectedDate != null) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _clearDateFilter,
                                  icon: const Icon(Icons.clear),
                                  label: const Text("Clear Filter"),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: currentItems.length + (isFetchingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < currentItems.length) {
                              final prescription = currentItems[index];
                              final meds = prescription['medications'] ?? [];
                              final createdAt = prescription['createdAt'];
                              final formattedDate = createdAt != null
                                  ? DateFormat('dd MMM yyyy').format(DateTime.parse(createdAt))
                                  : 'N/A';
                              
                              // final doctorName = prescription['prescribedBy'] != null 
                              //     ? prescription['prescribedBy'] 
                              //     : 'Doctor ID: ${prescription['doctorId'] ?? 'N/A'}';
                              final doctorName =
    prescription['prescribedBy'] ??
    prescription['doctorName'] ??
    'Doctor ID: ${prescription['doctorId'] ?? 'N/A'}';
                              final patientId = prescription['patientId'] ?? 'N/A';
                              final patientName = patientNames[patientId] ?? 
                                                  prescription['patientName'] ?? 
                                                  'Patient $patientId';

                              return Card(
                                margin: EdgeInsets.only(bottom: spacing),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.local_hospital,
                                              color: Colors.green,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.person, size: 16, color: Colors.green),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        doctorName,
                                                        style: TextStyle(
                                                          color: Colors.green,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: subtitleFontSize,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.person, size: 14, color: Colors.blue),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      patientName,
                                                      style: TextStyle(
                                                        fontSize: bodyFontSize,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.grey.shade800,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue.shade50,
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        "ID: $patientId",
                                                        style: TextStyle(
                                                          fontSize: smallFontSize,
                                                          color: Colors.blue.shade700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(Icons.receipt, size: 12, color: Colors.grey.shade500),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      "Prescription #${prescription['id']}",
                                                      style: TextStyle(
                                                        fontSize: smallFontSize,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      formattedDate,
                                                      style: TextStyle(
                                                        fontSize: smallFontSize,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Complaint",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              prescription['complaint'] ?? "No complaint mentioned",
                                              style: TextStyle(fontSize: bodyFontSize),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        "Medicines",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...meds.map((med) => Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.medication, size: 20, color: Colors.green),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    med['name'] ?? med['medicine_name'] ?? 'Unknown',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Wrap(
                                                    spacing: 12,
                                                    children: [
                                                      Text("${med['dosage']} mg", 
                                                           style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                                      Text(med['frequency'] ?? '', 
                                                           style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                                      Text(med['timing'] ?? '', 
                                                           style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                                      Text("${med['duration']} days", 
                                                           style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                      if (prescription['investigations'] != null && 
                                          (prescription['investigations'] as List).isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        const Text(
                                          "Investigations",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          children: (prescription['investigations'] as List).map((inv) {
                                            return Chip(
                                              label: Text(inv.toString()),
                                              backgroundColor: Colors.green.shade50,
                                              labelStyle: TextStyle(fontSize: smallFontSize),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                      if (prescription['advice'] != null && 
                                          prescription['advice'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        const Text(
                                          "Advice",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          prescription['advice'],
                                          style: TextStyle(fontSize: bodyFontSize),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            } else if (isFetchingMore) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
            ),

            Container(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: prescriptions.isEmpty ? null : _downloadPrescription,
                  icon: const Icon(Icons.download),
                  label: const Text(
                    "Download All Prescriptions (PDF)",
                    style: TextStyle(fontWeight: FontWeight.w600),
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
            ),
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
}