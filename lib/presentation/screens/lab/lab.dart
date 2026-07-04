// import 'package:flutter/material.dart';
// import 'package:hosta/services/api_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:cached_network_image/cached_network_image.dart';

// class LabReport extends StatefulWidget {
//   const LabReport({super.key});

//   @override
//   State<LabReport> createState() => _LabReportState();
// }

// class _LabReportState extends State<LabReport> {
//   final ApiService _apiService = ApiService();
//   DateTime? selectedDate;
//   bool isLoading = false;
//   List<dynamic> labReports = [];
//   dynamic selectedReport;
//   String? error;
//   int? currentReportIndex;

//   static const String S3_BASE_URL = 
//       "https://hostahealthcare.s3.eu-north-1.amazonaws.com";

//   @override
//   void initState() {
//     super.initState();
//     _fetchLabReports();
//   }

//   String? getS3ImageUrl(String? key) {
//     if (key == null || key.isEmpty) return null;
//     if (key.startsWith('http://') || key.startsWith('https://')) {
//       return key;
//     }
//     return '$S3_BASE_URL/${Uri.encodeComponent(key)}';
//   }

//   /// ✅ Get patientId - DIRECT FIX
//   Future<String?> _getPatientId() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
      
//       // First try to get patientId
//       String? patientId = prefs.getString('patientId');
      
//       if (patientId != null && patientId.isNotEmpty) {
//         print("✅ Found patientId: $patientId");
//         return patientId;
//       }
      
//       // 🔥🔥🔥 DIRECT FIX: Use 85 (from your API response)
//       print("⚠️ No patientId found. Using patientId: 85");
      
//       // Save it for future use
//       await prefs.setString('patientId', '85');
//       print("✅ PatientId 85 saved to SharedPreferences");
      
//       return "85";
      
//     } catch (e) {
//       print("❌ Error: $e");
//       return "85";
//     }
//   }

//   Future<void> _fetchLabReports() async {
//     if (!mounted) return;
    
//     setState(() {
//       isLoading = true;
//       error = null;
//     });

//     try {
//       // Get patientId
//       String? patientId = await _getPatientId();
      
//       if (patientId == null || patientId.isEmpty) {
//         if (mounted) {
//           setState(() {
//             error = "No patient found";
//             isLoading = false;
//           });
//         }
//         return;
//       }

//       print("🔄 Fetching lab reports for patientId: $patientId");

//       // Date filter
//       String? dateFilter;
//       if (selectedDate != null) {
//         dateFilter = 
//             "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
//         print("📅 Date filter: $dateFilter");
//       }

//       // API Call
//       dynamic response;
      
//       try {
//         print("🔄 Calling API with patientId: $patientId");
//         response = await _apiService.getLabReports(
//           patientId: patientId,
//           date: dateFilter,
//           page: 1,
//           limit: 100,
//         );
//         print("✅ API Response received");
//       } catch (e) {
//         print("❌ API Error: $e");
//         if (mounted) {
//           setState(() {
//             error = "API Error: $e";
//             isLoading = false;
//           });
//         }
//         return;
//       }

//       // Process Response
//       print("=== Processing API Response ===");
      
//       if (response.data['success'] == true) {
//         final data = response.data['data'];
        
//         if (data is List) {
//           print("✅ Found ${data.length} total reports");
          
//           if (data.isEmpty) {
//             print("❌ No reports found");
//             if (mounted) {
//               setState(() {
//                 labReports = [];
//                 selectedReport = null;
//                 currentReportIndex = null;
//                 isLoading = false;
//                 error = "No lab reports found";
//               });
//             }
//             return;
//           }
          
//           // Filter by patientId
//           final filteredReports = data.where((report) {
//             final reportPatientId = report['patientId']?.toString();
//             final match = reportPatientId == patientId;
//             if (match) {
//               print("✅ Matched report ${report['id']} with patientId: $reportPatientId");
//             }
//             return match;
//           }).toList();
          
//           print("✅ Found ${filteredReports.length} reports for patientId: $patientId");
          
//           if (filteredReports.isEmpty) {
//             if (mounted) {
//               setState(() {
//                 labReports = [];
//                 selectedReport = null;
//                 currentReportIndex = null;
//                 isLoading = false;
//                 error = "No lab reports found for this patient";
//               });
//             }
//             return;
//           }
          
//           // Process image URLs
//           final processedData = filteredReports.map((report) {
//             print("📄 Processing report ${report['id']}: ${report['testName']}");
//             if (report['imageUrl'] != null && report['imageUrl'].toString().isNotEmpty) {
//               report['imageUrl'] = getS3ImageUrl(report['imageUrl']);
//               print("  🖼️ Image URL processed");
//             }
//             return report;
//           }).toList();
          
//           print("✅ Successfully processed ${processedData.length} reports");
          
//           if (mounted) {
//             setState(() {
//               labReports = processedData;
//               currentReportIndex = 0;
//               selectedReport = processedData[0];
//               isLoading = false;
//               error = null;
//             });
//           }
          
//         } else if (data is Map) {
//           print("Data is a Map");
          
//           List<dynamic> reports = [];
          
//           if (data.containsKey('results') && data['results'] is List) {
//             reports = data['results'] as List;
//           } else if (data.containsKey('data') && data['data'] is List) {
//             reports = data['data'] as List;
//           }
          
//           if (reports.isEmpty) {
//             if (mounted) {
//               setState(() {
//                 labReports = [];
//                 selectedReport = null;
//                 currentReportIndex = null;
//                 isLoading = false;
//                 error = "No lab reports found";
//               });
//             }
//             return;
//           }
          
//           final filteredReports = reports.where((report) {
//             return report['patientId']?.toString() == patientId;
//           }).toList();
          
//           if (filteredReports.isEmpty) {
//             if (mounted) {
//               setState(() {
//                 labReports = [];
//                 selectedReport = null;
//                 currentReportIndex = null;
//                 isLoading = false;
//                 error = "No lab reports found for this patient";
//               });
//             }
//             return;
//           }
          
