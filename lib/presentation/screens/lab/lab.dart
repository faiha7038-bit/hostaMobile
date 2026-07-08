import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hosta/providers/lab_provider.dart';

class LabReport extends ConsumerStatefulWidget {
  const LabReport({super.key});

  @override
  ConsumerState<LabReport> createState() => _LabReportState();
}

class _LabReportState extends ConsumerState<LabReport> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(labProvider.notifier).init();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(labProvider.notifier).setSearchQuery(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final labState = ref.watch(labProvider);
    final labNotifier = ref.read(labProvider.notifier);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
    final isLargeScreen = screenWidth >= 1024;

    final displayReports = labState.filteredReports;

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
      ),
      body: Column(
        children: [
          _buildSearchBar(screenWidth, screenHeight, isSmallScreen, labState, labNotifier),
          
          if (labState.selectedPatientName != null || 
              labState.searchQuery.isNotEmpty || 
              labState.selectedDate != null)
            _buildActiveFilters(screenWidth, screenHeight, isSmallScreen, labState, labNotifier),
          
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: screenWidth * 0.04,
                right: screenWidth * 0.04,
                top: screenHeight * 0.01,
                bottom: screenHeight * 0.02,
              ),
              child: labState.isLoading
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
                  : labState.error != null
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
                                  labState.error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: isSmallScreen ? 16 : 18,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.025),
                              ElevatedButton(
                                onPressed: () {
                                  labNotifier.refresh();
                                },
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
                      : displayReports.isEmpty
                          ? _buildEmptyState(screenWidth, screenHeight, isSmallScreen, labState, labNotifier)
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (displayReports.length != labState.labReports.length)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: screenHeight * 0.01),
                                      child: Text(
                                        "Showing ${displayReports.length} of ${labState.labReports.length} reports",
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: screenWidth * 0.03,
                                        ),
                                      ),
                                    ),
                                  isLargeScreen
                                      ? _buildLargeScreenLayout(
                                          screenWidth, screenHeight, labState, labNotifier, displayReports)
                                      : _buildSmallMediumScreenLayout(
                                          screenWidth, screenHeight, labState, labNotifier, displayReports),
                                ],
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    double screenWidth,
    double screenHeight,
    bool isSmallScreen,
    LabState labState,
    LabNotifier labNotifier,
  ) {
    return Center(
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
            labState.searchQuery.isNotEmpty || labState.selectedPatientName != null
                ? "No matching reports found"
                : labState.selectedDate != null
                    ? "No reports for ${labState.selectedDate!.day}/${labState.selectedDate!.month}/${labState.selectedDate!.year}"
                    : "No lab reports found",
            style: TextStyle(
              color: Colors.grey,
              fontSize: isSmallScreen ? 18 : 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (labState.searchQuery.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.0125),
              child: Text(
                "No results for \"${labState.searchQuery}\"",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ),
          SizedBox(height: screenHeight * 0.025),
          Wrap(
            spacing: screenWidth * 0.02,
            runSpacing: screenHeight * 0.01,
            alignment: WrapAlignment.center,
            children: [
              if (labState.searchQuery.isNotEmpty || labState.selectedPatientName != null)
                ElevatedButton(
                  onPressed: () {
                    labNotifier.clearAllFilters();
                    _searchController.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.015,
                    ),
                  ),
                  child: Text(
                    "Clear Filters",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ),
              if (labState.selectedDate != null)
                ElevatedButton(
                  onPressed: () {
                    labNotifier.clearDateFilter();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: screenHeight * 0.015,
                    ),
                  ),
                  child: Text(
                    "Clear Date Filter",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    double screenWidth,
    double screenHeight,
    bool isSmallScreen,
    LabState labState,
    LabNotifier labNotifier,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.008,
      ),
      color: Colors.green.shade50,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: screenHeight * 0.055,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: screenWidth * 0.02),
                    child: Icon(
                      Icons.search,
                      color: Colors.green,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'Search reports...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: isSmallScreen ? 13 : 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.015,
                          vertical: 0,
                        ),
                        isDense: true,
                      ),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        height: 1.0,
                      ),
                      onChanged: (value) {
                        labNotifier.setSearchQuery(value);
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        labNotifier.clearSearch();
                        setState(() {});
                      },
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      iconSize: isSmallScreen ? 18 : 22,
                    ),
                  Container(
                    height: screenHeight * 0.035,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),
                  GestureDetector(
                    onTap: () {
                      if (labState.selectedDate != null) {
                        labNotifier.clearDateFilter();
                        setState(() {});
                      } else {
                        showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        ).then((picked) {
                          if (picked != null) {
                            labNotifier.setDateFilter(picked);
                            setState(() {});
                          }
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.015,
                        vertical: screenHeight * 0.01,
                      ),
                      child: Icon(
                        Icons.calendar_month,
                        color: labState.selectedDate != null ? Colors.green : Colors.grey,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.01),
                ],
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.015),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'All') {
                labNotifier.setPatientNameFilter(null);
                setState(() {});
              } else {
                labNotifier.setPatientNameFilter(value);
                setState(() {});
              }
            },
            child: Container(
              height: screenHeight * 0.055,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
              ),
              decoration: BoxDecoration(
                color: labState.selectedPatientName != null 
                    ? Colors.green 
                    : Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                border: Border.all(
                  color: labState.selectedPatientName != null 
                      ? Colors.green 
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person,
                    color: labState.selectedPatientName != null 
                        ? Colors.white 
                        : Colors.grey.shade600,
                    size: isSmallScreen ? 22 : 26,
                  ),
                  if (labState.selectedPatientName != null) ...[
                    SizedBox(width: screenWidth * 0.01),
                    Container(
                      constraints: BoxConstraints(maxWidth: screenWidth * 0.15),
                      child: Text(
                        labState.selectedPatientName!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.005),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ],
                ],
              ),
            ),
            tooltip: 'Filter by Patient',
            offset: Offset(0, screenHeight * 0.06),
            itemBuilder: (context) {
              final patientNames = labNotifier.getUniquePatientNames();
              final items = <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'All',
                  child: Row(
                    children: [
                      Icon(Icons.people, color: Colors.green),
                      SizedBox(width: 8),
                      Text('All Patients'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
              ];
              
              if (patientNames.isEmpty) {
                items.add(
                  const PopupMenuItem<String>(
                    value: 'NoPatients',
                    child: Text('No patients available'),
                    enabled: false,
                  ),
                );
              } else {
                for (final name in patientNames) {
                  items.add(
                    PopupMenuItem<String>(
                      value: name,
                      child: Row(
                        children: [
                          Icon(
                            labState.selectedPatientName == name 
                                ? Icons.check_circle 
                                : Icons.person_outline,
                            color: labState.selectedPatientName == name 
                                ? Colors.green 
                                : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: labState.selectedPatientName == name 
                                    ? FontWeight.bold 
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }
              return items;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilters(
    double screenWidth,
    double screenHeight,
    bool isSmallScreen,
    LabState labState,
    LabNotifier labNotifier,
  ) {
    final hasFilters = labState.selectedPatientName != null || 
                    labState.searchQuery.isNotEmpty || 
                    labState.selectedDate != null;
    
    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.005,
      ),
      color: Colors.green.shade100,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              "Active Filters: ",
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            if (labState.selectedPatientName != null)
              _buildFilterChip(
                label: labState.selectedPatientName!,
                icon: Icons.person,
                color: Colors.green,
                onTap: () {
                  labNotifier.setPatientNameFilter(null);
                  setState(() {});
                },
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
            if (labState.searchQuery.isNotEmpty)
              _buildFilterChip(
                label: labState.searchQuery,
                icon: Icons.search,
                color: Colors.blue,
                onTap: () {
                  labNotifier.clearSearch();
                  _searchController.clear();
                  setState(() {});
                },
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
            if (labState.selectedDate != null)
              _buildFilterChip(
                label: "${labState.selectedDate!.day}/${labState.selectedDate!.month}/${labState.selectedDate!.year}",
                icon: Icons.calendar_today,
                color: Colors.orange,
                onTap: () {
                  labNotifier.clearDateFilter();
                  setState(() {});
                },
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double screenWidth,
    required double screenHeight,
  }) {
    final Color darkColor = _getDarkerColor(color);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.015,
        vertical: screenHeight * 0.003,
      ),
      margin: EdgeInsets.only(right: screenWidth * 0.01),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: screenWidth * 0.03,
            color: color,
          ),
          SizedBox(width: screenWidth * 0.008),
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.025,
              color: darkColor,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          SizedBox(width: screenWidth * 0.008),
          InkWell(
            onTap: () {
              onTap();
              setState(() {});
            },
            borderRadius: BorderRadius.circular(screenWidth * 0.05),
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.005),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: screenWidth * 0.025,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDarkerColor(Color color) {
    if (color == Colors.green) return Colors.green.shade700;
    if (color == Colors.blue) return Colors.blue.shade700;
    if (color == Colors.orange) return Colors.orange.shade700;
    if (color == Colors.red) return Colors.red.shade700;
    if (color == Colors.purple) return Colors.purple.shade700;
    if (color == Colors.pink) return Colors.pink.shade700;
    if (color == Colors.teal) return Colors.teal.shade700;
    if (color == Colors.indigo) return Colors.indigo.shade700;
    return color.withOpacity(0.8);
  }

  Widget _buildSmallMediumScreenLayout(
    double screenWidth,
    double screenHeight,
    LabState labState,
    LabNotifier labNotifier,
    List<dynamic> displayReports,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayReports.length > 1) ...[
          _buildReportNavigator(screenWidth, screenHeight, labState, labNotifier, displayReports),
          SizedBox(height: screenHeight * 0.0125),
        ],
        Divider(
          color: Colors.grey,
          thickness: screenWidth * 0.0025,
        ),
        SizedBox(height: screenHeight * 0.0125),

        if (labState.selectedReport != null) ...[
          _buildReportHeader(screenWidth, screenHeight, labState),
          _buildReportDetails(screenWidth, screenHeight, labState),
          _buildPatientInfo(screenWidth, screenHeight, labState),
          _buildReportImage(screenWidth, screenHeight, labState),
        ],
        
        SizedBox(height: screenHeight * 0.02),
      ],
    );
  }

  Widget _buildLargeScreenLayout(
    double screenWidth,
    double screenHeight,
    LabState labState,
    LabNotifier labNotifier,
    List<dynamic> displayReports,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (displayReports.length > 1) ...[
                _buildReportNavigator(screenWidth, screenHeight, labState, labNotifier, displayReports),
              ],
            ],
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          flex: 2,
          child: labState.selectedReport != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReportHeader(screenWidth, screenHeight, labState),
                    _buildReportDetails(screenWidth, screenHeight, labState),
                    _buildPatientInfo(screenWidth, screenHeight, labState),
                    _buildReportImage(screenWidth, screenHeight, labState),
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

  Widget _buildReportNavigator(
    double screenWidth,
    double screenHeight,
    LabState labState,
    LabNotifier labNotifier,
    List<dynamic> displayReports,
  ) {
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
            "Showing: ${displayReports.length} report${displayReports.length > 1 ? 's' : ''}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.035,
              color: Colors.green.shade800,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: labState.currentReportIndex != null && 
                          labState.currentReportIndex! > 0
                    ? labNotifier.previousReport
                    : null,
                icon: Icon(
                  Icons.arrow_back_ios,
                  size: screenWidth * 0.04,
                  color: labState.currentReportIndex != null && 
                          labState.currentReportIndex! > 0
                      ? Colors.green
                      : Colors.grey,
                ),
              ),
              Text(
                "${(labState.currentReportIndex ?? 0) + 1} of ${displayReports.length}",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: screenWidth * 0.035,
                ),
              ),
              IconButton(
                onPressed: labState.currentReportIndex != null && 
                          labState.currentReportIndex! < displayReports.length - 1
                    ? labNotifier.nextReport
                    : null,
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: screenWidth * 0.04,
                  color: labState.currentReportIndex != null && 
                          labState.currentReportIndex! < displayReports.length - 1
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

  Widget _buildReportHeader(
    double screenWidth,
    double screenHeight,
    LabState labState,
  ) {
    final hospitalName = labState.selectedReport?['hospitalName']?.toString() ?? '';
    final hospitalId = labState.selectedReport?['hospitalId']?.toString() ?? '';
    
    String displayTitle = "Lab Report";
    if (hospitalName.isNotEmpty) {
      displayTitle = hospitalName;
    } else if (hospitalId.isNotEmpty) {
      displayTitle = "Hospital #$hospitalId";
    }
    
    return Column(
      children: [
        Center(
          child: Text(
            displayTitle,
            style: TextStyle(
              color: Colors.green,
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        if (labState.selectedReport?['labName']?.toString()?.isNotEmpty == true)
          Center(
            child: Text(
              labState.selectedReport?['labName'].toString() ?? '',
              style: TextStyle(
                color: Colors.blueGrey.shade600,
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        
        SizedBox(height: screenHeight * 0.005),
        
        if (labState.selectedReport?['patientName']?.toString()?.isNotEmpty == true) ...[
          Center(
            child: Text(
              "Patient: ${labState.selectedReport?['patientName']}",
              style: TextStyle(
                color: Colors.blueGrey,
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        
        if (labState.selectedReport?['department']?.toString()?.isNotEmpty == true) ...[
          Center(
            child: Text(
              labState.selectedReport?['department'].toString().toUpperCase() ?? '',
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

  Widget _buildReportDetails(
    double screenWidth,
    double screenHeight,
    LabState labState,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (labState.selectedReport?['department']?.toString()?.isNotEmpty == true)
                _buildDetailRow(
                  "Department:", 
                  labState.selectedReport?['department'].toString().toUpperCase() ?? '',
                  screenWidth,
                  screenHeight
                ),
              if (labState.selectedReport?['testName']?.toString()?.isNotEmpty == true)
                _buildDetailRow(
                  "Test Name:", 
                  labState.selectedReport?['testName'].toString() ?? '',
                  screenWidth,
                  screenHeight
                ),
              _buildDetailRow(
                "Report ID:", 
                "#${labState.selectedReport?['id'] ?? ''}",
                screenWidth,
                screenHeight
              ),
            ],
          ),
        ),
        SizedBox(width: screenWidth * 0.02),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildDetailRow(
                "Collected on:", 
                _formatDate(labState.selectedReport?['createdAt']),
                screenWidth,
                screenHeight
              ),
              _buildDetailRow(
                "Reported on:", 
                _formatDate(labState.selectedReport?['updatedAt']),
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
                  Text(
                    labState.selectedReport?['status']?.toString().toUpperCase() ?? '',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.bold,
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

  Widget _buildPatientInfo(
    double screenWidth,
    double screenHeight,
    LabState labState,
  ) {
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
                    if (labState.selectedReport?['patientId']?.toString()?.isNotEmpty == true)
                      _buildPatientInfoWrap(
                        "Patient ID:", 
                        "PT${labState.selectedReport?['patientId'].toString().padLeft(3, '0')}",
                        screenWidth,
                        screenHeight
                      ),
                    if (labState.selectedReport?['patientName']?.toString()?.isNotEmpty == true)
                      _buildPatientInfoWrap(
                        "Patient Name:", 
                        labState.selectedReport?['patientName'].toString() ?? '',
                        screenWidth,
                        screenHeight
                      ),
                    if (labState.selectedReport?['patientEmail']?.toString()?.isNotEmpty == true)
                      _buildPatientInfoWrap(
                        "Email:", 
                        labState.selectedReport?['patientEmail'].toString() ?? '',
                        screenWidth,
                        screenHeight
                      ),
                    if (labState.selectedReport?['testName']?.toString()?.isNotEmpty == true)
                      _buildPatientInfoWrap(
                        "Test Name:", 
                        labState.selectedReport?['testName'].toString() ?? '',
                        screenWidth,
                        screenHeight
                      ),
                    if (labState.selectedReport?['department']?.toString()?.isNotEmpty == true)
                      _buildPatientInfoWrap(
                        "Department:", 
                        labState.selectedReport?['department'].toString().toUpperCase() ?? '',
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

  Widget _buildReportImage(
    double screenWidth,
    double screenHeight,
    LabState labState,
  ) {
    final imageUrl = labState.selectedReport?['imageUrl'];
    
    final hasImage = (imageUrl != null && imageUrl.toString().isNotEmpty);
    
    if (!hasImage) {
      return Container(
        height: screenHeight * 0.15,
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
        height: screenHeight * 0.35,
        width: double.infinity,
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
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
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
}