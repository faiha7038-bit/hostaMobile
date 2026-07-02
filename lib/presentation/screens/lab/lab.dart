import 'package:flutter/material.dart';
import 'package:hosta/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:developer';

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

  // S3 Base URL
  static const String S3_BASE_URL = 
      "https://hostahealthcare.s3.eu-north-1.amazonaws.com";

  @override
  void initState() {
    super.initState();
    _fetchLabReports();
  }

  // Helper to get full S3 image URL
  String? getS3ImageUrl(String? key) {
    if (key == null || key.isEmpty) return null;
    
    // If it's already a full URL, return as is
    if (key.startsWith('http://') || key.startsWith('https://')) {
      return key;
    }
    
    // Construct S3 URL
    return '$S3_BASE_URL/${Uri.encodeComponent(key)}';
  }

  // Fetch lab reports from API
  Future<void> _fetchLabReports() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      String? userId = prefs.getString('userId');
      final userType = prefs.getString('userType') ?? 'patient';

      if (userId == "3") {
        String? patientId = prefs.getString('patientId');
        if (patientId != null && patientId.isNotEmpty) {
          userId = patientId;
        }
      }

      if (userId == null || userId.isEmpty) {
        setState(() {
          error = "User not logged in. Please login again.";
          isLoading = false;
        });
        return;
      }

      String? dateFilter;
      if (selectedDate != null) {
        dateFilter = 
            "${selectedDate!.year.toString().padLeft(4, '0')}-"
            "${selectedDate!.month.toString().padLeft(2, '0')}-"
            "${selectedDate!.day.toString().padLeft(2, '0')}";
      }

      dynamic response;
      
      response = await _apiService.getLabReports(
        patientId: userId,
        date: dateFilter,
        page: 1,
        limit: 100,
      );
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is List && data.isEmpty) {
          response = await _apiService.getLabReports(
            date: dateFilter,
            page: 1,
            limit: 100,
          );
        }
      }

      if (response.data['success'] == true) {
        final data = response.data['data'];
        
        if (data is List && data.isNotEmpty) {
          // Process each report to ensure image URL is correct
          final processedData = data.map((report) {
            if (report['imageKey'] != null && report['imageKey'].toString().isNotEmpty) {
              report['imageUrl'] = getS3ImageUrl(report['imageKey']);
            } else if (report['imageUrl'] != null && 
                     report['imageUrl'].toString().isNotEmpty &&
                     !report['imageUrl'].toString().startsWith('http')) {
              report['imageUrl'] = getS3ImageUrl(report['imageUrl']);
            }
            return report;
          }).toList();
          
          setState(() {
            labReports = processedData;
            currentReportIndex = 0;
            selectedReport = processedData[0];
            isLoading = false;
            error = null;
          });
        } else {
          setState(() {
            labReports = [];
            selectedReport = null;
            currentReportIndex = null;
            isLoading = false;
            error = "No lab reports found";
          });
        }
      } else {
        setState(() {
          // error = response.data['message'] ?? "Failed to fetch reports";
          // isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        // error = "Error loading reports: ${e.toString()}";
        // isLoading = false;
      });
    }
  }

  // Date Picker
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

  // Helper to format date from API
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

  // Get status color
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
      default:
        return Colors.grey;
    }
  }

  // Navigation for multiple reports
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

  // Check if result is abnormal
  bool _isResultAbnormal(String? result, String? referenceRange) {
    if (result == null || referenceRange == null) return false;
    
    double? resultValue = double.tryParse(result);
    if (resultValue == null) return false;
    
    String cleanRange = referenceRange.replaceAll(' ', '');
    if (cleanRange.contains('-')) {
      final parts = cleanRange.split('-');
      if (parts.length == 2) {
        double? minVal = double.tryParse(parts[0]);
        double? maxVal = double.tryParse(parts[1]);
        if (minVal != null && maxVal != null) {
          return resultValue < minVal || resultValue > maxVal;
        }
      }
    }
    return false;
  }

  // Build test results table from backend data
  Widget _buildTestResultsTable(double screenWidth) {
    if (selectedReport == null) return const SizedBox.shrink();
    
    final testResults = selectedReport['testResults'];
    
    if (testResults == null || (testResults as List).isEmpty) {
      return Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Center(
          child: Text(
            "No test results available",
            style: TextStyle(
              color: Colors.grey,
              fontSize: screenWidth * 0.035,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(screenWidth * 0.0075),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.025),
        border: Border.all(
          color: Colors.black,
          width: screenWidth * 0.0025,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          columnWidths: {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(1),
          },
          border: TableBorder(
            horizontalInside: BorderSide(
              color: Colors.grey,
              width: screenWidth * 0.0025,
            ),
          ),
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: Colors.black),
              children: [
                _buildCell("Investigation", isHeader: true, screenWidth: screenWidth),
                _buildCell("Result", isHeader: true, screenWidth: screenWidth),
                _buildCell("Reference Range", isHeader: true, screenWidth: screenWidth),
                _buildCell("Unit", isHeader: true, screenWidth: screenWidth),
              ],
            ),
            // Data Rows
            ...testResults.map<TableRow>((result) {
              bool isAbnormal = _isResultAbnormal(
                result['result']?.toString(),
                result['referenceRange']?.toString(),
              );
              
              return TableRow(
                children: [
                  _buildCell(result['name']?.toString() ?? 'N/A', screenWidth: screenWidth),
                  _buildCell(result['result']?.toString() ?? 'N/A', isHigh: isAbnormal, screenWidth: screenWidth),
                  _buildCell(result['referenceRange']?.toString() ?? 'N/A', screenWidth: screenWidth),
                  _buildCell(result['unit']?.toString() ?? 'N/A', screenWidth: screenWidth),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, {bool isHeader = false, bool isHigh = false, required double screenWidth}) {
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.025),
      child: Text(
        text,
        style: TextStyle(
          color: isHeader
              ? Colors.white
              : isHigh
              ? Colors.red
              : Colors.black87,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: screenWidth * 0.035,
        ),
      ),
    );
  }

  // Helper widget for detail rows
  Widget _buildDetailRow(String label, String value, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.035,
            ),
          ),
          SizedBox(width: 5),
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

  // Helper widget for patient info
  Widget _buildPatientInfo(String label, String value, double screenWidth) {
    return Expanded(
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

  // Build report image with S3 support
  Widget _buildReportImage(double screenWidth, double screenHeight) {
    final imageUrl = selectedReport?['imageUrl'];
    final imageKey = selectedReport?['imageKey'];
    
    // Check if we have any image data
    final hasImage = (imageUrl != null && imageUrl.toString().isNotEmpty) ||
                     (imageKey != null && imageKey.toString().isNotEmpty);
    
    if (!hasImage) {
      return Container(
        height: screenHeight * 0.12,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                color: Colors.grey.shade400,
                size: 40,
              ),
              SizedBox(height: 8),
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

    final displayUrl = imageUrl ?? getS3ImageUrl(imageKey);
    
    if (displayUrl == null) {
      return Container(
        height: screenHeight * 0.12,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            "Invalid image URL",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: screenWidth * 0.03,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        _showFullScreenImage(context, displayUrl);
      },
      child: Container(
        height: screenHeight * 0.15,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: displayUrl,
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
                          size: 40,
                        ),
                        SizedBox(height: 8),
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
              // Overlay hint
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.zoom_in,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Tap to zoom",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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

  // Full screen image viewer
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.all(8),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
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
                            size: 60,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Failed to load image",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
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
                top: 16,
                right: 16,
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Pinch to zoom • Drag to pan",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Lab Details",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05,
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
            size: screenWidth * 0.055,
          ),
        ),
        // actions: [
        //   IconButton(
        //     onPressed: _fetchLabReports,
        //     icon: Icon(
        //       Icons.refresh,
        //       color: Colors.white,
        //     ),
        //   ),
        // ],
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.02),
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.green,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Loading reports...",
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
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
                          size: 60,
                        ),
                        SizedBox(height: 10),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child:
                          Text("LabReport Not Found", textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),)
                          //  Text(
                          //  // error!,
                          //   textAlign: TextAlign.center,
                          //   style: TextStyle(
                          //     color: Colors.red,
                          //     fontSize: 16,
                          //   ),
                          // ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _fetchLabReports,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: Text("Retry"),
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
                              size: 80,
                            ),
                            SizedBox(height: 10),
                            Text(
                              "No lab reports found",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (selectedDate != null)
                              Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text(
                                  "No reports for ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  selectedDate = null;
                                });
                                _fetchLabReports();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: Text("Clear Filter"),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Filter UI
                            // Container(
                            //   padding: EdgeInsets.symmetric(
                            //     horizontal: screenWidth * 0.03,
                            //     vertical: screenHeight * 0.0125,
                            //   ),
                            //   decoration: BoxDecoration(
                            //     borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            //     border: Border.all(color: Colors.grey, width: screenWidth * 0.0025),
                            //   ),
                            //   child: Row(
                            //     children: [
                            //       Icon(
                            //         Icons.calendar_today,
                            //         color: Colors.green,
                            //         size: screenWidth * 0.05,
                            //       ),
                            //       SizedBox(width: screenWidth * 0.025),
                            //       Expanded(
                            //         child: Text(
                            //           selectedDate == null
                            //               ? "All reports"
                            //               : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                            //           style: TextStyle(
                            //             fontSize: screenWidth * 0.035,
                            //             color: selectedDate == null
                            //                 ? Colors.grey
                            //                 : Colors.black87,
                            //             fontWeight: FontWeight.w500,
                            //           ),
                            //         ),
                            //       ),
                            //       if (selectedDate != null)
                            //         GestureDetector(
                            //           onTap: () {
                            //             setState(() {
                            //               selectedDate = null;
                            //             });
                            //             _fetchLabReports();
                            //           },
                            //           child: Icon(
                            //             Icons.close,
                            //             size: screenWidth * 0.045,
                            //             color: Colors.grey,
                            //           ),
                            //         ),
                            //       SizedBox(width: screenWidth * 0.02),
                            //       ElevatedButton(
                            //         style: ElevatedButton.styleFrom(
                            //           backgroundColor: Colors.green,
                            //           padding: EdgeInsets.symmetric(
                            //             horizontal: screenWidth * 0.03,
                            //             vertical: screenHeight * 0.01,
                            //           ),
                            //           shape: RoundedRectangleBorder(
                            //             borderRadius: BorderRadius.circular(screenWidth * 0.02),
                            //           ),
                            //         ),
                            //         onPressed: pickDate,
                            //         child: Text(
                            //           "Filter",
                            //           style: TextStyle(
                            //             fontSize: screenWidth * 0.0325,
                            //             color: Colors.white,
                            //           ),
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                            GestureDetector(
  onTap: pickDate, // Calendar icon click cheyumbo filter date select cheyyam
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
),
                            // Report counter and navigation
                            if (labReports.length > 1) ...[
                              SizedBox(height: screenHeight * 0.0125),
                              Container(
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
                              ),
                            ],

                            SizedBox(height: screenHeight * 0.0125),
                            Divider(
                              color: Colors.grey,
                              thickness: screenWidth * 0.0025,
                            ),
                            SizedBox(height: screenHeight * 0.0125),

                            // Show report if available
                            if (selectedReport != null) ...[
                              // Report header with hospital info
                              if (selectedReport['hospital']?['name'] != null) ...[
                                Center(
                                  child: Text(
                                    selectedReport['hospital']['name'],
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: screenWidth * 0.055,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              if (selectedReport['hospital']?['address'] != null) ...[
                                Center(
                                  child: Text(
                                    selectedReport['hospital']['address'],
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: screenWidth * 0.035,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                              if (selectedReport['hospital']?['name'] != null || 
                                  selectedReport['hospital']?['address'] != null) ...[
                                Divider(
                                  indent: screenWidth * 0.075,
                                  endIndent: screenWidth * 0.075,
                                  color: Colors.grey,
                                  thickness: screenWidth * 0.0025,
                                ),
                                SizedBox(height: screenHeight * 0.0125),
                              ],
                              
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

                              // Report details - Fixed overflow
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (selectedReport['doctor'] != null || selectedReport['doctorId'] != null)
                                          _buildDetailRow(
                                            "Doctor:", 
                                            selectedReport['doctor'] != null 
                                                ? "Dr. ${selectedReport['doctor']['name'] ?? ''}" 
                                                : selectedReport['doctorId'] != null
                                                    ? "Dr. ${selectedReport['doctorId']}"
                                                    : '',
                                            screenWidth
                                          ),
                                        if (selectedReport['department'] != null)
                                          _buildDetailRow(
                                            "Department:", 
                                            selectedReport['department'].toUpperCase(),
                                            screenWidth
                                          ),
                                        if (selectedReport['testName'] != null)
                                          _buildDetailRow(
                                            "Test Name:", 
                                            selectedReport['testName'],
                                            screenWidth
                                          ),
                                        _buildDetailRow(
                                          "Report ID:", 
                                          "#${selectedReport['id'] ?? ''}",
                                          screenWidth
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        _buildDetailRow(
                                          "Collected on:", 
                                          _formatDate(selectedReport['createdAt']),
                                          screenWidth
                                        ),
                                        _buildDetailRow(
                                          "Reported on:", 
                                          _formatDate(selectedReport['updatedAt']),
                                          screenWidth
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
                                            SizedBox(width: 5),
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
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                selectedReport['status']?.toUpperCase() ?? '',
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
                              ),

                              SizedBox(height: screenHeight * 0.01875),

                              // Patient Information - Fixed overflow
                              if (selectedReport['patient'] != null || selectedReport['patientId'] != null) ...[
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
                                        SizedBox(height: 4),
                                        Wrap(
                                          spacing: 10,
                                          runSpacing: 4,
                                          children: [
                                            if (selectedReport['patient']?['name'] != null &&
                                                selectedReport['patient']['name'].toString().isNotEmpty)
                                              _buildPatientInfoWrap(
                                                "Patient Name:", 
                                                selectedReport['patient']['name'],
                                                screenWidth
                                              ),
                                            if (selectedReport['patientId'] != null &&
                                                selectedReport['patientId'].toString().isNotEmpty)
                                              _buildPatientInfoWrap(
                                                "Patient ID:", 
                                                "PT${selectedReport['patientId'].toString().padLeft(3, '0')}",
                                                screenWidth
                                              ),
                                            if (selectedReport['patient']?['age'] != null)
                                              _buildPatientInfoWrap(
                                                "Age/Gender:", 
                                                "${selectedReport['patient']['age']}${selectedReport['patient']['gender'] != null ? ' / ${selectedReport['patient']['gender']}' : ''}",
                                                screenWidth
                                              ),
                                            if (selectedReport['patient']?['bloodGroup'] != null &&
                                                selectedReport['patient']['bloodGroup'].toString().isNotEmpty)
                                              _buildPatientInfoWrap(
                                                "Blood Group:", 
                                                selectedReport['patient']['bloodGroup'],
                                                screenWidth
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.0125),
                              ],

                              // Test Results
                              Padding(
                                padding: EdgeInsets.only(left: screenWidth * 0.0125),
                                child: Text(
                                  "Test Results",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.04,
                                  ),
                                ),
                              ),
                              _buildTestResultsTable(screenWidth),
                              SizedBox(height: screenHeight * 0.0125),

                              // Report image with S3 support
                              Padding(
                                padding: EdgeInsets.only(left: screenWidth * 0.0125),
                                child: Text(
                                  "Report Attachment",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.04,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.0075),
                              _buildReportImage(screenWidth, screenHeight),
                            ],
                            
                            SizedBox(height: screenHeight * 0.02),
                            
                            // // Download button
                            // if (selectedReport != null) ...[
                            //   ElevatedButton(
                            //     style: ElevatedButton.styleFrom(
                            //       backgroundColor: Colors.green,
                            //       shape: RoundedRectangleBorder(
                            //         borderRadius: BorderRadius.circular(screenWidth * 0.025),
                            //       ),
                            //       padding: EdgeInsets.symmetric(
                            //         horizontal: screenWidth * 0.08,
                            //         vertical: screenHeight * 0.0125,
                            //       ),
                            //       minimumSize: Size(double.infinity, screenHeight * 0.06),
                            //     ),
                            //     onPressed: () {
                            //       ScaffoldMessenger.of(context).showSnackBar(
                            //         SnackBar(
                            //           content: Text("Download functionality coming soon"),
                            //           backgroundColor: Colors.blue,
                            //         ),
                            //       );
                            //     },
                            //     child: Row(
                            //       mainAxisAlignment: MainAxisAlignment.center,
                            //       children: [
                            //         Text(
                            //           "Download Report",
                            //           style: TextStyle(
                            //             color: Colors.white,
                            //             fontSize: screenWidth * 0.04,
                            //             fontWeight: FontWeight.w500,
                            //           ),
                            //         ),
                            //         SizedBox(width: screenWidth * 0.02),
                            //         Icon(
                            //           Icons.download,
                            //           color: Colors.white,
                            //           size: screenWidth * 0.05,
                            //         ),
                            //       ],
                            //     ),
                            //   ),
                            // ],
                          ],
                        ),
                      ),
        ),
    );
  }

  // New helper widget for patient info with Wrap
  Widget _buildPatientInfoWrap(String label, String value, double screenWidth) {
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
}