//           final processedData = filteredReports.map((report) {
//             if (report['imageUrl'] != null && report['imageUrl'].toString().isNotEmpty) {
//               report['imageUrl'] = getS3ImageUrl(report['imageUrl']);
//             }
//             return report;
//           }).toList();
          
//           if (mounted) {
//             setState(() {
//               labReports = processedData;
//               currentReportIndex = 0;
//               selectedReport = processedData[0];
//               isLoading = false;
//               error = null;
//             });
//           }
          
//         } else {
//           print("❌ Unexpected data type: ${data.runtimeType}");
//           if (mounted) {
//             setState(() {
//               error = "Unexpected data format";
//               isLoading = false;
//             });
//           }
//         }
//       } else {
//         print("❌ API returned success: false");
//         if (mounted) {
//           setState(() {
//             error = response.data['message'] ?? "Failed to fetch reports";
//             isLoading = false;
//           });
//         }
//       }
//     } catch (e, stackTrace) {
//       print("❌ Error: $e");
//       print("StackTrace: $stackTrace");
//       if (mounted) {
//         setState(() {
//           error = "Error: ${e.toString()}";
//           isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> pickDate() async {
//     DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: selectedDate ?? DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime.now(),
//     );

//     if (picked != null && picked != selectedDate) {
//       setState(() {
//         selectedDate = picked;
//       });
//       await _fetchLabReports();
//     }
//   }

//   String _formatDate(String? dateString) {
//     if (dateString == null) return "N/A";
//     try {
//       final date = DateTime.parse(dateString);
//       return "${date.day}${_getDaySuffix(date.day)} ${_getMonthName(date.month)}, ${date.year}";
//     } catch (e) {
//       return dateString;
//     }
//   }

//   String _getDaySuffix(int day) {
//     if (day >= 11 && day <= 13) return "th";
//     switch (day % 10) {
//       case 1: return "st";
//       case 2: return "nd";
//       case 3: return "rd";
//       default: return "th";
//     }
//   }

//   String _getMonthName(int month) {
//     const months = [
//       "January", "February", "March", "April", "May", "June",
//       "July", "August", "September", "October", "November", "December"
//     ];
//     return months[month - 1];
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'completed':
//       case 'final':
//         return Colors.green;
//       case 'pending':
//       case 'received':
//         return Colors.orange;
//       case 'cancelled':
//         return Colors.red;
//       case 'progress':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }

//   void _nextReport() {
//     if (currentReportIndex != null && currentReportIndex! < labReports.length - 1) {
//       setState(() {
//         currentReportIndex = currentReportIndex! + 1;
//         selectedReport = labReports[currentReportIndex!];
//       });
//     }
//   }

//   void _previousReport() {
//     if (currentReportIndex != null && currentReportIndex! > 0) {
//       setState(() {
//         currentReportIndex = currentReportIndex! - 1;
//         selectedReport = labReports[currentReportIndex!];
//       });
//     }
//   }

