// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:hosta/services/api_service.dart';
// import 'package:intl/intl.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

// class PrescriptionDetailsScreen extends StatefulWidget {
//   final String userId;
//   const PrescriptionDetailsScreen({super.key, required this.userId});

//   @override
//   State<PrescriptionDetailsScreen> createState() =>
//       _PrescriptionDetailsScreenState();
// }

// class _PrescriptionDetailsScreenState extends State<PrescriptionDetailsScreen> {
//   int currentPage = 1;
//   int totalPages = 1;
//   bool isFetchingMore = false;
//   ScrollController scrollController = ScrollController();
//   final TextEditingController _dateController = TextEditingController();
//   DateTime? selectedDate;

//   // Store ALL prescriptions from API
//   List<dynamic> allPrescriptions = [];
//   // Display filtered prescriptions
//   List<dynamic> prescriptions = [];

//   bool isLoading = true;
//   final ApiService _apiService = ApiService();
//   bool isRequestInProgress = false;
//   bool _hasReachedEnd = false;
//   Timer? _debounceTimer;
//   bool _noMoreData = false;

//   Map<int, String> patientNames = {};

//   @override
//   void initState() {
//     super.initState();
//     scrollController.addListener(_onScroll);
//     fetchPrescriptions();
//   }

//   @override
//   void dispose() {
//     scrollController.dispose();
//     _dateController.dispose();
//     _debounceTimer?.cancel();
//     super.dispose();
//   }

//   void _clearDateFilter() {
//     setState(() {
//       selectedDate = null;
//       _dateController.clear();
//       _applyLocalDateFilter();  // ✅ Local filter re-apply
//     });
//   }

//   void _onScroll() {
//     if (_debounceTimer?.isActive == true) return;
//     if (!scrollController.hasClients) return;
//     if (isFetchingMore || isRequestInProgress) return;
//     if (_hasReachedEnd || _noMoreData) return;
//     if (currentPage >= totalPages) return;
//     if (prescriptions.isEmpty) return;

//     if (scrollController.position.pixels >=
//         scrollController.position.maxScrollExtent - 200) {
//       fetchMorePrescriptions();
//     }
//   }

//   // ✅✅✅ LOCAL FILTER FUNCTION ✅✅✅
//   void _applyLocalDateFilter() {
//     print("🔍 Applying local filter...");
//     print("📅 Selected date: $selectedDate");

//     if (selectedDate == null) {
//       // No filter - show all prescriptions
//       prescriptions = List.from(allPrescriptions);
//       print("📊 No filter - showing all ${prescriptions.length} items");
//     } else {
//       // Filter by selected date
//       final filterDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
//       print("📅 Filter date: $filterDate");

//       prescriptions = allPrescriptions.where((prescription) {
//         final createdAt = prescription['createdAt'];
//         if (createdAt == null) return false;

//         final prescriptionDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(createdAt));
//         final isMatch = prescriptionDate == filterDate;

//         if (isMatch) {
//           print("  ✅ Match: ID ${prescription['id']} - Date: $prescriptionDate");
//         }

//         return isMatch;
//       }).toList();

//       print("📊 Local filter found ${prescriptions.length} items for $filterDate");
//     }

//     // Reset pagination for filtered results
//     currentPage = 1;
//     totalPages = (prescriptions.length / 10).ceil();
//     if (totalPages == 0) totalPages = 1;
//     _hasReachedEnd = currentPage >= totalPages;
//     _noMoreData = false;

//     setState(() {});
//   }

//   Future<void> fetchPrescriptions() async {
//     setState(() {
//       isLoading = true;
//       isFetchingMore = false;
//       _hasReachedEnd = false;
//       _noMoreData = false;
//     });

//     try {
//       // Send date to API (optional, may not work)
//       String? dateParam;
//       if (selectedDate != null) {
//         dateParam = DateFormat('yyyy-MM-dd').format(selectedDate!);
//         print("📅 Sending date to API: $dateParam");
//       }

//       final response = await _apiService.getPrescriptions(
//         userId: widget.userId,
//         page: 1,
//         limit: 100,  // Get all prescriptions
//       //  date: dateParam,
//       );

//       print("✅ API Status: ${response.statusCode}");

//       if (response.statusCode == 200) {
//         final data = response.data['data'] as List;
//         print("📊 Total items from API: ${data.length}");

//         // Store all data
//         allPrescriptions = data;
//         _fetchPatientNames(allPrescriptions);

//         // ✅✅ Apply local filter (THIS IS THE KEY!) ✅✅
//         _applyLocalDateFilter();

//         print("📊 After local filter: ${prescriptions.length} items");
//       }
//     } catch (e) {
//       print("❌ Error: $e");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   void _fetchPatientNames(List<dynamic> prescriptionsList) {
//     for (var prescription in prescriptionsList) {
//       final patientId = prescription['patientId'];
//       if (patientId != null && !patientNames.containsKey(patientId)) {
//         if (prescription['patientName'] != null) {
//           patientNames[patientId] = prescription['patientName'];
//         } else {
//           patientNames[patientId] = 'Patient $patientId';
//         }
//       }
//     }
//   }

//   Future<void> fetchMorePrescriptions() async {
//     if (isFetchingMore || isRequestInProgress) return;
//     if (_hasReachedEnd || _noMoreData) return;
//     if (currentPage >= totalPages) {
//       setState(() => _hasReachedEnd = true);
//       return;
//     }

//     setState(() {
//       isFetchingMore = true;
//       isRequestInProgress = true;
//     });

//     // Simulate loading for pagination
//     await Future.delayed(const Duration(milliseconds: 300));

//     setState(() {
//       currentPage++;
//       _hasReachedEnd = currentPage >= totalPages;
//       isFetchingMore = false;
//       isRequestInProgress = false;
//     });
//   }

//   List<dynamic> getCurrentPageItems() {
//     int start = (currentPage - 1) * 10;
//     int end = start + 10;
//     if (start >= prescriptions.length) return [];
//     if (end > prescriptions.length) end = prescriptions.length;
//     return prescriptions.sublist(start, end);
//   }

//   Future<void> _downloadPrescription() async {
//     if (prescriptions.isEmpty) return;

//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.Page(
//         build: (context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text(
//                 "Medical Prescription",
//                 style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
//               ),
//               pw.SizedBox(height: 20),
//               ...prescriptions.map((prescription) {
//                 final createdAt = prescription['createdAt'];
//                 final formattedDate = createdAt != null
//                     ? DateFormat('dd MMM yyyy').format(DateTime.parse(createdAt))
//                     : 'N/A';

//                 // final doctorName = prescription['prescribedBy'] != null
//                 //     ? prescription['prescribedBy']
//                 //     : 'Doctor ID: ${prescription['doctorId'] ?? 'N/A'}';
//                 final doctorName =
//     prescription['prescribedBy'] ??
//     prescription['doctorName'] ??
//     'Doctor ID: ${prescription['doctorId'] ?? 'N/A'}';

//                 final patientId = prescription['patientId'] ?? 'N/A';
//                 final patientName = patientNames[patientId] ??
//                                     prescription['patientName'] ??
//                                     'Patient $patientId';

//                 return pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text("Doctor: $doctorName",
//                            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
//                     pw.Text("Patient: $patientName",
//                            style: pw.TextStyle(fontSize: 12)),
//                     pw.Text("Patient ID: $patientId",
//                            style: pw.TextStyle(fontSize: 12)),
//                     pw.Text("Prescription ID: ${prescription['id']}",
//                            style: pw.TextStyle(fontSize: 12)),
//                     pw.Text("Date: $formattedDate",
//                            style: pw.TextStyle(fontSize: 12)),
//                     pw.SizedBox(height: 10),
//                     pw.Text("Complaint: ${prescription['complaint'] ?? ''}",
//                            style: pw.TextStyle(fontSize: 12)),
//                     pw.SizedBox(height: 10),
//                     pw.Text("Medicines:",
//                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
//                     pw.SizedBox(height: 10),
//                     ...((prescription['medications'] ?? []) as List).map((med) {
//                       return pw.Text(
//                         "- ${med['name'] ?? med['medicine_name']} "
//                         "(${med['dosage']}mg) "
//                         "${med['frequency']} - ${med['timing']}",
//                         style: pw.TextStyle(fontSize: 11),
//                       );
//                     }),
//                     pw.SizedBox(height: 25),
//                     pw.Divider(),
//                     pw.SizedBox(height: 15),
//                   ],
//                 );
//               }),
//             ],
//           );
//         },
//       ),
//     );

