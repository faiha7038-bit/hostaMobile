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
  final TextEditingController _searchController = TextEditingController();
  
  // Patient filter variables
  String? _selectedPatientId;
  String? _selectedPatientName;
  bool _isPatientFilterActive = false;

  // Patient search in dialog
  String _patientSearchQuery = '';
  List<Map<String, String>> _filteredPatients = [];

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
    if (!mounted) return;
    
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

      if (!mounted) return;
      
      setState(() {
        _response = response;
        _isLoading = false;
        _updateFilteredPatients();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _updateFilteredPatients() {
    final patients = _getUniquePatients();
    if (_patientSearchQuery.isEmpty) {
      _filteredPatients = patients;
    } else {
      _filteredPatients = patients.where((p) {
        final name = p['name']?.toLowerCase() ?? '';
        final id = p['id']?.toLowerCase() ?? '';
        final query = _patientSearchQuery.toLowerCase();
        return name.contains(query) || id.contains(query);
      }).toList();
    }
  }

  List<Map<String, String>> _getUniquePatients() {
    if (_response == null) return [];
    
    Map<String, Map<String, String>> uniqueMap = {};
    for (var p in _response!.data) {
      String id = p.patientId.toString();
      if (!uniqueMap.containsKey(id)) {
        uniqueMap[id] = {
          'id': id,
          'name': p.patientName ?? 'Patient #${p.patientId}',
        };
      }
    }
    return uniqueMap.values.toList();
  }

  Future<void> _refreshData() async {
    await _loadPrescriptions();
  }

  // ======================== FILTER LOGIC ============================================
  List<Prescription> _getFilteredPrescriptions() {
    if (_response == null) return [];
    
    List<Prescription> filtered = List.from(_response!.data);
    
    // 1. APPLY PATIENT FILTER
    if (_isPatientFilterActive && _selectedPatientId != null && _selectedPatientId!.isNotEmpty) {
      filtered = filtered.where((prescription) {
        return prescription.patientId.toString() == _selectedPatientId;
      }).toList();
    }
    
    // 2. APPLY DATE FILTER
    if (_selectedStartDate != null || _selectedEndDate != null) {
      filtered = filtered.where((prescription) {
        final prescriptionDate = DateTime.parse(prescription.createdAt);
        final pDate = DateTime(prescriptionDate.year, prescriptionDate.month, prescriptionDate.day);
        
        bool matchesStart = true;
        bool matchesEnd = true;
        
        if (_selectedStartDate != null) {
          final startDate = DateTime(
            _selectedStartDate!.year, 
            _selectedStartDate!.month, 
            _selectedStartDate!.day
          );
          matchesStart = pDate.isAtSameMomentAs(startDate) || pDate.isAfter(startDate);
        }
        
        if (_selectedEndDate != null) {
          final endDate = DateTime(
            _selectedEndDate!.year, 
            _selectedEndDate!.month, 
            _selectedEndDate!.day
          );
          matchesEnd = pDate.isAtSameMomentAs(endDate) || pDate.isBefore(endDate);
        }
        
        return matchesStart && matchesEnd;
      }).toList();
    }
    
    // 3. APPLY SEARCH FILTER
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((prescription) {
        final query = _searchQuery.toLowerCase();
        final patientName = prescription.patientName?.toLowerCase() ?? '';
        final hospitalName = prescription.hospitalName?.toLowerCase() ?? '';
        final prescribedBy = prescription.prescribedBy?.toLowerCase() ?? '';
        final patientId = prescription.patientId.toString();
        final complaint = prescription.complaint.toLowerCase();
        
        return patientName.contains(query) ||
               hospitalName.contains(query) ||
               prescribedBy.contains(query) ||
               patientId.contains(query) ||
               complaint.contains(query);
      }).toList();
    }
    
    return filtered;
  }

  // ================================ CLEAR FILTERS ============================================
  void _clearDateFilter() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
      _isFiltering = false;
    });
  }

  void _clearPatientFilter() {
    setState(() {
      _selectedPatientId = null;
      _selectedPatientName = null;
      _isPatientFilterActive = false;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
      _isFiltering = false;
      _selectedPatientId = null;
      _selectedPatientName = null;
      _isPatientFilterActive = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  // =========================== DATE PICKER ============================================
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


  //================================ PATIENT FILTER DIALOG ===================================
  void _showPatientFilterDialog() {
  _updateFilteredPatients();
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      String? tempPatientId;
      String? tempPatientName;
      
      return StatefulBuilder(
        builder: (context, setStateModal) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Content - now wrapped in Expanded
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Filter by Patient',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_isPatientFilterActive)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _clearPatientFilter();
                                      _updateFilteredPatients();
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Clear',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Search TextField
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Search patients...',
                                prefixIcon: const Icon(Icons.search),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onChanged: (value) {
                                setStateModal(() {
                                  _patientSearchQuery = value;
                                  _updateFilteredPatients();
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Patient list - now using Flexible with constraints
                          Expanded(
                            child: _filteredPatients.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Text('No patients found'),
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _filteredPatients.length,
                                      itemBuilder: (context, index) {
                                        final patient = _filteredPatients[index];
                                        final isSelected = tempPatientId == patient['id'];
                                        return Container(
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey[200]!,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: isSelected 
                                                  ? Colors.green 
                                                  : Colors.grey[200],
                                              child: Text(
                                                patient['name']!.substring(0, 1).toUpperCase(),
                                                style: TextStyle(
                                                  color: isSelected ? Colors.white : Colors.grey[700],
                                                ),
                                              ),
                                            ),
                                            title: Text(
                                              patient['name']!,
                                              style: TextStyle(
                                                fontWeight: isSelected 
                                                    ? FontWeight.w600 
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                            subtitle: Text(
                                              'ID: ${patient['id']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            trailing: isSelected
                                                ? const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                  )
                                                : null,
                                            onTap: () {
                                              setStateModal(() {
                                                tempPatientId = patient['id'];
                                                tempPatientName = patient['name'];
                                              });
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: tempPatientId == null
                                      ? null
                                      : () {
                                          Navigator.pop(context);
                                          setState(() {
                                            _selectedPatientId = tempPatientId;
                                            _selectedPatientName = tempPatientName;
                                            _isPatientFilterActive = true;
                                            _patientSearchQuery = '';
                                            _updateFilteredPatients();
                                          });
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    disabledBackgroundColor: Colors.grey[300],
                                  ),
                                  child: const Text('Apply Filter'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  // =======================  BUILD ============================================
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isSmallPhone = screenWidth < 400;

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
            size: screenWidth * 0.055,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isFiltering || _isPatientFilterActive || _searchQuery.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear_all,
                color: Colors.white,
                size: screenWidth * 0.055,
              ),
              onPressed: _clearAllFilters,
              tooltip: 'Clear all filters',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(context, screenWidth, screenHeight, isTablet, isSmallPhone),
          if (_isFiltering || _isPatientFilterActive || _searchQuery.isNotEmpty)
            _buildFilterChips(context, screenWidth, screenHeight),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Colors.green,
                      strokeWidth: screenWidth * 0.015,
                    ),
                  )
                : _errorMessage != null
                    ? _buildErrorWidget(context, screenWidth, screenHeight)
                    : _buildContent(context, screenWidth, screenHeight, isTablet),
          ),
        ],
      ),
    );
  }

  // ============================= FILTER CHIPS ============================================
  Widget _buildFilterChips(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.008,
      ),
      color: Colors.white,
      child: Wrap(
        spacing: screenWidth * 0.02,
        runSpacing: screenHeight * 0.005,
        children: [
          if (_isPatientFilterActive && _selectedPatientName != null)
            Chip(
              label: Text(
                'Patient: $_selectedPatientName',
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                ),
              ),
              backgroundColor: Colors.green.withOpacity(0.1),
              deleteIcon: Icon(
                Icons.close,
                size: screenWidth * 0.035,
              ),
              onDeleted: _clearPatientFilter,
            ),
          if (_isFiltering)
            Chip(
              label: Text(
                'Date: ${_formatDate(_selectedStartDate!)} - ${_formatDate(_selectedEndDate!)}',
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                ),
              ),
              backgroundColor: Colors.blue.withOpacity(0.1),
              deleteIcon: Icon(
                Icons.close,
                size: screenWidth * 0.035,
              ),
              onDeleted: _clearDateFilter,
            ),
          if (_searchQuery.isNotEmpty)
            Chip(
              label: Text(
                'Search: $_searchQuery',
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                ),
              ),
              backgroundColor: Colors.orange.withOpacity(0.1),
              deleteIcon: Icon(
                Icons.close,
                size: screenWidth * 0.035,
              ),
              onDeleted: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
        ],
      ),
    );
  }

  // ============================== SEARCH BAR ============================================
  Widget _buildSearchBar(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    bool isTablet,
    bool isSmallPhone,
  ) {
    final isFilterActive = _isFiltering || _isPatientFilterActive || _searchQuery.isNotEmpty;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.012,
      ),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              height: isTablet 
                  ? screenHeight * 0.065 
                  : isSmallPhone 
                      ? screenHeight * 0.05 
                      : screenHeight * 0.055,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isFilterActive ? Colors.green : const Color(0xFFE2E8F0),
                  width: isFilterActive ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: _isFiltering 
                      ? 'Search filtered results...' 
                      : _isPatientFilterActive
                      ? 'Search in patient: $_selectedPatientName...'
                      : 'Search prescriptions...',
                  hintStyle: TextStyle(
                    fontSize: isTablet 
                        ? screenWidth * 0.018 
                        : isSmallPhone 
                            ? screenWidth * 0.028 
                            : screenWidth * 0.032,
                    color: const Color(0xFFA0AEC0),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isFilterActive ? Colors.green : const Color(0xFFA0AEC0),
                    size: isTablet 
                        ? screenWidth * 0.025 
                        : isSmallPhone 
                            ? screenWidth * 0.04 
                            : screenWidth * 0.045,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.calendar_month,
                          color: Colors.green,
                          size: isTablet 
                              ? screenWidth * 0.035 
                              : isSmallPhone 
                                  ? screenWidth * 0.045 
                                  : screenWidth * 0.055,
                        ),
                        onPressed: () => _selectDateRange(context),
                        padding: EdgeInsets.all(
                          isTablet 
                              ? screenWidth * 0.01 
                              : isSmallPhone 
                                  ? screenWidth * 0.01 
                                  : screenWidth * 0.015
                        ),
                        constraints: BoxConstraints(
                          minWidth: isTablet 
                              ? screenWidth * 0.05 
                              : isSmallPhone 
                                  ? screenWidth * 0.07 
                                  : screenWidth * 0.09,
                          minHeight: isTablet 
                              ? screenWidth * 0.05 
                              : isSmallPhone 
                                  ? screenWidth * 0.07 
                                  : screenWidth * 0.09,
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: const Color(0xFFA0AEC0),
                            size: isTablet 
                                ? screenWidth * 0.02 
                                : isSmallPhone 
                                    ? screenWidth * 0.035 
                                    : screenWidth * 0.04,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: isTablet 
                                ? screenWidth * 0.035 
                                : isSmallPhone 
                                    ? screenWidth * 0.05 
                                    : screenWidth * 0.06,
                          ),
                        ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.025,
                    vertical: 0,
                  ),
                  isDense: true,
                ),
                style: TextStyle(
                  fontSize: isTablet 
                      ? screenWidth * 0.02 
                      : isSmallPhone 
                          ? screenWidth * 0.03 
                          : screenWidth * 0.035,
                  color: const Color(0xFF1A202C),
                ),
              ),
            ),
          ),

          Container(
            margin: EdgeInsets.only(left: screenWidth * 0.025),
            child: Stack(
              children: [
                Container(
                  width: isTablet 
                      ? screenWidth * 0.055 
                      : isSmallPhone 
                          ? screenWidth * 0.08 
                          : screenWidth * 0.09,
                  height: isTablet 
                      ? screenWidth * 0.055 
                      : isSmallPhone 
                          ? screenWidth * 0.08 
                          : screenWidth * 0.09,
                  decoration: BoxDecoration(
                    color: _isPatientFilterActive 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green,
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.person,
                      color: Colors.green,
                      size: isTablet 
                          ? screenWidth * 0.03 
                          : isSmallPhone 
                              ? screenWidth * 0.04 
                              : screenWidth * 0.05,
                    ),
                    onPressed: _showPatientFilterDialog,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                if (_isPatientFilterActive)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: isTablet ? 12 : isSmallPhone ? 10 : 16,
                      height: isTablet ? 12 : isSmallPhone ? 10 : 16,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: isTablet ? 8 : isSmallPhone ? 6 : 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================== ERROR WIDGET============================================
  Widget _buildErrorWidget(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
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

  // ===========================CONTENT ============================================
  Widget _buildContent(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    bool isTablet,
  ) {
    final filteredData = _getFilteredPrescriptions();
    final isFilterActive = _isFiltering || _searchQuery.isNotEmpty || _isPatientFilterActive;
    
    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isFilterActive 
                  ? Icons.filter_alt_off 
                  : Icons.medication_outlined,
              size: screenWidth * 0.15,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              isFilterActive 
                  ? 'No prescriptions found matching your filters' 
                  : 'No Prescriptions Found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            if (_isPatientFilterActive && _selectedPatientName != null) ...[
              SizedBox(height: screenHeight * 0.01),
              Text(
                'Patient: $_selectedPatientName',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ],
            if (!isFilterActive) ...[
              SizedBox(height: screenHeight * 0.01),
              Text(
                'Pull down to refresh',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ],
            if (isFilterActive) ...[
              SizedBox(height: screenHeight * 0.02),
              TextButton(
                onPressed: _clearAllFilters,
                child: Text(
                  'Clear All Filters',
                  textAlign: TextAlign.center,
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

  // ======================== PRESCRIPTION CARD====================
  Widget _buildPrescriptionCard(
    Prescription p,
    double screenWidth,
    double screenHeight,
    bool isTablet,
  ) {
    final bgColor = p.canvasBg != null && p.canvasBg != 'white'
        ? _parseColor(p.canvasBg!)
        : Colors.white;

    return Card(
      elevation: isTablet ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
      ),
      color: bgColor,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? screenWidth * 0.03 : screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: isTablet ? 3 : 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                            'PRESCRIPTION',
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ID: ${p.bookingId}',
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

            // Patient Information
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
                      mainAxisSize: MainAxisSize.min,
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
                      mainAxisSize: MainAxisSize.min,
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
                      mainAxisSize: MainAxisSize.min,
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
                      mainAxisSize: MainAxisSize.min,
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
                          '#${p.patientId}',
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
              Divider(
                height: screenHeight * 0.025,
                color: const Color(0xFFE2E8F0),
              ),
            ],

            // Chief Complaint
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

            // Medications
            if (p.medications.isNotEmpty) ...[
              Text(
                'Medications',
                style: TextStyle(
                  fontSize: isTablet ? screenWidth * 0.02 : screenWidth * 0.035,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A202C),
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEDF2F7),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: isTablet ? 100 : 80,
                                child: const Text(
                                  'Medicine',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A5568),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: isTablet ? 70 : 55,
                                child: const Text(
                                  'Dosage',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A5568),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: isTablet ? 70 : 55,
                                child: const Text(
                                  'Duration',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A5568),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: isTablet ? 80 : 65,
                                child: const Text(
                                  'Frequency',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A5568),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: isTablet ? 80 : 65,
                                child: const Text(
                                  'Timing',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A5568),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: isTablet ? 90 : 70,
                                child: const Text(
                                  'Instructions',
                                  style: TextStyle(
                                    fontSize: 10,
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
                        ...p.medications.map((med) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: const Color(0xFFE2E8F0), width: 0.5)),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: isTablet ? 100 : 80,
                                  child: Text(
                                    med.medicineName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1A202C),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: isTablet ? 70 : 55,
                                  child: Text(
                                    med.dosage,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF1A202C),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: isTablet ? 70 : 55,
                                  child: Text(
                                    med.duration,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF1A202C),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: isTablet ? 80 : 65,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEBF8FF),
                                      borderRadius: BorderRadius.circular(8),
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
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: isTablet ? 80 : 65,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0FFF4),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      med.timing,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF276749),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: isTablet ? 90 : 70,
                                  child: Text(
                                    med.instructions.isNotEmpty ? med.instructions : ' ',
                                    style: const TextStyle(
                                      fontSize: 10,
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
              ),
              Divider(
                height: screenHeight * 0.025,
                color: const Color(0xFFE2E8F0),
              ),
            ],

            // Investigations
            if (p.investigations != null && p.investigations!.isNotEmpty) ...[
              Text(
                'Investigations',
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
                  p.investigations!,
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

            // Doctor Notes
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

            // Signature
            if (p.prescribedBy != null && p.prescribedBy!.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
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
                        'Prescribed by',
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

  // ==============================HELPERS==============
  Color _parseColor(String colorString) {
    if (colorString == 'white') return Colors.white;
    if (colorString == 'transparent') return Colors.transparent;
    try {
      return Color(int.parse('FF${colorString.replaceAll('#', '')}', radix: 16));
    } catch (e) {
      return Colors.white;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}