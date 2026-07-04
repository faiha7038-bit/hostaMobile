import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../services/api_service.dart';
import '../../../data/models/prescription_model.dart';

class PrescriptionListScreen extends StatefulWidget {
  final String? userId;

  const PrescriptionListScreen({
    Key? key,
    this.userId,
  }) : super(key: key);

  @override
  State<PrescriptionListScreen> createState() => _PrescriptionListScreenState();
}

class _PrescriptionListScreenState extends State<PrescriptionListScreen> {
  late ApiService _apiService;
  PrescriptionResponse? _response;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  final int _limit = 10;
  
  // Date filter variables
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  bool _isFiltering = false;
  
  // Search variable
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _apiService.init();
    _loadPrescriptions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrescriptions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getPrescriptions(
        userId: widget.userId,
        page: _currentPage,
        limit: _limit,
      );

      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadPrescriptions();
  }

  // Get filtered prescriptions based on date range and search query
  List<Prescription> _getFilteredPrescriptions() {
    if (_response == null) return [];
    
    List<Prescription> filtered = _response!.data;
    
    // Apply date filter
    if (_selectedStartDate != null || _selectedEndDate != null) {
      filtered = filtered.where((prescription) {
        final prescriptionDate = DateTime.parse(prescription.createdAt);
        
        bool matchesStart = true;
        bool matchesEnd = true;
        
        if (_selectedStartDate != null) {
          final startDate = DateTime(_selectedStartDate!.year, _selectedStartDate!.month, _selectedStartDate!.day);
          final pDate = DateTime(prescriptionDate.year, prescriptionDate.month, prescriptionDate.day);
          matchesStart = pDate.isAtSameMomentAs(startDate) || pDate.isAfter(startDate);
        }
        
        if (_selectedEndDate != null) {
          final endDate = DateTime(_selectedEndDate!.year, _selectedEndDate!.month, _selectedEndDate!.day);
          final pDate = DateTime(prescriptionDate.year, prescriptionDate.month, prescriptionDate.day);
          matchesEnd = pDate.isAtSameMomentAs(endDate) || pDate.isBefore(endDate);
        }
        
        return matchesStart && matchesEnd;
      }).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((prescription) {
        final query = _searchQuery.toLowerCase();
        return (prescription.patientName?.toLowerCase().contains(query) ?? false) ||
               (prescription.hospitalName?.toLowerCase().contains(query) ?? false) ||
               (prescription.prescribedBy?.toLowerCase().contains(query) ?? false) ||
               (prescription.patientId.toString().contains(query)) ||
               (prescription.complaint.toLowerCase().contains(query));
      }).toList();
    }
    
    return filtered;
  }

  // Clear date filters
  void _clearDateFilter() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
      _isFiltering = false;
    });
  }

  // Show date picker dialog
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTime? pickedStart = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedStart != null) {
      final DateTime? pickedEnd = await showDatePicker(
        context: context,
        initialDate: _selectedEndDate ?? pickedStart,
        firstDate: pickedStart,
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.green,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedEnd != null) {
        setState(() {
          _selectedStartDate = pickedStart;
          _selectedEndDate = pickedEnd;
          _isFiltering = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'My Prescriptions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          size: screenWidth * 0.055
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ============================================
          // SEARCH BAR WITH CALENDAR ICON
          // ============================================
          _buildSearchBar(screenWidth, screenHeight, isTablet),
          
          // ============================================
          // MAIN CONTENT
          // ============================================
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Colors.green,
                      strokeWidth: screenWidth * 0.015,
                    ),
                  )
                : _errorMessage != null
                    ? _buildErrorWidget(screenWidth, screenHeight)
                    : _buildContent(screenWidth, screenHeight, isTablet),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SEARCH BAR WITH CALENDAR ICON
  // ============================================
  Widget _buildSearchBar(double screenWidth, double screenHeight, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.012,
      ),
      color: Colors.white,
      child: Row(
        children: [
          // Search Bar with Calendar Icon
          Expanded(
            child: Container(
              height: isTablet ? screenHeight * 0.065 : screenHeight * 0.055,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isFiltering ? Colors.green : const Color(0xFFE2E8F0),
                  width: _isFiltering ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: _isFiltering 
                      ? 'Search filtered results...' 
                      : 'Search prescriptions...',
                  hintStyle: TextStyle(
                    fontSize: isTablet ? screenWidth * 0.018 : screenWidth * 0.032,
                    color: const Color(0xFFA0AEC0),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: _isFiltering ? Colors.green : const Color(0xFFA0AEC0),
                    size: isTablet ? screenWidth * 0.025 : screenWidth * 0.045,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Calendar Icon - Large Green
                      Container(
                        margin: EdgeInsets.only(right: screenWidth * 0.01),
                        child: IconButton(
                          icon: Icon(
                            Icons.calendar_month,
                            color: Colors.green,
                            size: isTablet ? screenWidth * 0.035 : screenWidth * 0.055,
                          ),
                          onPressed: () => _selectDateRange(context),
                          padding: EdgeInsets.all(isTablet ? screenWidth * 0.01 : screenWidth * 0.015),
                          constraints: BoxConstraints(
                            minWidth: isTablet ? screenWidth * 0.055 : screenWidth * 0.09,
                            minHeight: isTablet ? screenWidth * 0.055 : screenWidth * 0.09,
                          ),
                        ),
                      ),
                      // Clear Button (if search has text)
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: const Color(0xFFA0AEC0),
                            size: isTablet ? screenWidth * 0.02 : screenWidth * 0.04,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: isTablet ? screenWidth * 0.035 : screenWidth * 0.06,
                          ),
                        ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.025,
                    vertical: screenHeight * 0.005,
                  ),
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: isTablet ? screenWidth * 0.02 : screenWidth * 0.035,
                  color: const Color(0xFF1A202C),
                ),
              ),
            ),
          ),
          
          // Filter Status Badge
          if (_isFiltering || _searchQuery.isNotEmpty) ...[
            SizedBox(width: screenWidth * 0.02),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.02,
                vertical: screenHeight * 0.005,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_getFilteredPrescriptions().length}',
                    style: TextStyle(
                      fontSize: isTablet ? screenWidth * 0.015 : screenWidth * 0.025,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                  ),
                  if (_isFiltering) ...[
                    SizedBox(width: screenWidth * 0.01),
                    Icon(
                      Icons.calendar_month,
                      color: Colors.green,
                      size: isTablet ? screenWidth * 0.015 : screenWidth * 0.025,
                    ),
                  ],
                  if (_searchQuery.isNotEmpty) ...[
                    SizedBox(width: screenWidth * 0.01),
                    Icon(
                      Icons.search,
                      color: Colors.green,
                      size: isTablet ? screenWidth * 0.015 : screenWidth * 0.025,
                    ),
                  ],
                  if (_isFiltering)
                    GestureDetector(
                      onTap: _clearDateFilter,
                      child: Padding(
                        padding: EdgeInsets.only(left: screenWidth * 0.01),
                        child: Icon(
                          Icons.close,
                          color: Colors.green,
                          size: isTablet ? screenWidth * 0.015 : screenWidth * 0.025,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget(double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: screenWidth * 0.15,
            color: Colors.red.shade300,
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            'Error Loading Prescriptions',
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A202C),
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          //   child: Text(
          //     _errorMessage!,
          //     textAlign: TextAlign.center,
          //     style: TextStyle(
          //       color: Colors.grey.shade600,
          //       fontSize: screenWidth * 0.035,
          //     ),
          //   ),
          // ),
          SizedBox(height: screenHeight * 0.03),
          ElevatedButton(
            onPressed: _loadPrescriptions,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.08,
                vertical: screenHeight * 0.015,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Retry',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    double screenWidth,
    double screenHeight,
    bool isTablet,
  ) {
    final filteredData = _getFilteredPrescriptions();
    
    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              (_isFiltering || _searchQuery.isNotEmpty) ? Icons.filter_alt_off : Icons.medication_outlined,
              size: screenWidth * 0.15,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              (_isFiltering || _searchQuery.isNotEmpty) 
                  ? 'No prescriptions found matching your search' 
                  : 'No Prescriptions Found',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            if (!_isFiltering && _searchQuery.isEmpty) ...[
              SizedBox(height: screenHeight * 0.01),
              Text(
                'Pull down to refresh',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ],
            if (_isFiltering || _searchQuery.isNotEmpty) ...[
              SizedBox(height: screenHeight * 0.02),
              TextButton(
                onPressed: () {
                  setState(() {
                    _clearDateFilter();
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                child: Text(
                  'Clear All Filters',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      color: Colors.green,
      child: ListView.builder(
        padding: EdgeInsets.all(screenWidth * 0.04),
        itemCount: filteredData.length,
        itemBuilder: (context, index) {
          final prescription = filteredData[index];
          return Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.02),
            child: _buildPrescriptionCard(
              prescription,
              screenWidth,
              screenHeight,
              isTablet,
            ),
          );
        },
      ),
    );
  }

  // ============================================
  // PRESCRIPTION CARD - RESPONSIVE
  // ============================================
  Widget _buildPrescriptionCard(
    Prescription p,
    double screenWidth,
    double screenHeight,
    bool isTablet,
  ) {
    final bgColor = p.canvasBg != null && p.canvasBg != 'white'
        ? _parseColor(p.canvasBg!)
        : Colors.white;

    final cardPadding = isTablet
        ? EdgeInsets.all(screenWidth * 0.03)
        : EdgeInsets.all(screenWidth * 0.04);

    return Card(
      elevation: isTablet ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
      ),
      color: bgColor,
      child: Padding(
        padding: cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========================================
            // 1. HEADER: Hospital + Doctor
            // ========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isTablet ? 3 : 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (p.hospitalName != null && p.hospitalName!.isNotEmpty)
                        Text(
                          p.hospitalName!,
                          style: TextStyle(
                            fontSize: isTablet ? screenWidth * 0.025 : screenWidth * 0.045,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A202C),
                          ),
                        ),
                      SizedBox(height: screenHeight * 0.005),
                      if (p.prescribedBy != null && p.prescribedBy!.isNotEmpty)
                        Text(
                          p.prescribedBy!,
                          style: TextStyle(
                            fontSize: isTablet ? screenWidth * 0.02 : screenWidth * 0.038,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                      if (p.prescribedBy != null && p.prescribedBy!.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(top: screenHeight * 0.005),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.025,
                            vertical: screenHeight * 0.005,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF8FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'ONCOLOGY',
                            style: TextStyle(
                              fontSize: isTablet ? screenWidth * 0.015 : screenWidth * 0.025,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2B6CB0),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ID: ${p.id}',
                      style: TextStyle(
                        fontSize: isTablet ? screenWidth * 0.018 : screenWidth * 0.028,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4A5568),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      _formatDate(DateTime.parse(p.createdAt)),
                      style: TextStyle(
                        fontSize: isTablet ? screenWidth * 0.018 : screenWidth * 0.028,
                        color: const Color(0xFF718096),
                      ),
                    ),
                    if (p.nextConsultation != null) ...[
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        'Next: ${_formatDate(DateTime.parse(p.nextConsultation!))}',
                        style: TextStyle(
                          fontSize: isTablet ? screenWidth * 0.018 : screenWidth * 0.028,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2B6CB0),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),

            Divider(
              height: screenHeight * 0.025,
              color: const Color(0xFFE2E8F0),
            ),

            // ========================================
            // 2. PATIENT INFORMATION - FIXED
            // ========================================
            if (p.patientId > 0) ...[
              Text(
                'Patient Information',
                style: TextStyle(
                  fontSize: isTablet ? screenWidth * 0.02 : screenWidth * 0.035,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A202C),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PATIENT NAME',
                          style: TextStyle(
                            fontSize: isTablet ? screenWidth * 0.015 : screenWidth * 0.025,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF718096),
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          p.patientName ?? 'Patient #${p.patientId}',
                          style: TextStyle(
                            fontSize: isTablet ? screenWidth * 0.02 : screenWidth * 0.035,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1A202C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PATIENT ID',
                          style: TextStyle(
                            fontSize: isTablet ? screenWidth * 0.015 : screenWidth * 0.025,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF718096),
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          p.patientId.toString(),
                          style: TextStyle(
                            fontSize: isTablet ? screenWidth * 0.02 : screenWidth * 0.035,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1A202C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.01),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AGE / GENDER',
                          style: TextStyle(
                            fontSize: isTablet ? screenWidth * 0.015 : screenWidth * 0.025,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF718096),
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          p.patientAge != null && p.patientGender != null
                              ? '${p.patientAge}  / ${p.patientGender}'
                              : p.patientAge != null 
                              ? '${p.patientAge} yrs' 
                              : p.patientGender ?? 'N/A', 
                          style: TextStyle(
                            fontSize: isTablet ? screenWidth * 0.02 : screenWidth * 0.035,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1A202C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONTACT',
                          style: TextStyle(
                            fontSize: isTablet ? screenWidth * 0.015 : screenWidth * 0.025,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF718096),
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          p.patientPhone ?? 'N/A',
                          style: TextStyle(
                            fontSize: isTablet ? screenWidth * 0.02 : screenWidth * 0.035,
                            fontWeight: FontWeight.w500,
                            color: p.patientPhone != null
                            ? const Color(0xFF1A202C)
                            : const Color(0xFF1A202C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(
                height: screenHeight * 0.025,
                color: const Color(0xFFE2E8F0),
              ),
            ],

            // ========================================
            // 3. CHIEF COMPLAINT
            // ========================================
            if (p.complaint.isNotEmpty) ...[
              Text(
                'Chief Complaint',
                style: TextStyle(
                  fontSize: isTablet ? screenWidth * 0.02 : screenWidth * 0.035,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A202C),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth * 0.03),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  p.complaint,
                  style: TextStyle(
                    fontSize: isTablet ? screenWidth * 0.02 : screenWidth * 0.035,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ),
              Divider(
                height: screenHeight * 0.025,
                color: const Color(0xFFE2E8F0),
              ),
            ],

            // ========================================
            // 4. MEDICATIONS - IMPROVED
            // ========================================
               
if (p.medications.isNotEmpty) ...[
  const Text(
    'Medications',
    style: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A202C),
    ),
  ),
  const SizedBox(height: 10),
  Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: const Color(0xFFF7FAFC),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFEDF2F7),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 100,
                  child: Text(
                    'Medicine',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 12),
                SizedBox(
                  width: 65,
                  child: Text(
                    'Dosage',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 12),
                SizedBox(
                  width: 65,
                  child: Text(
                    'Duration',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 12),
                SizedBox(
                  width: 85,
                  child: Text(
                    'Frequency',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 12),
                SizedBox(
                  width: 85,
                  child: Text(
                    'Timing',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: 12),
                SizedBox(
                  width: 85,
                  child: Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          // Data Rows
          ...p.medications.map((med) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFE2E8F0),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      med.medicineName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A202C),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 65,
                    child: Text(
                      med.dosage,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1A202C),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 65,
                    child: Text(
                      med.duration,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1A202C),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 85,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF8FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        med.frequency,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2B6CB0),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 85,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FFF4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        med.timing,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF276749),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 85,
                    child: Text(
                      med.instructions.isNotEmpty
                          ? med.instructions
                          : '  ',
                      style: const TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF718096),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    ),
  ),
  const Divider(height: 20, color: Color(0xFFE2E8F0)),
],

        
            // ========================================
            // 5. DOCTOR NOTES
            // ========================================
            if (p.advice.isNotEmpty) ...[
              Text(
                'Doctor Notes & Instructions',
                style: TextStyle(
                  fontSize: isTablet ? screenWidth * 0.02 : screenWidth * 0.035,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A202C),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth * 0.03),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  p.advice,
                  style: TextStyle(
                    fontSize: isTablet ? screenWidth * 0.02 : screenWidth * 0.035,
                    color: const Color(0xFF2D3748),
                  ),
                ),
              ),
              Divider(
                height: screenHeight * 0.025,
                color: const Color(0xFFE2E8F0),
              ),
            ],

            // ========================================
            // 6. SIGNATURE
            // ========================================
            if (p.prescribedBy != null && p.prescribedBy!.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.prescribedBy!,
                        style: TextStyle(
                          fontSize: isTablet ? screenWidth * 0.025 : screenWidth * 0.04,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A202C),
                        ),
                      ),
                      Text(
                        'ONCOLOGY',
                        style: TextStyle(
                          fontSize: isTablet ? screenWidth * 0.015 : screenWidth * 0.03,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF718096),
                        ),
                      ),
                    ],
                  ),
                  if (p.hospitalName != null && p.hospitalName!.isNotEmpty)
                    Text(
                      p.hospitalName!,
                      style: TextStyle(
                        fontSize: isTablet ? screenWidth * 0.015 : screenWidth * 0.025,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFA0AEC0),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================
  // DETAIL CHIP HELPER - FIXED
  // ============================================
  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required String value,
    required double screenWidth,
    required double screenHeight,
    required bool isTablet,
    Color color = const Color(0xFF4A5568),
    Color bgColor = const Color(0xFFF7FAFC),
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: screenHeight * 0.005,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isTablet ? screenWidth * 0.015 : screenWidth * 0.03,
            color: color,
          ),
          SizedBox(width: screenWidth * 0.01),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? screenWidth * 0.01 : screenWidth * 0.018,
                  color: const Color(0xFF718096),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: isTablet ? screenWidth * 0.015 : screenWidth * 0.025,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // PARSE COLOR FROM API
  // ============================================
  Color _parseColor(String colorString) {
    if (colorString == 'white') return Colors.white;
    if (colorString == 'transparent') return Colors.transparent;
    try {
      return Color(
        int.parse('FF${colorString.replaceAll('#', '')}', radix: 16),
      );
    } catch (e) {
      return Colors.white;
    }
  }

  // ============================================
  // HELPER
  // ============================================
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}