//     final dir = await getApplicationDocumentsDirectory();
//     final file = File("${dir.path}/prescription.pdf");
//     await file.writeAsBytes(await pdf.save());

//     if (mounted) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => Scaffold(
//             appBar: AppBar(
//               title: const Text("Prescription Preview"),
//               backgroundColor: Colors.green,
//               foregroundColor: Colors.white,
//             ),
//             body: PdfPreview(build: (format) => pdf.save()),
//           ),
//         ),
//       );

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Prescription PDF ready")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     final screenWidth = screenSize.width;
//     final isSmallScreen = screenWidth < 600;
//     final isTablet = screenWidth >= 600 && screenWidth < 1200;
//     final isDesktop = screenWidth >= 1200;

//     final titleFontSize = isDesktop ? 22.0 : (isTablet ? 20.0 : 18.0);
//     final subtitleFontSize = isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0);
//     final bodyFontSize = isDesktop ? 14.0 : (isTablet ? 13.0 : 12.0);
//     final smallFontSize = isDesktop ? 12.0 : (isTablet ? 11.0 : 10.0);
//     final spacing = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);

//     final currentItems = getCurrentPageItems();

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FC),
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           'Prescription Details',
//           style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w600),
//         ),
//         actions: [
//           _appBarAction(Icons.print, 'Print', isSmallScreen),
//           _appBarAction(Icons.download, 'Download', isSmallScreen),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(10.0),
//         child: Column(
//           children: [
//             // Filter Section
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 5,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: TextField(
//                 controller: _dateController,
//                 readOnly: true,
//                 onTap: () async {
//                   final picked = await showDatePicker(
//                     context: context,
//                     initialDate: selectedDate ?? DateTime.now(),
//                     firstDate: DateTime(2020),
//                     lastDate: DateTime(2030),
//                   );
//                   if (picked != null) {
//                     print("📅 Date selected: ${DateFormat('yyyy-MM-dd').format(picked)}");
//                     setState(() {
//                       selectedDate = picked;
//                       _dateController.text = DateFormat('dd MMM yyyy').format(picked);
//                     });
//                     // ✅ Apply local filter when date selected
//                     _applyLocalDateFilter();
//                   }
//                 },
//                 decoration: InputDecoration(
//                   hintText: "Filter by date",
//                   prefixIcon: const Icon(Icons.calendar_today, color: Colors.green),
//                   suffixIcon: selectedDate != null
//                       ? IconButton(
//                           icon: const Icon(Icons.close, color: Colors.red),
//                           onPressed: _clearDateFilter,
//                         )
//                       : null,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide.none,
//                   ),
//                   filled: true,
//                   fillColor: Colors.grey.shade50,
//                   contentPadding: const EdgeInsets.symmetric(vertical: 16),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),

//             // Filter indicator
//             if (selectedDate != null)
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade50,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(Icons.filter_alt, size: 16, color: Colors.green),
//                     const SizedBox(width: 8),
//                     Text(
//                       "Filtered: ${DateFormat('dd MMM yyyy').format(selectedDate!)}",
//                       style: TextStyle(fontSize: 12, color: Colors.green.shade700),
//                     ),
//                   ],
//                 ),
//               ),

//             const SizedBox(height: 12),

//             // Prescriptions List
//             Expanded(
//               child: isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   : currentItems.isEmpty
//                       ? Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.medical_information,
//                                    size: 64, color: Colors.grey.shade400),
//                               const SizedBox(height: 16),
//                               Text(
//                                 selectedDate != null
//                                     ? "No prescriptions found for ${DateFormat('dd MMM yyyy').format(selectedDate!)}"
//                                     : "No prescriptions found",
//                                 style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
//                               ),
//                               if (selectedDate != null) ...[
//                                 const SizedBox(height: 8),
//                                 TextButton.icon(
//                                   onPressed: _clearDateFilter,
//                                   icon: const Icon(Icons.clear),
//                                   label: const Text("Clear Filter"),
//                                 ),
//                               ],
//                             ],
//                           ),
//                         )
//                       : ListView.builder(
//                           controller: scrollController,
//                           itemCount: currentItems.length + (isFetchingMore ? 1 : 0),
//                           itemBuilder: (context, index) {
//                             if (index < currentItems.length) {
//                               final prescription = currentItems[index];
//                               final meds = prescription['medications'] ?? [];
//                               final createdAt = prescription['createdAt'];
//                               final formattedDate = createdAt != null
//                                   ? DateFormat('dd MMM yyyy').format(DateTime.parse(createdAt))
//                                   : 'N/A';

//                               // final doctorName = prescription['prescribedBy'] != null
//                               //     ? prescription['prescribedBy']
//                               //     : 'Doctor ID: ${prescription['doctorId'] ?? 'N/A'}';
//                               final doctorName =
//     prescription['prescribedBy'] ??
//     prescription['doctorName'] ??
//     'Doctor ID: ${prescription['doctorId'] ?? 'N/A'}';
//                               final patientId = prescription['patientId'] ?? 'N/A';
//                               final patientName = patientNames[patientId] ??
//                                                   prescription['patientName'] ??
//                                                   'Patient $patientId';

//                               return Card(
//                                 margin: EdgeInsets.only(bottom: spacing),
//                                 elevation: 2,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(16),
//                                 ),
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(16),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         crossAxisAlignment: CrossAxisAlignment.start,
//                                         children: [
//                                           Container(
//                                             padding: const EdgeInsets.all(12),
//                                             decoration: BoxDecoration(
//                                               color: Colors.green.shade100,
//                                               borderRadius: BorderRadius.circular(12),
//                                             ),
//                                             child: const Icon(
//                                               Icons.local_hospital,
//                                               color: Colors.green,
//                                               size: 24,
//                                             ),
//                                           ),
//                                           const SizedBox(width: 12),
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment: CrossAxisAlignment.start,
//                                               children: [
//                                                 Row(
//                                                   children: [
//                                                     const Icon(Icons.person, size: 16, color: Colors.green),
//                                                     const SizedBox(width: 4),
//                                                     Expanded(
//                                                       child: Text(
//                                                         doctorName,
//                                                         style: TextStyle(
//                                                           color: Colors.green,
//                                                           fontWeight: FontWeight.bold,
//                                                           fontSize: subtitleFontSize,
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                                 const SizedBox(height: 8),
//                                                 Row(
//                                                   children: [
//                                                     const Icon(Icons.person, size: 14, color: Colors.blue),
//                                                     const SizedBox(width: 4),
//                                                     Text(
//                                                       patientName,
//                                                       style: TextStyle(
//                                                         fontSize: bodyFontSize,
//                                                         fontWeight: FontWeight.w500,
//                                                         color: Colors.grey.shade800,
//                                                       ),
//                                                     ),
//                                                     const SizedBox(width: 8),
//                                                     Container(
//                                                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                                                       decoration: BoxDecoration(
//                                                         color: Colors.blue.shade50,
//                                                         borderRadius: BorderRadius.circular(4),
//                                                       ),
//                                                       child: Text(
//                                                         "ID: $patientId",
//                                                         style: TextStyle(
//                                                           fontSize: smallFontSize,
//                                                           color: Colors.blue.shade700,
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                                 const SizedBox(height: 8),
//                                                 Row(
//                                                   children: [
//                                                     Icon(Icons.receipt, size: 12, color: Colors.grey.shade500),
//                                                     const SizedBox(width: 4),
//                                                     Text(
//                                                       "Prescription #${prescription['id']}",
//                                                       style: TextStyle(
//                                                         fontSize: smallFontSize,
//                                                         color: Colors.grey.shade600,
//                                                       ),
//                                                     ),
//                                                     const SizedBox(width: 12),
//                                                     Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
//                                                     const SizedBox(width: 4),
//                                                     Text(
//                                                       formattedDate,
//                                                       style: TextStyle(
//                                                         fontSize: smallFontSize,
//                                                         color: Colors.grey.shade600,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 16),
//                                       Container(
//                                         padding: const EdgeInsets.all(12),
//                                         decoration: BoxDecoration(
//                                           color: Colors.amber.shade50,
//                                           borderRadius: BorderRadius.circular(12),
//                                         ),
//                                         child: Column(
//                                           crossAxisAlignment: CrossAxisAlignment.start,
//                                           children: [
//                                             const Text(
//                                               "Complaint",
//                                               style: TextStyle(
//                                                 fontWeight: FontWeight.bold,
//                                                 fontSize: 13,
//                                               ),
//                                             ),
//                                             const SizedBox(height: 4),
//                                             Text(
//                                               prescription['complaint'] ?? "No complaint mentioned",
//                                               style: TextStyle(fontSize: bodyFontSize),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       const SizedBox(height: 16),
//                                       const Text(
//                                         "Medicines",
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 15,
//                                           color: Colors.green,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 8),
//                                       ...meds.map((med) => Container(
//                                         margin: const EdgeInsets.only(bottom: 8),
//                                         padding: const EdgeInsets.all(12),
//                                         decoration: BoxDecoration(
//                                           color: Colors.grey.shade50,
//                                           borderRadius: BorderRadius.circular(10),
//                                           border: Border.all(color: Colors.grey.shade200),
//                                         ),
//                                         child: Row(
//                                           children: [
//                                             const Icon(Icons.medication, size: 20, color: Colors.green),
//                                             const SizedBox(width: 12),
//                                             Expanded(
//                                               child: Column(
//                                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                                 children: [
//                                                   Text(
//                                                     med['name'] ?? med['medicine_name'] ?? 'Unknown',
//                                                     style: const TextStyle(
//                                                       fontWeight: FontWeight.w600,
//                                                       fontSize: 14,
//                                                     ),
//                                                   ),
//                                                   const SizedBox(height: 4),
//                                                   Wrap(
//                                                     spacing: 12,
//                                                     children: [
//                                                       Text("${med['dosage']} mg",
//                                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
//                                                       Text(med['frequency'] ?? '',
//                                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
//                                                       Text(med['timing'] ?? '',
//                                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
//                                                       Text("${med['duration']} days",
//                                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
//                                                     ],
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       )),
//                                       if (prescription['investigations'] != null &&
//                                           (prescription['investigations'] as List).isNotEmpty) ...[
//                                         const SizedBox(height: 12),
//                                         const Text(
//                                           "Investigations",
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                             color: Colors.green,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 8),
//                                         Wrap(
//                                           spacing: 8,
//                                           children: (prescription['investigations'] as List).map((inv) {
//                                             return Chip(
//                                               label: Text(inv.toString()),
//                                               backgroundColor: Colors.green.shade50,
//                                               labelStyle: TextStyle(fontSize: smallFontSize),
//                                             );
//                                           }).toList(),
//                                         ),
//                                       ],
//                                       if (prescription['advice'] != null &&
//                                           prescription['advice'].toString().isNotEmpty) ...[
//                                         const SizedBox(height: 12),
//                                         const Text(
//                                           "Advice",
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                             color: Colors.green,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           prescription['advice'],
//                                           style: TextStyle(fontSize: bodyFontSize),
//                                         ),
//                                       ],
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             } else if (isFetchingMore) {
//                               return const Padding(
//                                 padding: EdgeInsets.all(16),
//                                 child: Center(child: CircularProgressIndicator()),
//                               );
//                             }
//                             return const SizedBox.shrink();
//                           },
//                         ),
//             ),

//             Container(
//               padding: const EdgeInsets.only(top: 8),
//               child: SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton.icon(
//                   onPressed: prescriptions.isEmpty ? null : _downloadPrescription,
//                   icon: const Icon(Icons.download),
//                   label: const Text(
//                     "Download All Prescriptions (PDF)",
//                     style: TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _appBarAction(IconData icon, String label, bool isSmallScreen) {
//     return Padding(
//       padding: const EdgeInsets.only(right: 4),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, size: isSmallScreen ? 18 : 20),
//           Text(label, style: TextStyle(fontSize: isSmallScreen ? 9 : 11)),
//         ],
//       ),
//     );
//   }
// }
// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:hosta/services/api_service.dart';
// import 'package:intl/intl.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

// class PrescriptionDetailsScreen extends StatefulWidget {
//   final String userId;
//   const PrescriptionDetailsScreen({super.key, required this.userId});

//   @override
//   State<PrescriptionDetailsScreen> createState() =>
//       _PrescriptionDetailsScreenState();
// }

// class _PrescriptionDetailsScreenState extends State<PrescriptionDetailsScreen> {
//   int currentPage = 1;
//   int totalPages = 1;
//   bool isFetchingMore = false;
//   ScrollController scrollController = ScrollController();
//   final TextEditingController _dateController = TextEditingController();
//   DateTime? selectedDate;

//   // Store ALL prescriptions from API
//   List<dynamic> allPrescriptions = [];
//   // Display filtered prescriptions
//   List<dynamic> prescriptions = [];

//   bool isLoading = true;
//   final ApiService _apiService = ApiService();
//   bool isRequestInProgress = false;
//   bool _hasReachedEnd = false;
//   Timer? _debounceTimer;
//   bool _noMoreData = false;

//   Map<int, String> patientNames = {};

//   @override
//   void initState() {
//     super.initState();
//     scrollController.addListener(_onScroll);
//     fetchPrescriptions();
//   }

//   @override
//   void dispose() {
//     scrollController.dispose();
//     _dateController.dispose();
//     _debounceTimer?.cancel();
//     super.dispose();
//   }

//   void _clearDateFilter() {
//     setState(() {
//       selectedDate = null;
//       _dateController.clear();
//       _applyLocalDateFilter();
//     });
//   }

//   void _onScroll() {
//     if (_debounceTimer?.isActive == true) return;
//     if (!scrollController.hasClients) return;
//     if (isFetchingMore || isRequestInProgress) return;
//     if (_hasReachedEnd || _noMoreData) return;
//     if (currentPage >= totalPages) return;
//     if (prescriptions.isEmpty) return;

//     if (scrollController.position.pixels >=
//         scrollController.position.maxScrollExtent - 200) {
//       fetchMorePrescriptions();
//     }
//   }

//   void _applyLocalDateFilter() {
//     print("🔍 Applying local filter...");
//     print("📅 Selected date: $selectedDate");

//     if (selectedDate == null) {
//       prescriptions = List.from(allPrescriptions);
//       print("📊 No filter - showing all ${prescriptions.length} items");
//     } else {
//       final filterDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
//       print("📅 Filter date: $filterDate");

//       prescriptions = allPrescriptions.where((prescription) {
//         final createdAt = prescription['createdAt'];
//         if (createdAt == null) return false;

//         final prescriptionDate =
//             DateFormat('yyyy-MM-dd').format(DateTime.parse(createdAt));
//         final isMatch = prescriptionDate == filterDate;

//         if (isMatch) {
//           print(
//               "  ✅ Match: ID ${prescription['id']} - Date: $prescriptionDate");
//         }

//         return isMatch;
//       }).toList();

//       print(
//           "📊 Local filter found ${prescriptions.length} items for $filterDate");
//     }

//     currentPage = 1;
//     totalPages = (prescriptions.length / 10).ceil();
//     if (totalPages == 0) totalPages = 1;
//     _hasReachedEnd = currentPage >= totalPages;
//     _noMoreData = false;

//     setState(() {});
//   }

//   Future<void> fetchPrescriptions() async {
//     setState(() {
//       isLoading = true;
//       isFetchingMore = false;
//       _hasReachedEnd = false;
//       _noMoreData = false;
//     });

//     try {
//       String? dateParam;
//       if (selectedDate != null) {
//         dateParam = DateFormat('yyyy-MM-dd').format(selectedDate!);
//         print("📅 Sending date to API: $dateParam");
//       }

//       final response = await _apiService.getPrescriptions(
//         userId: widget.userId,
//         page: 1,
//         limit: 100,
//       );

//       print("✅ API Status: ${response.statusCode}");

//       if (response.statusCode == 200) {
//         final data = response.data['data'] as List;
//         print("📊 Total items from API: ${data.length}");

//         allPrescriptions = data;
//         _fetchPatientNames(allPrescriptions);
//         _applyLocalDateFilter();

//         print("📊 After local filter: ${prescriptions.length} items");
//       }
//     } catch (e) {
//       print("❌ Error: $e");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   void _fetchPatientNames(List<dynamic> prescriptionsList) {
//     for (var prescription in prescriptionsList) {
//       final patientId = prescription['patientId'];
//       if (patientId != null && !patientNames.containsKey(patientId)) {
//         if (prescription['patientName'] != null) {
//           patientNames[patientId] = prescription['patientName'];
//         } else {
//           patientNames[patientId] = 'Patient $patientId';
//         }
//       }
//     }
//   }

//   Future<void> fetchMorePrescriptions() async {
//     if (isFetchingMore || isRequestInProgress) return;
//     if (_hasReachedEnd || _noMoreData) return;
//     if (currentPage >= totalPages) {
//       setState(() => _hasReachedEnd = true);
//       return;
//     }

//     setState(() {
//       isFetchingMore = true;
//       isRequestInProgress = true;
//     });

//     await Future.delayed(const Duration(milliseconds: 300));

//     setState(() {
//       currentPage++;
//       _hasReachedEnd = currentPage >= totalPages;
//       isFetchingMore = false;
//       isRequestInProgress = false;
//     });
//   }

//   List<dynamic> getCurrentPageItems() {
//     int start = (currentPage - 1) * 10;
//     int end = start + 10;
//     if (start >= prescriptions.length) return [];
//     if (end > prescriptions.length) end = prescriptions.length;
//     return prescriptions.sublist(start, end);
//   }

//   // ✅ NEW METHOD: Download single prescription
//   Future<void> _downloadSinglePrescription(dynamic prescription) async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.Page(
//         build: (context) {
//           final createdAt = prescription['createdAt'];
//           final formattedDate = createdAt != null
//               ? DateFormat('dd MMM yyyy').format(DateTime.parse(createdAt))
//               : 'N/A';

//           final doctorName = prescription['prescribedBy'] ??
//               prescription['doctorName'] ??
//               'Doctor ID: ${prescription['doctorId'] ?? 'N/A'}';

//           final patientId = prescription['patientId'] ?? 'N/A';
//           final patientName = patientNames[patientId] ??
//               prescription['patientName'] ??
//               'Patient $patientId';

//           // Safely handle medications
//           List<dynamic> medications = [];
//           try {
//             final meds = prescription['medications'];
//             if (meds is List) {
//               medications = meds;
//             }
//           } catch (e) {
//             print("❌ Error processing medications: $e");
//           }

//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text(
//                 "Medical Prescription",
//                 style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
//               ),
//               pw.SizedBox(height: 20),
//               pw.Text("Doctor: $doctorName",
//                   style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
//               pw.Text("Patient: $patientName", style: pw.TextStyle(fontSize: 14)),
//               pw.Text("Patient ID: $patientId", style: pw.TextStyle(fontSize: 14)),
//               pw.Text("Prescription ID: ${prescription['id']}",
//                   style: pw.TextStyle(fontSize: 14)),
//               pw.Text("Date: $formattedDate", style: pw.TextStyle(fontSize: 14)),
//               pw.SizedBox(height: 20),
//               pw.Text("Complaint: ${prescription['complaint'] ?? ''}",
//                   style: pw.TextStyle(fontSize: 14)),
//               pw.SizedBox(height: 20),
//               pw.Text("Medicines:",
//                   style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//               pw.SizedBox(height: 10),
//               if (medications.isNotEmpty)
//                 ...medications.map((med) {
//                   return pw.Text(
//                     "• ${med['name'] ?? med['medicine_name'] ?? 'Unknown'} "
//                     "(${med['dosage'] ?? 0}mg) "
//                     "${med['frequency'] ?? ''} - ${med['timing'] ?? ''}",
//                     style: pw.TextStyle(fontSize: 12),
//                   );
//                 })
//               else
//                 pw.Text(
//                   "No medicines prescribed",
//                   style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
//                 ),
//               if (prescription['advice'] != null &&
//                   prescription['advice'].toString().isNotEmpty) ...[
//                 pw.SizedBox(height: 20),
//                 pw.Text("Advice:",
//                     style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//                 pw.Text(prescription['advice'], style: pw.TextStyle(fontSize: 12)),
//               ],
//               if (prescription['investigations'] != null &&
//                   (prescription['investigations'] as List).isNotEmpty) ...[
//                 pw.SizedBox(height: 20),
//                 pw.Text("Investigations:",
//                     style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
//                 for (var inv in prescription['investigations'])
//                   pw.Text("• $inv", style: pw.TextStyle(fontSize: 12)),
//               ],
//             ],
//           );
//         },
//       ),
//     );

//     try {
//       final dir = await getApplicationDocumentsDirectory();
//       final fileName =
//           "prescription_${prescription['id']}_${DateTime.now().millisecondsSinceEpoch}.pdf";
//       final file = File("${dir.path}/$fileName");
//       await file.writeAsBytes(await pdf.save());

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("✅ Prescription #${prescription['id']} downloaded successfully!"),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 3),
//           ),
//         );
//       }
//     } catch (e) {
//       print("❌ Error downloading prescription: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("❌ Error downloading: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // Existing method for all prescriptions
//   Future<void> _downloadPrescription() async {
//     if (prescriptions.isEmpty) return;