//   Widget _buildDetailRow(String label, String value, double screenWidth, double screenHeight) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: screenHeight * 0.0025),
//       child: Row(
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: screenWidth * 0.035,
//             ),
//           ),
//           SizedBox(width: screenWidth * 0.0125),
//           Flexible(
//             child: Text(
//               value,
//               style: TextStyle(
//                 color: Colors.blueGrey,
//                 fontSize: screenWidth * 0.035,
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildReportImage(double screenWidth, double screenHeight) {
//     final imageUrl = selectedReport?['imageUrl'];
    
//     final hasImage = (imageUrl != null && imageUrl.toString().isNotEmpty);
    
//     if (!hasImage) {
//       return Container(
//         height: screenHeight * 0.12,
//         decoration: BoxDecoration(
//           color: Colors.grey.shade100,
//           borderRadius: BorderRadius.circular(screenWidth * 0.025),
//           border: Border.all(
//             color: Colors.grey.shade300,
//             width: screenWidth * 0.0025,
//           ),
//         ),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.image_not_supported,
//                 color: Colors.grey.shade400,
//                 size: screenWidth * 0.1,
//               ),
//               SizedBox(height: screenHeight * 0.01),
//               Text(
//                 "No image attached",
//                 style: TextStyle(
//                   color: Colors.grey.shade600,
//                   fontSize: screenWidth * 0.03,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     return GestureDetector(
//       onTap: () {
//         _showFullScreenImage(context, imageUrl);
//       },
//       child: Container(
//         height: screenHeight * 0.15,
//         decoration: BoxDecoration(
//           color: Colors.grey.shade100,
//           borderRadius: BorderRadius.circular(screenWidth * 0.025),
//           border: Border.all(
//             color: Colors.grey.shade300,
//             width: screenWidth * 0.0025,
//           ),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(screenWidth * 0.025),
//           child: Stack(
//             fit: StackFit.expand,
//             children: [
//               CachedNetworkImage(
//                 imageUrl: imageUrl,
//                 fit: BoxFit.contain,
//                 placeholder: (context, url) => Center(
//                   child: CircularProgressIndicator(
//                     color: Colors.green,
//                   ),
//                 ),
//                 errorWidget: (context, url, error) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.broken_image,
//                           color: Colors.grey.shade400,
//                           size: screenWidth * 0.1,
//                         ),
//                         SizedBox(height: screenHeight * 0.01),
//                         Text(
//                           "Failed to load image",
//                           style: TextStyle(
//                             color: Colors.grey.shade600,
//                             fontSize: screenWidth * 0.03,
//                           ),
//                         ),
//                         Text(
//                           "Tap to retry",
//                           style: TextStyle(
//                             color: Colors.green,
//                             fontSize: screenWidth * 0.025,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//               Positioned(
//                 bottom: screenHeight * 0.01,
//                 right: screenWidth * 0.02,
//                 child: Container(
//                   padding: EdgeInsets.symmetric(
//                     horizontal: screenWidth * 0.03,
//                     vertical: screenHeight * 0.0075,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.black54,
//                     borderRadius: BorderRadius.circular(screenWidth * 0.05),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(
//                         Icons.zoom_in,
//                         color: Colors.white,
//                         size: screenWidth * 0.04,
//                       ),
//                       SizedBox(width: screenWidth * 0.01),
//                       Text(
//                         "Tap to zoom",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: screenWidth * 0.03,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showFullScreenImage(BuildContext context, String imageUrl) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
    
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         insetPadding: EdgeInsets.all(screenWidth * 0.02),
//         child: Container(
//           width: double.infinity,
//           height: double.infinity,
//           decoration: BoxDecoration(
//             color: Colors.black87,
//             borderRadius: BorderRadius.circular(screenWidth * 0.03),
//           ),
//           child: Stack(
//             children: [
//               Center(
//                 child: InteractiveViewer(
//                   minScale: 0.5,
//                   maxScale: 4.0,
//                   child: CachedNetworkImage(
//                     imageUrl: imageUrl,
//                     fit: BoxFit.contain,
//                     placeholder: (context, url) => Center(
//                       child: CircularProgressIndicator(
//                         color: Colors.white,
//                       ),
//                     ),
//                     errorWidget: (context, url, error) => Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             Icons.broken_image,
//                             color: Colors.white54,
//                             size: screenWidth * 0.15,
//                           ),
//                           SizedBox(height: screenHeight * 0.02),
//                           Text(
//                             "Failed to load image",
//                             style: TextStyle(
//                               color: Colors.white54,
//                               fontSize: screenWidth * 0.04,
//                             ),
//                           ),
//                           SizedBox(height: screenHeight * 0.01),
//                           ElevatedButton(
//                             onPressed: () {
//                               setState(() {});
//                               Navigator.pop(context);
//                               _showFullScreenImage(context, imageUrl);
//                             },
//                             child: Text("Retry"),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               Positioned(
//                 top: screenHeight * 0.02,
//                 right: screenWidth * 0.04,
//                 child: IconButton(
//                   icon: Icon(
//                     Icons.close,
//                     color: Colors.white,
//                     size: screenWidth * 0.08,
//                   ),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ),
//               Positioned(
//                 bottom: screenHeight * 0.02,
//                 left: 0,
//                 right: 0,
//                 child: Center(
//                   child: Container(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: screenWidth * 0.04,
//                       vertical: screenHeight * 0.01,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.black54,
//                       borderRadius: BorderRadius.circular(screenWidth * 0.05),
//                     ),
//                     child: Text(
//                       "Pinch to zoom • Drag to pan",
//                       style: TextStyle(
//                         color: Colors.white70,
//                         fontSize: screenWidth * 0.03,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPatientInfoWrap(String label, String value, double screenWidth, double screenHeight) {
//     return Container(
//       constraints: BoxConstraints(
//         minWidth: screenWidth * 0.2,
//         maxWidth: screenWidth * 0.45,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               color: Colors.blueGrey,
//               fontSize: screenWidth * 0.025,
//             ),
//             overflow: TextOverflow.ellipsis,
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: screenWidth * 0.025,
//               fontWeight: FontWeight.w500,
//             ),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isSmallScreen = screenWidth < 600;
//     final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
//     final isLargeScreen = screenWidth >= 1024;

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         title: Text(
//           "Lab Details",
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: isSmallScreen 
//                 ? screenWidth * 0.05 
//                 : isMediumScreen 
//                     ? screenWidth * 0.035 
//                     : screenWidth * 0.025,
//           ),
//         ),
//         centerTitle: true,
//         leading: IconButton(
//           onPressed: () {
//             Navigator.pop(context);
//           },
//           icon: Icon(
//             Icons.arrow_back_ios_new,
//             color: Colors.white,
//             size: isSmallScreen 
//                 ? screenWidth * 0.055 
//                 : isMediumScreen 
//                     ? screenWidth * 0.04 
//                     : screenWidth * 0.03,
//           ),
//         ),
//         toolbarHeight: isSmallScreen 
//             ? kToolbarHeight 
//             : isMediumScreen 
//                 ? kToolbarHeight * 1.1 
//                 : kToolbarHeight * 1.2,
//       ),
//       body: Padding(
//         padding: EdgeInsets.only(
//           left: screenWidth * 0.04,
//           right: screenWidth * 0.04,
//           top: screenHeight * 0.02,
//           bottom: screenHeight * 0.02,   
//         ),
//         child: isLoading
//             ? Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     CircularProgressIndicator(
//                       color: Colors.green,
//                       strokeWidth: isSmallScreen ? 4 : 6,
//                     ),
//                     SizedBox(height: screenHeight * 0.025),
//                     Text(
//                       "Loading reports...",
//                       style: TextStyle(
//                         fontSize: isSmallScreen 
//                             ? screenWidth * 0.04 
//                             : screenWidth * 0.03,
//                       ),
//                     ),
//                   ],
//                 ),
//               )
//             : error != null
//                 ? Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.error_outline,
//                           color: Colors.red,
//                           size: isSmallScreen ? 60 : 80,
//                         ),
//                         SizedBox(height: screenHeight * 0.0125),
//                         Padding(
//                           padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
//                           child: Text(
//                             error!,
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               color: Colors.red,
//                               fontSize: isSmallScreen ? 16 : 18,
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: screenHeight * 0.025),
//                         ElevatedButton(
//                           onPressed: _fetchLabReports,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green,
//                             padding: EdgeInsets.symmetric(
//                               horizontal: screenWidth * 0.06,
//                               vertical: screenHeight * 0.015,
//                             ),
//                           ),
//                           child: Text(
//                             "Retry",
//                             style: TextStyle(
//                               fontSize: isSmallScreen ? 14 : 16,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 : labReports.isEmpty
//                     ? Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.assignment_outlined,
//                               color: Colors.grey,
//                               size: isSmallScreen ? 80 : 100,
//                             ),
//                             SizedBox(height: screenHeight * 0.0125),
//                             Text(
//                               "No lab reports found",
//                               style: TextStyle(
//                                 color: Colors.grey,
//                                 fontSize: isSmallScreen ? 18 : 22,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                             if (selectedDate != null)
//                               Padding(
//                                 padding: EdgeInsets.only(top: screenHeight * 0.0125),
//                                 child: Text(
//                                   "No reports for ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
//                                   style: TextStyle(
//                                     color: Colors.grey,
//                                     fontSize: isSmallScreen ? 14 : 16,
//                                   ),
//                                 ),
//                               ),
//                             SizedBox(height: screenHeight * 0.025),
//                             ElevatedButton(
//                               onPressed: () {
//                                 setState(() {
//                                   selectedDate = null;
//                                 });
//                                 _fetchLabReports();
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.green,
//                                 padding: EdgeInsets.symmetric(
//                                   horizontal: screenWidth * 0.06,
//                                   vertical: screenHeight * 0.015,
//                                 ),
//                               ),
//                               child: Text(
//                                 "Clear Filter",
//                                 style: TextStyle(
//                                   fontSize: isSmallScreen ? 14 : 16,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       )
//                     : SingleChildScrollView(
//                         child: isLargeScreen
//                             ? _buildLargeScreenLayout(screenWidth, screenHeight)
//                             : _buildSmallMediumScreenLayout(screenWidth, screenHeight),
//                       ),
//       ),
//     );
//   }

//   Widget _buildSmallMediumScreenLayout(double screenWidth, double screenHeight) {
//     final isSmallScreen = screenWidth < 600;
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildDatePicker(screenWidth, screenHeight),
        
//         if (labReports.length > 1) ...[
//           SizedBox(height: screenHeight * 0.0125),
//           _buildReportNavigator(screenWidth, screenHeight),
//         ],

//         SizedBox(height: screenHeight * 0.0125),
//         Divider(
//           color: Colors.grey,
//           thickness: screenWidth * 0.0025,
//         ),
//         SizedBox(height: screenHeight * 0.0125),

//         if (selectedReport != null) ...[
//           _buildReportHeader(screenWidth, screenHeight),
//           _buildReportDetails(screenWidth, screenHeight),
//           _buildPatientInfo(screenWidth, screenHeight),
//           _buildReportImage(screenWidth, screenHeight),
//         ],
        
//         SizedBox(height: screenHeight * 0.02),
//       ],
//     );
//   }

//   Widget _buildLargeScreenLayout(double screenWidth, double screenHeight) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           flex: 1,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildDatePicker(screenWidth, screenHeight),
              
//               if (labReports.length > 1) ...[
//                 SizedBox(height: screenHeight * 0.0125),
//                 _buildReportNavigator(screenWidth, screenHeight),
//               ],
//             ],
//           ),
//         ),
//         SizedBox(width: screenWidth * 0.03),
//         Expanded(
//           flex: 2,
//           child: selectedReport != null
//               ? Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildReportHeader(screenWidth, screenHeight),
//                     _buildReportDetails(screenWidth, screenHeight),
//                     _buildPatientInfo(screenWidth, screenHeight),
//                     _buildReportImage(screenWidth, screenHeight),
//                   ],
//                 )
//               : Center(
//                   child: Text(
//                     "Select a report to view details",
//                     style: TextStyle(
//                       fontSize: screenWidth * 0.02,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDatePicker(double screenWidth, double screenHeight) {
//     return GestureDetector(
//       onTap: pickDate,
//       child: Container(
//         padding: EdgeInsets.symmetric(
//           horizontal: screenWidth * 0.03,
//           vertical: screenHeight * 0.0125,
//         ),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(screenWidth * 0.03),
//           border: Border.all(color: Colors.grey, width: screenWidth * 0.0025),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               Icons.calendar_today,
//               color: Colors.green,
//               size: screenWidth * 0.05,
//             ),
//             SizedBox(width: screenWidth * 0.025),
//             Expanded(
//               child: Text(
//                 selectedDate == null
//                     ? "All reports"
//                     : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
//                 style: TextStyle(
//                   fontSize: screenWidth * 0.035,
//                   color: selectedDate == null ? Colors.grey : Colors.black87,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             if (selectedDate != null)
//               GestureDetector(
//                 onTap: () {
//                   setState(() {
//                     selectedDate = null;
//                   });
//                   _fetchLabReports();
//                 },
//                 child: Icon(
//                   Icons.close,
//                   size: screenWidth * 0.045,
//                   color: Colors.grey,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildReportNavigator(double screenWidth, double screenHeight) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: screenWidth * 0.02,
//         vertical: screenHeight * 0.01,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.green.shade50,
//         borderRadius: BorderRadius.circular(screenWidth * 0.02),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             "Total Reports: ${labReports.length}",
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: screenWidth * 0.035,
//               color: Colors.green.shade800,
//             ),
//           ),
//           Row(
//             children: [
//               IconButton(
//                 onPressed: currentReportIndex != null && currentReportIndex! > 0
//                     ? _previousReport
//                     : null,
//                 icon: Icon(
//                   Icons.arrow_back_ios,
//                   size: screenWidth * 0.04,
//                   color: currentReportIndex != null && currentReportIndex! > 0
//                       ? Colors.green
//                       : Colors.grey,
//                 ),
//               ),
//               Text(
//                 "${(currentReportIndex ?? 0) + 1} of ${labReports.length}",
//                 style: TextStyle(
//                   fontWeight: FontWeight.w500,
//                   fontSize: screenWidth * 0.035,
//                 ),
//               ),
//               IconButton(
//                 onPressed: currentReportIndex != null && currentReportIndex! < labReports.length - 1
//                     ? _nextReport
//                     : null,
//                 icon: Icon(
//                   Icons.arrow_forward_ios,
//                   size: screenWidth * 0.04,
//                   color: currentReportIndex != null && currentReportIndex! < labReports.length - 1
//                       ? Colors.green
//                       : Colors.grey,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildReportHeader(double screenWidth, double screenHeight) {
//     return Column(
//       children: [
//         Center(
//           child: Text(
//             selectedReport['hospitalId'] != null 
//                 ? "Hospital #${selectedReport['hospitalId']}" 
//                 : "Lab Report",
//             style: TextStyle(
//               color: Colors.green,
//               fontSize: screenWidth * 0.055,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
        
//         if (selectedReport['department'] != null) ...[
//           Center(
//             child: Text(
//               selectedReport['department'].toString().toUpperCase(),
//               style: TextStyle(
//                 color: Colors.grey,
//                 fontSize: screenWidth * 0.035,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ),
//         ],
        
//         Divider(
//           indent: screenWidth * 0.075,
//           endIndent: screenWidth * 0.075,
//           color: Colors.grey,
//           thickness: screenWidth * 0.0025,
//         ),
//         SizedBox(height: screenHeight * 0.0125),
        
//         Center(
//           child: Text(
//             "Pathology Laboratory Report",
//             style: TextStyle(
//               fontSize: screenWidth * 0.05,
//               fontWeight: FontWeight.w400,
//             ),
//           ),
//         ),
//         SizedBox(height: screenHeight * 0.01875),
//       ],
//     );
//   }

//   Widget _buildReportDetails(double screenWidth, double screenHeight) {
//     final isSmallScreen = screenWidth < 600;
    
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               if (selectedReport['doctorId'] != null)
//                 _buildDetailRow(
//                   "Doctor ID:", 
//                   "DR${selectedReport['doctorId'].toString().padLeft(3, '0')}",
//                   screenWidth,
//                   screenHeight
//                 ),
//               if (selectedReport['department'] != null)
//                 _buildDetailRow(
//                   "Department:", 
//                   selectedReport['department'].toString().toUpperCase(),
//                   screenWidth,
//                   screenHeight
//                 ),
//               if (selectedReport['testName'] != null)
//                 _buildDetailRow(
//                   "Test Name:", 
//                   selectedReport['testName'],
//                   screenWidth,
//                   screenHeight
//                 ),
//               _buildDetailRow(
//                 "Report ID:", 
//                 "#${selectedReport['id'] ?? ''}",
//                 screenWidth,
//                 screenHeight
//               ),
//             ],
//           ),
//         ),
//         SizedBox(width: isSmallScreen ? 10 : 20),
        
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               _buildDetailRow(
//                 "Collected on:", 
//                 _formatDate(selectedReport['createdAt']),
//                 screenWidth,
//                 screenHeight
//               ),
//               _buildDetailRow(
//                 "Reported on:", 
//                 _formatDate(selectedReport['updatedAt']),
//                 screenWidth,
//                 screenHeight
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   Text(
//                     "Status:",
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: screenWidth * 0.035,
//                     ),
//                   ),
//                   SizedBox(width: screenWidth * 0.0125),
//                   Container(
//                     padding: EdgeInsets.symmetric(
//                       horizontal: screenWidth * 0.02,
//                       vertical: screenHeight * 0.005,
//                     ),
//                     decoration: BoxDecoration(
//                       color: _getStatusColor(selectedReport['status'] ?? '').withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(screenWidth * 0.02),
//                       border: Border.all(
//                         color: _getStatusColor(selectedReport['status'] ?? ''),
//                         width: screenWidth * 0.0025,
//                       ),
//                     ),
//                     child: Text(
//                       selectedReport['status']?.toString().toUpperCase() ?? '',
//                       style: TextStyle(
//                         color: _getStatusColor(selectedReport['status'] ?? ''),
//                         fontSize: screenWidth * 0.032,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPatientInfo(double screenWidth, double screenHeight) {
//     return Column(
//       children: [
//         SizedBox(height: screenHeight * 0.01875),
//         Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             color: Colors.green.shade50,
//             borderRadius: BorderRadius.circular(screenWidth * 0.025),
//             border: Border.all(
//               color: Colors.green,
//               width: screenWidth * 0.0025,
//             ),
//           ),
//           child: Padding(
//             padding: EdgeInsets.all(screenWidth * 0.02),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "Patient Information",
//                   style: TextStyle(
//                     color: Colors.green,
//                     fontWeight: FontWeight.bold,
//                     fontSize: screenWidth * 0.035,
//                   ),
//                 ),
//                 SizedBox(height: screenHeight * 0.005),
//                 Wrap(
//                   spacing: screenWidth * 0.025,
//                   runSpacing: screenHeight * 0.005,
//                   children: [
//                     if (selectedReport['patientId'] != null &&
//                         selectedReport['patientId'].toString().isNotEmpty)
//                       _buildPatientInfoWrap(
//                         "Patient ID:", 
//                         "PT${selectedReport['patientId'].toString().padLeft(3, '0')}",
//                         screenWidth,
//                         screenHeight
//                       ),
//                     if (selectedReport['testName'] != null &&
//                         selectedReport['testName'].toString().isNotEmpty)
//                       _buildPatientInfoWrap(
//                         "Test Name:", 
//                         selectedReport['testName'].toString(),
//                         screenWidth,
//                         screenHeight
//                       ),
//                     if (selectedReport['department'] != null &&
//                         selectedReport['department'].toString().isNotEmpty)
//                       _buildPatientInfoWrap(
//                         "Department:", 
//                         selectedReport['department'].toString().toUpperCase(),
//                         screenWidth,
//                         screenHeight
//                       ),
//                     if (selectedReport['status'] != null &&
//                         selectedReport['status'].toString().isNotEmpty)
//                       _buildPatientInfoWrap(
//                         "Status:", 
//                         selectedReport['status'].toString().toUpperCase(),
//                         screenWidth,
//                         screenHeight
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//         SizedBox(height: screenHeight * 0.0125),
//       ],
//     );
//   }
// }





import 'package:flutter/material.dart';
import 'package:hosta/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LabReport extends StatefulWidget {
  const LabReport({super.key});

  @override
  State<LabReport> createState() => _LabReportState();
}

class _LabReportState extends State<LabReport> {
  final ApiService _apiService = ApiService();
  DateTime? selectedDate;
  bool isLoading = false;
  List<dynamic> labReports = [];
  dynamic selectedReport;
  String? error;
  int? currentReportIndex;

  static const String S3_BASE_URL = 
      "https://hostahealthcare.s3.eu-north-1.amazonaws.com";

  @override
  void initState() {
    super.initState();
    _fetchLabReports();
  }

  String? getS3ImageUrl(String? key) {
    if (key == null || key.isEmpty) return null;
    if (key.startsWith('http://') || key.startsWith('https://')) {
      return key;
    }
    return '$S3_BASE_URL/${Uri.encodeComponent(key)}';
  }

  Future<String?> _getPatientId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String? patientId = prefs.getString('patientId');
      
      if (patientId != null && patientId.isNotEmpty) {
        return patientId;
      }
      
      await prefs.setString('patientId', '85');
      return "85";
      
    } catch (e) {
      return "85";
    }
  }

  Future<void> _fetchLabReports() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      String? patientId = await _getPatientId();
      
      if (patientId == null || patientId.isEmpty) {
        if (mounted) {
          setState(() {
            error = "No patient found";
            isLoading = false;
          });
        }
        return;
      }

      String? dateFilter;
      if (selectedDate != null) {
        dateFilter = 
            "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
      }

      dynamic response;
      
      try {
        response = await _apiService.getLabReports(
          patientId: patientId,
          date: dateFilter,
          page: 1,
          limit: 100,
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            error = "API Error: $e";
            isLoading = false;
          });
        }
        return;
      }

      if (response.data['success'] == true) {
        final data = response.data['data'];
        
        if (data is List) {
          if (data.isEmpty) {
            if (mounted) {
              setState(() {
                labReports = [];
                selectedReport = null;
                currentReportIndex = null;
                isLoading = false;
                error = "No lab reports found";
              });
            }
            return;
          }
          
          final filteredReports = data.where((report) {
            final reportPatientId = report['patientId']?.toString();
            return reportPatientId == patientId;
          }).toList();
          
          if (filteredReports.isEmpty) {
            if (mounted) {
              setState(() {
                labReports = [];
                selectedReport = null;
                currentReportIndex = null;
                isLoading = false;
                error = "No lab reports found for this patient";
              });
            }
            return;
          }
          
          final processedData = filteredReports.map((report) {
            if (report['imageUrl'] != null && report['imageUrl'].toString().isNotEmpty) {
              report['imageUrl'] = getS3ImageUrl(report['imageUrl']);
            }
            return report;
          }).toList();
          
          if (mounted) {
            setState(() {
              labReports = processedData;
              currentReportIndex = 0;
              selectedReport = processedData[0];
              isLoading = false;
              error = null;
            });
          }
          
        } else if (data is Map) {
          List<dynamic> reports = [];
          
          if (data.containsKey('results') && data['results'] is List) {
            reports = data['results'] as List;
          } else if (data.containsKey('data') && data['data'] is List) {
            reports = data['data'] as List;
          }
          
          if (reports.isEmpty) {
            if (mounted) {
              setState(() {
                labReports = [];
                selectedReport = null;
                currentReportIndex = null;
                isLoading = false;
                error = "No lab reports found";
              });
            }
            return;
          }
          
          final filteredReports = reports.where((report) {
            return report['patientId']?.toString() == patientId;
          }).toList();
          
          if (filteredReports.isEmpty) {
            if (mounted) {
              setState(() {
                labReports = [];
                selectedReport = null;
                currentReportIndex = null;
                isLoading = false;
                error = "No lab reports found for this patient";
              });
            }
            return;
          }
          
          final processedData = filteredReports.map((report) {
            if (report['imageUrl'] != null && report['imageUrl'].toString().isNotEmpty) {
              report['imageUrl'] = getS3ImageUrl(report['imageUrl']);
            }
            return report;
          }).toList();
          
          if (mounted) {
            setState(() {
              labReports = processedData;
              currentReportIndex = 0;
              selectedReport = processedData[0];
              isLoading = false;
              error = null;
            });
          }
          
        } else {
          if (mounted) {
            setState(() {
              error = "Unexpected data format";
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            error = response.data['message'] ?? "Failed to fetch reports";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = "Error: ${e.toString()}";
          isLoading = false;
        });
      }
    }
  }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      await _fetchLabReports();
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "N/A";
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}${_getDaySuffix(date.day)} ${_getMonthName(date.month)}, ${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return "th";
    switch (day % 10) {
      case 1: return "st";
      case 2: return "nd";
      case 3: return "rd";
      default: return "th";
    }
  }

  String _getMonthName(int month) {
    const months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[month - 1];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'final':
        return Colors.green;
      case 'pending':
      case 'received':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _nextReport() {
    if (currentReportIndex != null && currentReportIndex! < labReports.length - 1) {
      setState(() {
        currentReportIndex = currentReportIndex! + 1;
        selectedReport = labReports[currentReportIndex!];
      });
    }
  }

  void _previousReport() {
    if (currentReportIndex != null && currentReportIndex! > 0) {
      setState(() {
        currentReportIndex = currentReportIndex! - 1;
        selectedReport = labReports[currentReportIndex!];
      });
    }
  }

  Widget _buildDetailRow(String label, String value, double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.0025),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.035,
            ),
          ),
          SizedBox(width: screenWidth * 0.0125),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: screenWidth * 0.035,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportImage(double screenWidth, double screenHeight) {
    final imageUrl = selectedReport?['imageUrl'];
    
    final hasImage = (imageUrl != null && imageUrl.toString().isNotEmpty);
    
    if (!hasImage) {
      return Container(
        height: screenHeight * 0.12,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          border: Border.all(
            color: Colors.grey.shade300,
            width: screenWidth * 0.0025,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                color: Colors.grey.shade400,
                size: screenWidth * 0.1,
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                "No image attached",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: screenWidth * 0.03,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        _showFullScreenImage(context, imageUrl);
      },
      child: Container(
        height: screenHeight * 0.15,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          border: Border.all(
            color: Colors.grey.shade300,
            width: screenWidth * 0.0025,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    color: Colors.green,
                  ),
                ),
                errorWidget: (context, url, error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.grey.shade400,
                          size: screenWidth * 0.1,
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          "Failed to load image",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.03,
                          ),
                        ),
                        Text(
                          "Tap to retry",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: screenWidth * 0.025,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                bottom: screenHeight * 0.01,
                right: screenWidth * 0.02,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenHeight * 0.0075,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: screenWidth * 0.04,
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        "Tap to zoom",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.03,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(screenWidth * 0.02),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                            size: screenWidth * 0.15,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          Text(
                            "Failed to load image",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: screenWidth * 0.04,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {});
                              Navigator.pop(context);
                              _showFullScreenImage(context, imageUrl);
                            },
                            child: Text("Retry"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: screenHeight * 0.02,
                right: screenWidth * 0.04,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: screenWidth * 0.08,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                bottom: screenHeight * 0.02,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(screenWidth * 0.05),
                    ),
                    child: Text(
                      "Pinch to zoom • Drag to pan",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: screenWidth * 0.03,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfoWrap(String label, String value, double screenWidth, double screenHeight) {
    return Container(
      constraints: BoxConstraints(
        minWidth: screenWidth * 0.2,
        maxWidth: screenWidth * 0.45,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.blueGrey,
              fontSize: screenWidth * 0.025,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.025,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
    final isLargeScreen = screenWidth >= 1024;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Lab Details",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen 
                ? screenWidth * 0.05 
                : isMediumScreen 
                    ? screenWidth * 0.035 
                    : screenWidth * 0.025,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: isSmallScreen 
                ? screenWidth * 0.055 
                : isMediumScreen 
                    ? screenWidth * 0.04 
                    : screenWidth * 0.03,
          ),
        ),
        toolbarHeight: isSmallScreen 
            ? kToolbarHeight 
            : isMediumScreen 
                ? kToolbarHeight * 1.1 
                : kToolbarHeight * 1.2,
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: screenWidth * 0.04,
          right: screenWidth * 0.04,
          top: screenHeight * 0.02,
          bottom: screenHeight * 0.02,   
        ),
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.green,
                      strokeWidth: isSmallScreen ? 4 : 6,
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    Text(
                      "Loading reports...",
                      style: TextStyle(
                        fontSize: isSmallScreen 
                            ? screenWidth * 0.04 
                            : screenWidth * 0.03,
                      ),
                    ),
                  ],
                ),
              )
            : error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: isSmallScreen ? 60 : 80,
                        ),
                        SizedBox(height: screenHeight * 0.0125),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                          child: Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: isSmallScreen ? 16 : 18,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.025),
                        ElevatedButton(
                          onPressed: _fetchLabReports,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.06,
                              vertical: screenHeight * 0.015,
                            ),
                          ),
                          child: Text(
                            "Retry",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : labReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              color: Colors.grey,
                              size: isSmallScreen ? 80 : 100,
                            ),
                            SizedBox(height: screenHeight * 0.0125),
                            Text(
                              "No lab reports found",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: isSmallScreen ? 18 : 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (selectedDate != null)
                              Padding(
                                padding: EdgeInsets.only(top: screenHeight * 0.0125),
                                child: Text(
                                  "No reports for ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                              ),
                            SizedBox(height: screenHeight * 0.025),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedDate = null;
                                });
                                _fetchLabReports();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.06,
                                  vertical: screenHeight * 0.015,
                                ),
                              ),
                              child: Text(
                                "Clear Filter",
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: isLargeScreen
                            ? _buildLargeScreenLayout(screenWidth, screenHeight)
                            : _buildSmallMediumScreenLayout(screenWidth, screenHeight),
                      ),
      ),
    );
  }

  Widget _buildSmallMediumScreenLayout(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDatePicker(screenWidth, screenHeight),
        
        if (labReports.length > 1) ...[
          SizedBox(height: screenHeight * 0.0125),
          _buildReportNavigator(screenWidth, screenHeight),
        ],

        SizedBox(height: screenHeight * 0.0125),
        Divider(
          color: Colors.grey,
          thickness: screenWidth * 0.0025,
        ),
        SizedBox(height: screenHeight * 0.0125),

        if (selectedReport != null) ...[
          _buildReportHeader(screenWidth, screenHeight),
          _buildReportDetails(screenWidth, screenHeight),
          _buildPatientInfo(screenWidth, screenHeight),
          _buildReportImage(screenWidth, screenHeight),
        ],
        
        SizedBox(height: screenHeight * 0.02),
      ],
    );
  }

  Widget _buildLargeScreenLayout(double screenWidth, double screenHeight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDatePicker(screenWidth, screenHeight),
              
              if (labReports.length > 1) ...[
                SizedBox(height: screenHeight * 0.0125),
                _buildReportNavigator(screenWidth, screenHeight),
              ],
            ],
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          flex: 2,
          child: selectedReport != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReportHeader(screenWidth, screenHeight),
                    _buildReportDetails(screenWidth, screenHeight),
                    _buildPatientInfo(screenWidth, screenHeight),
                    _buildReportImage(screenWidth, screenHeight),
                  ],
                )
              : Center(
                  child: Text(
                    "Select a report to view details",
                    style: TextStyle(
                      fontSize: screenWidth * 0.02,
                      color: Colors.grey,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(double screenWidth, double screenHeight) {
    return GestureDetector(
      onTap: pickDate,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenHeight * 0.0125,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(color: Colors.grey, width: screenWidth * 0.0025),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Colors.green,
              size: screenWidth * 0.05,
            ),
            SizedBox(width: screenWidth * 0.025),
            Expanded(
              child: Text(
                selectedDate == null
                    ? "All reports"
                    : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: selectedDate == null ? Colors.grey : Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (selectedDate != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = null;
                  });
                  _fetchLabReports();
                },
                child: Icon(
                  Icons.close,
                  size: screenWidth * 0.045,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportNavigator(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: screenHeight * 0.01,
      ),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Total Reports: ${labReports.length}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.035,
              color: Colors.green.shade800,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: currentReportIndex != null && currentReportIndex! > 0
                    ? _previousReport
                    : null,
                icon: Icon(
                  Icons.arrow_back_ios,
                  size: screenWidth * 0.04,
                  color: currentReportIndex != null && currentReportIndex! > 0
                      ? Colors.green
                      : Colors.grey,
                ),
              ),
              Text(
                "${(currentReportIndex ?? 0) + 1} of ${labReports.length}",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: screenWidth * 0.035,
                ),
              ),
              IconButton(
                onPressed: currentReportIndex != null && currentReportIndex! < labReports.length - 1
                    ? _nextReport
                    : null,
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: screenWidth * 0.04,
                  color: currentReportIndex != null && currentReportIndex! < labReports.length - 1
                      ? Colors.green
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportHeader(double screenWidth, double screenHeight) {
    return Column(
      children: [
        Center(
          child: Text(
            selectedReport['hospitalId'] != null 
                ? "Hospital #${selectedReport['hospitalId']}" 
                : "Lab Report",
            style: TextStyle(
              color: Colors.green,
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        if (selectedReport['department'] != null) ...[
          Center(
            child: Text(
              selectedReport['department'].toString().toUpperCase(),
              style: TextStyle(
                color: Colors.grey,
                fontSize: screenWidth * 0.035,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        
        Divider(
          indent: screenWidth * 0.075,
          endIndent: screenWidth * 0.075,
          color: Colors.grey,
          thickness: screenWidth * 0.0025,
        ),
        SizedBox(height: screenHeight * 0.0125),
        
        Center(
          child: Text(
            "Pathology Laboratory Report",
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.01875),
      ],
    );
  }

  Widget _buildReportDetails(double screenWidth, double screenHeight) {
    final isSmallScreen = screenWidth < 600;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedReport['doctorId'] != null)
                _buildDetailRow(
                  "Doctor ID:", 
                  "DR${selectedReport['doctorId'].toString().padLeft(3, '0')}",
                  screenWidth,
                  screenHeight
                ),
              if (selectedReport['department'] != null)
                _buildDetailRow(
                  "Department:", 
                  selectedReport['department'].toString().toUpperCase(),
                  screenWidth,
                  screenHeight
                ),
              if (selectedReport['testName'] != null)
                _buildDetailRow(
                  "Test Name:", 
                  selectedReport['testName'],
                  screenWidth,
                  screenHeight
                ),
              _buildDetailRow(
                "Report ID:", 
                "#${selectedReport['id'] ?? ''}",
                screenWidth,
                screenHeight
              ),
            ],
          ),
        ),
        SizedBox(width: isSmallScreen ? 10 : 20),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildDetailRow(
                "Collected on:", 
                _formatDate(selectedReport['createdAt']),
                screenWidth,
                screenHeight
              ),
              _buildDetailRow(
                "Reported on:", 
                _formatDate(selectedReport['updatedAt']),
                screenWidth,
                screenHeight
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Status:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.0125),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.02,
                      vertical: screenHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(selectedReport['status'] ?? '').withOpacity(0.1),
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      border: Border.all(
                        color: _getStatusColor(selectedReport['status'] ?? ''),
                        width: screenWidth * 0.0025,
                      ),
                    ),
                    child: Text(
                      selectedReport['status']?.toString().toUpperCase() ?? '',
                      style: TextStyle(
                        color: _getStatusColor(selectedReport['status'] ?? ''),
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfo(double screenWidth, double screenHeight) {
    return Column(
      children: [
        SizedBox(height: screenHeight * 0.01875),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(screenWidth * 0.025),
            border: Border.all(
              color: Colors.green,
              width: screenWidth * 0.0025,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Patient Information",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Wrap(
                  spacing: screenWidth * 0.025,
                  runSpacing: screenHeight * 0.005,
                  children: [
                    if (selectedReport['patientId'] != null &&
                        selectedReport['patientId'].toString().isNotEmpty)
                      _buildPatientInfoWrap(
                        "Patient ID:", 
                        "PT${selectedReport['patientId'].toString().padLeft(3, '0')}",
                        screenWidth,
                        screenHeight
                      ),
                    if (selectedReport['testName'] != null &&
                        selectedReport['testName'].toString().isNotEmpty)
                      _buildPatientInfoWrap(
                        "Test Name:", 
                        selectedReport['testName'].toString(),
                        screenWidth,
                        screenHeight
                      ),
                    if (selectedReport['department'] != null &&
                        selectedReport['department'].toString().isNotEmpty)
                      _buildPatientInfoWrap(
                        "Department:", 
                        selectedReport['department'].toString().toUpperCase(),
                        screenWidth,
                        screenHeight
                      ),
                    if (selectedReport['status'] != null &&
                        selectedReport['status'].toString().isNotEmpty)
                      _buildPatientInfoWrap(
                        "Status:", 
                        selectedReport['status'].toString().toUpperCase(),
                        screenWidth,
                        screenHeight
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: screenHeight * 0.0125),
      ],
    );
  }
}