//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.Page(
//         build: (context) {
//           return pw.Column(
//             crossAxisAlignment: pw.CrossAxisAlignment.start,
//             children: [
//               pw.Text(
//                 "Medical Prescription",
//                 style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
//               ),
//               pw.SizedBox(height: 20),
//               ...prescriptions.map((prescription) {
//                 final createdAt = prescription['createdAt'];
//                 final formattedDate = createdAt != null
//                     ? DateFormat('dd MMM yyyy')
//                         .format(DateTime.parse(createdAt))
//                     : 'N/A';

//                 final doctorName = prescription['prescribedBy'] ??
//                     prescription['doctorName'] ??
//                     'Doctor ID: ${prescription['doctorId'] ?? 'N/A'}';

//                 final patientId = prescription['patientId'] ?? 'N/A';
//                 final patientName = patientNames[patientId] ??
//                     prescription['patientName'] ??
//                     'Patient $patientId';

//                 List<dynamic> medications = [];
//                 try {
//                   final meds = prescription['medications'];
//                   if (meds is List) {
//                     medications = meds;
//                   }
//                 } catch (e) {
//                   print("❌ Error processing medications: $e");
//                 }

//                 return pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text("Doctor: $doctorName",
//                         style: pw.TextStyle(
//                             fontSize: 12, fontWeight: pw.FontWeight.bold)),
//                     pw.Text("Patient: $patientName",
//                         style: pw.TextStyle(fontSize: 12)),
//                     pw.Text("Patient ID: $patientId",
//                         style: pw.TextStyle(fontSize: 12)),
//                     pw.Text("Prescription ID: ${prescription['id']}",
//                         style: pw.TextStyle(fontSize: 12)),
//                     pw.Text("Date: $formattedDate",
//                         style: pw.TextStyle(fontSize: 12)),
//                     pw.SizedBox(height: 10),
//                     pw.Text("Complaint: ${prescription['complaint'] ?? ''}",
//                         style: pw.TextStyle(fontSize: 12)),
//                     pw.SizedBox(height: 10),
//                     pw.Text("Medicines:",
//                         style: pw.TextStyle(
//                             fontSize: 14, fontWeight: pw.FontWeight.bold)),
//                     pw.SizedBox(height: 10),
//                     ...medications.map((med) {
//                       return pw.Text(
//                         "- ${med['name'] ?? med['medicine_name'] ?? 'Unknown'} "
//                         "(${med['dosage'] ?? 0}mg) "
//                         "${med['frequency'] ?? ''} - ${med['timing'] ?? ''}",
//                         style: pw.TextStyle(fontSize: 11),
//                       );
//                     }),
//                     pw.SizedBox(height: 25),
//                     pw.Divider(),
//                     pw.SizedBox(height: 15),
//                   ],
//                 );
//               }),
//             ],
//           );
//         },
//       ),
//     );

//     final dir = await getApplicationDocumentsDirectory();
//     final file = File("${dir.path}/prescription.pdf");
//     await file.writeAsBytes(await pdf.save());

//     if (mounted) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => Scaffold(
//             appBar: AppBar(
//               title: const Text("Prescription Preview"),
//               backgroundColor: Colors.green,
//               foregroundColor: Colors.white,
//             ),
//             body: PdfPreview(build: (format) => pdf.save()),
//           ),
//         ),
//       );

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Prescription PDF ready")),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     final screenWidth = screenSize.width;
//     final isSmallScreen = screenWidth < 600;
//     final isTablet = screenWidth >= 600 && screenWidth < 1200;
//     final isDesktop = screenWidth >= 1200;

//     final titleFontSize = isDesktop ? 22.0 : (isTablet ? 20.0 : 18.0);
//     final subtitleFontSize = isDesktop ? 16.0 : (isTablet ? 15.0 : 14.0);
//     final bodyFontSize = isDesktop ? 14.0 : (isTablet ? 13.0 : 12.0);
//     final smallFontSize = isDesktop ? 12.0 : (isTablet ? 11.0 : 10.0);
//     final spacing = isDesktop ? 24.0 : (isTablet ? 20.0 : 16.0);

//     final currentItems = getCurrentPageItems();

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FC),
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           'Prescription Details',
//           style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w600),
//         ),
//         actions: const [],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(10.0),
//         child: Column(
//           children: [
//             // Filter Section
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 5,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: TextField(
//                 controller: _dateController,
//                 readOnly: true,
//                 onTap: () async {
//                   final picked = await showDatePicker(
//                     context: context,
//                     initialDate: selectedDate ?? DateTime.now(),
//                     firstDate: DateTime(2020),
//                     lastDate: DateTime(2030),
//                   );
//                   if (picked != null) {
//                     setState(() {
//                       selectedDate = picked;
//                       _dateController.text =
//                           DateFormat('dd MMM yyyy').format(picked);
//                     });
//                     _applyLocalDateFilter();
//                   }
//                 },
//                 decoration: InputDecoration(
//                   hintText: "Filter by date",
//                   prefixIcon:
//                       const Icon(Icons.calendar_today, color: Colors.green),
//                   suffixIcon: selectedDate != null
//                       ? IconButton(
//                           icon: const Icon(Icons.close, color: Colors.red),
//                           onPressed: _clearDateFilter,
//                         )
//                       : null,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide.none,
//                   ),
//                   filled: true,
//                   fillColor: Colors.grey.shade50,
//                   contentPadding: const EdgeInsets.symmetric(vertical: 16),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),

//             if (selectedDate != null)
//               Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade50,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Icon(Icons.filter_alt, size: 16, color: Colors.green),
//                     const SizedBox(width: 8),
//                     Text(
//                       "Filtered: ${DateFormat('dd MMM yyyy').format(selectedDate!)}",
//                       style:
//                           TextStyle(fontSize: 12, color: Colors.green.shade700),
//                     ),
//                   ],
//                 ),
//               ),

//             const SizedBox(height: 12),

//             // Prescriptions List
//             Expanded(
//               child: isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   : currentItems.isEmpty
//                       ? Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(Icons.medical_information,
//                                   size: 64, color: Colors.grey.shade400),
//                               const SizedBox(height: 16),
//                               Text(
//                                 selectedDate != null
//                                     ? "No prescriptions found for ${DateFormat('dd MMM yyyy').format(selectedDate!)}"
//                                     : "No prescriptions found",
//                                 style: TextStyle(
//                                     color: Colors.grey.shade600, fontSize: 16),
//                               ),
//                               if (selectedDate != null) ...[
//                                 const SizedBox(height: 8),
//                                 TextButton.icon(
//                                   onPressed: _clearDateFilter,
//                                   icon: const Icon(Icons.clear),
//                                   label: const Text("Clear Filter"),
//                                 ),
//                               ],
//                             ],
//                           ),
//                         )
//                       : ListView.builder(
//                           controller: scrollController,
//                           itemCount: currentItems.length + (isFetchingMore ? 1 : 0),
//                           itemBuilder: (context, index) {
//                             // if (index >=0&& index < currentItems.length) {
//                             //   final prescription = currentItems[index];
//                                  if (index < currentItems.length) {
//                   final prescription = currentItems[index];
                  
//                               List<dynamic> meds = [];
//                               try {
//                                 final medications = prescription['medications'];
//                                 if (medications is List) {
//                                   meds = medications;
//                                 }
//                               } catch (e) {
//                                 print("❌ Error processing medications: $e");
//                               }

//                               final createdAt = prescription['createdAt'];
//                               final formattedDate = createdAt != null
//                                   ? DateFormat('dd MMM yyyy')
//                                       .format(DateTime.parse(createdAt))
//                                   : 'N/A';

//                               final doctorName = prescription['prescribedBy'] ??
//                                   prescription['doctorName'] ??
//                                   'Doctor ID: ${prescription['doctorId'] ?? 'N/A'}';
//                               final patientId =
//                                   prescription['patientId'] ?? 'N/A';
//                               final patientName = patientNames[patientId] ??
//                                   prescription['patientName'] ??
//                                   'Patient $patientId';

//                               return Card(
//                                 margin: EdgeInsets.only(bottom: spacing),
//                                 elevation: 2,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(16),
//                                 ),
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(16),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       // ✅ FIXED: Row with download button
//                                       Row(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Container(
//                                             padding: const EdgeInsets.all(12),
//                                             decoration: BoxDecoration(
//                                               color: Colors.green.shade100,
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                             ),
//                                             child: const Icon(
//                                               Icons.local_hospital,
//                                               color: Colors.green,
//                                               size: 24,
//                                             ),
//                                           ),
//                                           const SizedBox(width: 12),
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.start,
//                                               children: [
//                                                 Row(
//                                                   children: [
//                                                     const Icon(Icons.person,
//                                                         size: 16,
//                                                         color: Colors.green),
//                                                     const SizedBox(width: 4),
//                                                     Expanded(
//                                                       child: Text(
//                                                         doctorName,
//                                                         style: TextStyle(
//                                                           color: Colors.green,
//                                                           fontWeight:
//                                                               FontWeight.bold,
//                                                           fontSize:
//                                                               subtitleFontSize,
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                                 const SizedBox(height: 8),
//                                                 Row(
//                                                   children: [
//                                                     const Icon(Icons.person,
//                                                         size: 14,
//                                                         color: Colors.blue),
//                                                     const SizedBox(width: 4),
//                                                     Text(
//                                                       patientName,
//                                                       style: TextStyle(
//                                                         fontSize: bodyFontSize,
//                                                         fontWeight:
//                                                             FontWeight.w500,
//                                                         color: Colors
//                                                             .grey.shade800,
//                                                       ),
//                                                     ),
//                                                     const SizedBox(width: 8),
//                                                     Container(
//                                                       padding: const EdgeInsets
//                                                           .symmetric(
//                                                           horizontal: 6,
//                                                           vertical: 2),
//                                                       decoration: BoxDecoration(
//                                                         color:
//                                                             Colors.blue.shade50,
//                                                         borderRadius:
//                                                             BorderRadius
//                                                                 .circular(4),
//                                                       ),
//                                                       child: Text(
//                                                         "ID: $patientId",
//                                                         style: TextStyle(
//                                                           fontSize:
//                                                               smallFontSize,
//                                                           color: Colors
//                                                               .blue.shade700,
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                                 const SizedBox(height: 8),
//                                                 Row(
//                                                   children: [
//                                                     Icon(Icons.receipt,
//                                                         size: 12,
//                                                         color: Colors
//                                                             .grey.shade500),
//                                                     const SizedBox(width: 4),
//                                                     Text(
//                                                       "Prescription #${prescription['id']}",
//                                                       style: TextStyle(
//                                                         fontSize: smallFontSize,
//                                                         color: Colors
//                                                             .grey.shade600,
//                                                       ),
//                                                     ),
//                                                     const SizedBox(width: 12),
//                                                     Icon(Icons.calendar_today,
//                                                         size: 12,
//                                                         color: Colors
//                                                             .grey.shade500),
//                                                     const SizedBox(width: 4),
//                                                     Text(
//                                                       formattedDate,
//                                                       style: TextStyle(
//                                                         fontSize: smallFontSize,
//                                                         color: Colors
//                                                             .grey.shade600,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                           // ✅ DOWNLOAD BUTTON
//                                           Column(
//                                             children: [
//                                               IconButton(
//                                                 icon: const Icon(
//                                                     Icons.download,
//                                                     color: Colors.green),
//                                                 onPressed: () =>
//                                                     _downloadSinglePrescription(
//                                                         prescription),
//                                                 tooltip:
//                                                     'Download this prescription',
//                                                 constraints:
//                                                     const BoxConstraints(),
//                                                 padding: EdgeInsets.zero,
//                                                 iconSize: 28,
//                                               ),
//                                               Text(
//                                               'Download',
//                                                 style: TextStyle(
//                                                   fontSize: 10,
//                                                   color: Colors.green.shade700,
//                                                   fontWeight: FontWeight.w600,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 16),
//                                       Container(
//                                         padding: const EdgeInsets.all(12),
//                                         decoration: BoxDecoration(
//                                           color: Colors.amber.shade50,
//                                           borderRadius:
//                                               BorderRadius.circular(12),
//                                         ),
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             const Text(
//                                               "Complaint",
//                                               style: TextStyle(
//                                                 fontWeight: FontWeight.bold,
//                                                 fontSize: 13,
//                                               ),
//                                             ),
//                                             const SizedBox(height: 4),
//                                             Text(
//                                               prescription['complaint'] ??
//                                                   "No complaint mentioned",
//                                               style: TextStyle(
//                                                   fontSize: bodyFontSize),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                       const SizedBox(height: 16),
//                                       const Text(
//                                         "Medicines",
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 15,
//                                           color: Colors.green,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 8),
//                                       if (meds.isNotEmpty)
//                                         ...meds.map((med) => Container(
//                                               margin: const EdgeInsets.only(
//                                                   bottom: 8),
//                                               padding: const EdgeInsets.all(12),
//                                               decoration: BoxDecoration(
//                                                 color: Colors.grey.shade50,
//                                                 borderRadius:
//                                                     BorderRadius.circular(10),
//                                                 border: Border.all(
//                                                     color:
//                                                         Colors.grey.shade200),
//                                               ),
//                                               child: Row(
//                                                 children: [
//                                                   const Icon(Icons.medication,
//                                                       size: 20,
//                                                       color: Colors.green),
//                                                   const SizedBox(width: 12),
//                                                   Expanded(
//                                                     child: Column(
//                                                       crossAxisAlignment:
//                                                           CrossAxisAlignment
//                                                               .start,
//                                                       children: [
//                                                         Text(
//                                                           med['name'] ??
//                                                               med['medicine_name'] ??
//                                                               'Unknown',
//                                                           style:
//                                                               const TextStyle(
//                                                             fontWeight:
//                                                                 FontWeight.w600,
//                                                             fontSize: 14,
//                                                           ),
//                                                         ),
//                                                         const SizedBox(
//                                                             height: 4),
//                                                         Wrap(
//                                                           spacing: 12,
//                                                           children: [
//                                                             if (med['dosage'] !=
//                                                                 null)
//                                                               Text(
//                                                                   "${med['dosage']} mg",
//                                                                   style: TextStyle(
//                                                                       fontSize:
//                                                                           12,
//                                                                       color: Colors
//                                                                           .grey
//                                                                           .shade700)),
//                                                             if (med['frequency'] !=
//                                                                     null &&
//                                                                 med['frequency']
//                                                                     .toString()
//                                                                     .isNotEmpty)
//                                                               Text(
//                                                                   med['frequency'],
//                                                                   style: TextStyle(
//                                                                       fontSize:
//                                                                           12,
//                                                                       color: Colors
//                                                                           .grey
//                                                                           .shade700)),
//                                                             if (med['timing'] !=
//                                                                     null &&
//                                                                 med['timing']
//                                                                     .toString()
//                                                                     .isNotEmpty)
//                                                               Text(
//                                                                   med['timing'],
//                                                                   style: TextStyle(
//                                                                       fontSize:
//                                                                           12,
//                                                                       color: Colors
//                                                                           .grey
//                                                                           .shade700)),
//                                                             if (med['duration'] !=
//                                                                     null &&
//                                                                 med['duration']
//                                                                     .toString()
//                                                                     .isNotEmpty)
//                                                               Text(
//                                                                   "${med['duration']} days",
//                                                                   style: TextStyle(
//                                                                       fontSize:
//                                                                           12,
//                                                                       color: Colors
//                                                                           .grey
//                                                                           .shade700)),
//                                                           ],
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ))
//                                       else
//                                         Container(
//                                           padding: const EdgeInsets.all(12),
//                                           decoration: BoxDecoration(
//                                             color: Colors.grey.shade50,
//                                             borderRadius:
//                                                 BorderRadius.circular(10),
//                                             border: Border.all(
//                                                 color: Colors.grey.shade200),
//                                           ),
//                                           child: Row(
//                                             children: [
//                                               const Icon(Icons.info_outline,
//                                                   size: 20, color: Colors.grey),
//                                               const SizedBox(width: 12),
//                                               Expanded(
//                                                 child: Text(
//                                                   "No medicines prescribed",
//                                                   style: TextStyle(
//                                                     fontSize: bodyFontSize,
//                                                     color: Colors.grey.shade600,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                       if (prescription['investigations'] !=
//                                               null &&
//                                           (prescription['investigations']
//                                                   as List)
//                                               .isNotEmpty) ...[
//                                         const SizedBox(height: 12),
//                                         const Text(
//                                           "Investigations",
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                             color: Colors.green,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 8),
//                                         Wrap(
//                                           spacing: 8,
//                                           children:
//                                               (prescription['investigations']
//                                                       as List)
//                                                   .map((inv) {
//                                             return Chip(
//                                               label: Text(inv.toString()),
//                                               backgroundColor:
//                                                   Colors.green.shade50,
//                                               labelStyle: TextStyle(
//                                                   fontSize: smallFontSize),
//                                             );
//                                           }).toList(),
//                                         ),
//                                       ],
//                                       if (prescription['advice'] != null &&
//                                           prescription['advice']
//                                               .toString()
//                                               .isNotEmpty) ...[
//                                         const SizedBox(height: 12),
//                                         const Text(
//                                           "Advice",
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.bold,
//                                             fontSize: 14,
//                                             color: Colors.green,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           prescription['advice'],
//                                           style:
//                                               TextStyle(fontSize: bodyFontSize),
//                                         ),
//                                       ],
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             } else if (isFetchingMore) {
//                               return const Padding(
//                                 padding: EdgeInsets.all(16),
//                                 child:
//                                     Center(child: CircularProgressIndicator()),
//                               );
//                             }
//                             return const SizedBox.shrink();
//                           },
//                         ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }












import 'dart:async';
import 'dart:developer';
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

  List<dynamic> allPrescriptions = [];
  List<dynamic> prescriptions = [];

  bool isLoading = true;
  final ApiService _apiService = ApiService();
  bool isRequestInProgress = false;
  bool _hasReachedEnd = false;
  Timer? _debounceTimer;
  bool _noMoreData = false;

  // Maps for names
  Map<int, String> patientNames = {};
  Map<int, String> doctorNames = {};
  bool _isFetchingDoctorNames = false;

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
      _applyLocalDateFilter();
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

  void _applyLocalDateFilter() {
    if (selectedDate == null) {
      prescriptions = List.from(allPrescriptions);
    } else {
      final filterDate = DateFormat('yyyy-MM-dd').format(selectedDate!);
      prescriptions = allPrescriptions.where((prescription) {
        final createdAt = prescription['createdAt'];
        if (createdAt == null) return false;
        final prescriptionDate =
            DateFormat('yyyy-MM-dd').format(DateTime.parse(createdAt));
        return prescriptionDate == filterDate;
      }).toList();
    }

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
      final response = await _apiService.getPrescriptions(
        userId: widget.userId,
        page: 1,
        limit: 100,
      );
      log("resofprescription=${response.data}");
      
      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        allPrescriptions = data;
        _fetchPatientNames(allPrescriptions);
        
        // ✅ First, try to get doctor names from prescribedBy
        _fetchDoctorNamesFromPrescriptions(allPrescriptions);
        
        // ✅ Then, fetch missing doctor names from API
        await _fetchMissingDoctorNames(allPrescriptions);
        
        _applyLocalDateFilter();
      }
    } catch (e) {
      print("❌ Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading prescriptions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        patientNames[patientId] =
            prescription['patientName'] ?? 'Patient $patientId';
      }
    }
  }

  // ✅ Get doctor names from prescriptions first
  void _fetchDoctorNamesFromPrescriptions(List<dynamic> prescriptionsList) {
    for (var prescription in prescriptionsList) {
      final doctorId = prescription['doctorId'];
      if (doctorId != null && !doctorNames.containsKey(doctorId)) {
        // Check if prescribedBy has value
        final doctorName = prescription['prescribedBy'];
        
        if (doctorName != null && doctorName.toString().isNotEmpty) {
          doctorNames[doctorId] = doctorName.toString();
        }
      }
    }
  }

  // ✅ Fetch missing doctor names from API
  Future<void> _fetchMissingDoctorNames(List<dynamic> prescriptionsList) async {
    // Get unique doctor IDs that don't have names yet
    Set<int> missingDoctorIds = {};
    for (var prescription in prescriptionsList) {
      final doctorId = prescription['doctorId'];
      if (doctorId != null && !doctorNames.containsKey(doctorId)) {
        missingDoctorIds.add(doctorId);
      }
    }

    if (missingDoctorIds.isEmpty) {
      print("✅ All doctor names already available");
      return;
    }

    print("📋 Fetching ${missingDoctorIds.length} doctor names...");
    setState(() {
      _isFetchingDoctorNames = true;
    });

    // Fetch each doctor's details
    for (int id in missingDoctorIds) {
      try {
        // Assuming you have a method to get doctor details
        // If not, you need to add this to your ApiService
        final response = await _apiService.getDoctorDetails(id);
        
        if (response.statusCode == 200) {
          final doctorData = response.data['data'];
          String doctorName = doctorData['name'] ?? 
                             doctorData['doctorName'] ?? 
                             doctorData['fullName'] ??
                             'Doctor #$id';
          doctorNames[id] = doctorName;
          print("✅ Fetched doctor $id: $doctorName");
        } else {
          doctorNames[id] = 'Doctor #$id';
          print("⚠️ Failed to fetch doctor $id");
        }
      } catch (e) {
        print("❌ Error fetching doctor $id: $e");
        doctorNames[id] = 'Doctor #$id';
      }
    }

    setState(() {
      _isFetchingDoctorNames = false;
    });
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

  // ✅ UPDATED: Get doctor name from our map
  String _getDoctorName(dynamic prescription) {
    final doctorId = prescription['doctorId'];
    
    // 1. Check if we have the doctor name in our map
    if (doctorId != null && doctorNames.containsKey(doctorId)) {
      return doctorNames[doctorId]!;
    }
    
    // 2. Check if prescribedBy has a value (fallback)
    if (prescription['prescribedBy'] != null && 
        prescription['prescribedBy'].toString().isNotEmpty) {
      return prescription['prescribedBy'].toString();
    }
    
    // 3. Fallback - show doctor ID
    if (doctorId != null) {
      return 'Doctor #$doctorId';
    }
    
    return 'Unknown Doctor';
  }

  String _getPatientName(dynamic prescription) {
    final patientId = prescription['patientId'];
    if (patientId != null && patientNames.containsKey(patientId)) {
      return patientNames[patientId]!;
    }
    return prescription['patientName'] ?? 'Patient $patientId';
  }

  List<dynamic> _safeGetMedications(dynamic prescription) {
    try {
      final meds = prescription['medications'];
      if (meds is List) return meds;
      return [];
    } catch (e) {
      return [];
    }
  }

  List<dynamic> _safeGetInvestigations(dynamic prescription) {
    try {
      final invData = prescription['investigations'];
      if (invData is List) return invData;
      if (invData is String && invData.isNotEmpty) return [invData];
      return [];
    } catch (e) {
      return [];
    }
  }

  // PDF Generation Methods
  Future<pw.Document> _generatePrescriptionPdf(dynamic prescription) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (context) {
          final createdAt = prescription['createdAt'];
          final formattedDate = createdAt != null
              ? DateFormat('dd MMM yyyy').format(DateTime.parse(createdAt))
              : 'N/A';

          final doctorName = _getDoctorName(prescription);
          final patientName = _getPatientName(prescription);
          final patientId = prescription['patientId'] ?? 'N/A';
          final medications = _safeGetMedications(prescription);
          final investigations = _safeGetInvestigations(prescription);

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Medical Prescription",
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text("Doctor: $doctorName",
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text("Patient: $patientName", style: pw.TextStyle(fontSize: 14)),
              pw.Text("Patient ID: $patientId", style: pw.TextStyle(fontSize: 14)),
              pw.Text("Prescription ID: ${prescription['id']}",
                  style: pw.TextStyle(fontSize: 14)),
              pw.Text("Date: $formattedDate", style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text("Complaint: ${prescription['complaint'] ?? ''}",
                  style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text("Medicines:",
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              if (medications.isNotEmpty)
                ...medications.map((med) {
                  return pw.Text(
                    "• ${med['name'] ?? med['medicine_name'] ?? 'Unknown'} "
                    "(${med['dosage'] ?? 0}mg) "
                    "${med['frequency'] ?? ''} - ${med['timing'] ?? ''}",
                    style: pw.TextStyle(fontSize: 12),
                  );
                })
              else
                pw.Text(
                  "No medicines prescribed",
                  style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
                ),
              if (prescription['advice'] != null &&
                  prescription['advice'].toString().isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text("Advice:",
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text(prescription['advice'], style: pw.TextStyle(fontSize: 12)),
              ],
              if (investigations.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text("Investigations:",
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                for (var inv in investigations)
                  pw.Text("• $inv", style: pw.TextStyle(fontSize: 12)),
              ],
            ],
          );
        },
      ),
    );
    
    return pdf;
  }

  Future<pw.Document> _generateAllPrescriptionsPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Medical Prescriptions",
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              ...prescriptions.map((prescription) {
                final createdAt = prescription['createdAt'];
                final formattedDate = createdAt != null
                    ? DateFormat('dd MMM yyyy')
                        .format(DateTime.parse(createdAt))
                    : 'N/A';

                final doctorName = _getDoctorName(prescription);
                final patientName = _getPatientName(prescription);
                final patientId = prescription['patientId'] ?? 'N/A';
                final medications = _safeGetMedications(prescription);

                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Doctor: $doctorName",
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
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
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    ...medications.map((med) {
                      return pw.Text(
                        "- ${med['name'] ?? med['medicine_name'] ?? 'Unknown'} "
                        "(${med['dosage'] ?? 0}mg) "
                        "${med['frequency'] ?? ''} - ${med['timing'] ?? ''}",
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
    
    return pdf;
  }

  // View prescription
  Future<void> _viewPrescription(dynamic prescription) async {
    try {
      final pdf = await _generatePrescriptionPdf(prescription);
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: Text(
                  "Prescription #${prescription['id']}",
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () async {
                      final dir = await getApplicationDocumentsDirectory();
                      final fileName = 
                          "prescription_${prescription['id']}_${DateTime.now().millisecondsSinceEpoch}.pdf";
                      final file = File("${dir.path}/$fileName");
                      await file.writeAsBytes(await pdf.save());
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("✅ Prescription #${prescription['id']} downloaded!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              body: PdfPreview(
                build: (format) => pdf.save(),
                allowPrinting: true,
                allowSharing: true,
                onPrinted: (context) {},
              ),
            ),
          ),
        );
      }
    } catch (e) {
      print("❌ Error viewing prescription: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error viewing prescription: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Download single prescription
  Future<void> _downloadSinglePrescription(dynamic prescription) async {
    try {
      final pdf = await _generatePrescriptionPdf(prescription);
      
      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          "prescription_${prescription['id']}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File("${dir.path}/$fileName");
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Prescription #${prescription['id']} downloaded successfully!"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print("❌ Error downloading prescription: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error downloading: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Download all prescriptions
  Future<void> _downloadPrescription() async {
    if (prescriptions.isEmpty) return;

    try {
      final pdf = await _generateAllPrescriptionsPdf();
      
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
                actions: [
                  IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () async {
                      final dir = await getApplicationDocumentsDirectory();
                      final file = File("${dir.path}/prescription_${DateTime.now().millisecondsSinceEpoch}.pdf");
                      await file.writeAsBytes(await pdf.save());
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("✅ All prescriptions downloaded!"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              body: PdfPreview(
                build: (format) => pdf.save(),
                allowPrinting: true,
                allowSharing: true,
              ),
            ),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Prescription PDF ready")),
        );
      }
    } catch (e) {
      print("❌ Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final isDesktop = screenWidth >= 1200;

    final titleFontSize = isDesktop ? 22.0 : 18.0;
    final subtitleFontSize = isDesktop ? 16.0 : 14.0;
    final bodyFontSize = isDesktop ? 14.0 : 12.0;
    final smallFontSize = isDesktop ? 12.0 : 10.0;
    final spacing = isDesktop ? 24.0 : 16.0;

    final currentItems = getCurrentPageItems();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Prescriptions',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          if (prescriptions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadPrescription,
              tooltip: 'Download all prescriptions',
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
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
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Colors.green,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = picked;
                            _dateController.text =
                                DateFormat('dd MMM yyyy').format(picked);
                          });
                          _applyLocalDateFilter();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "Filter by date",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon:
                            Icon(Icons.calendar_today, color: Colors.green.shade600, size: 20),
                        suffixIcon: selectedDate != null
                            ? IconButton(
                                icon: Icon(Icons.close, color: Colors.red.shade400, size: 20),
                                onPressed: _clearDateFilter,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ),
                if (selectedDate != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade50, Colors.green.shade100],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_alt, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM yyyy').format(selectedDate!),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Stats Bar
          if (prescriptions.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.green.shade100),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medical_services, size: 18, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '${prescriptions.length} prescriptions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (selectedDate != null)
                    Text(
                      'Filtered',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                      ),
                    ),
                ],
              ),
            ),

          // Prescriptions List
          Expanded(
            child: isLoading || _isFetchingDoctorNames
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading doctor details...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : currentItems.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: currentItems.length + (isFetchingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < currentItems.length) {
                            return _buildPrescriptionCard(
                              currentItems[index],
                              spacing,
                              subtitleFontSize,
                              bodyFontSize,
                              smallFontSize,
                            );
                          } else if (isFetchingMore) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_information,
              size: 50,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            selectedDate != null
                ? "No prescriptions found for ${DateFormat('dd MMM yyyy').format(selectedDate!)}"
                : "No prescriptions found",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (selectedDate != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _clearDateFilter,
              icon: Icon(Icons.clear, color: Colors.green.shade700),
              label: Text(
                "Clear Filter",
                style: TextStyle(color: Colors.green.shade700),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.green.shade50,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(
    dynamic prescription,
    double spacing,
    double subtitleFontSize,
    double bodyFontSize,
    double smallFontSize,
  ) {
    final medications = _safeGetMedications(prescription);
    final investigations = _safeGetInvestigations(prescription);
    
    final createdAt = prescription['createdAt'];
    final formattedDate = createdAt != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(createdAt))
        : 'N/A';

    final doctorName = _getDoctorName(prescription);
    final patientName = _getPatientName(prescription);
    final patientId = prescription['patientId'] ?? 'N/A';

    return Card(
      margin: EdgeInsets.only(bottom: spacing),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Colors.white,
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
                          Icon(Icons.person, size: 16, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doctorName,
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: subtitleFontSize,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: Colors.blue.shade600),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "ID: $patientId",
                              style: TextStyle(
                                fontSize: smallFontSize,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.receipt_long, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            "#${prescription['id']}",
                            style: TextStyle(
                              fontSize: smallFontSize,
                              fontWeight: FontWeight.w600,
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
                // View and Download buttons
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.visibility, color: Colors.blue.shade700, size: 20),
                        onPressed: () => _viewPrescription(prescription),
                        tooltip: 'View prescription',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.download, color: Colors.green.shade700, size: 20),
                        onPressed: () => _downloadSinglePrescription(prescription),
                        tooltip: 'Download prescription',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Complaint Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.healing, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 6),
                      Text(
                        "Complaint",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prescription['complaint'] ?? "No complaint mentioned",
                    style: TextStyle(
                      fontSize: bodyFontSize,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Medicines Section
            const Text(
              "Medicines",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            if (medications.isNotEmpty)
              ...medications.map((med) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.medication, size: 20, color: Colors.green.shade400),
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
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (med['dosage'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "${med['dosage']} mg",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                  if (med['frequency'] != null &&
                                      med['frequency'].toString().isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        med['frequency'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  if (med['timing'] != null &&
                                      med['timing'].toString().isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        med['timing'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.purple.shade700,
                                        ),
                                      ),
                                    ),
                                  if (med['duration'] != null &&
                                      med['duration'].toString().isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        "${med['duration']} days",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.grey.shade400),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "No medicines prescribed",
                        style: TextStyle(
                          fontSize: bodyFontSize,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Investigations
            if (investigations.isNotEmpty) ...[
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
                runSpacing: 8,
                children: investigations.map((inv) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade50, Colors.green.shade100],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      inv.toString(),
                      style: TextStyle(
                        fontSize: smallFontSize,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Advice
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Text(
                  prescription['advice'],
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    color: Colors.indigo.shade800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}