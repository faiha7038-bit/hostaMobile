import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/services/socket-service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/api_service.dart';

class PatientDetailsScreen extends ConsumerStatefulWidget {
  const PatientDetailsScreen({super.key});

  @override
  ConsumerState<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends ConsumerState<PatientDetailsScreen> {
  List<Map<String, dynamic>> patientsList = [];
  List<Map<String, dynamic>> filteredPatientsList = [];
  Map<String, dynamic> currentPatient = {};
  bool isLoading = true;
  String? userId;
  int? hospitalId;
  int? selectedPatientIndex = 0;
  String? errorMessage;
  bool _listenerAdded = false;
  late Function(dynamic) _onPatientEvent;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
    _setupSocketListener();
  }

  @override
  void dispose() {
    SocketService().removeListener(
      "PATIENT_REGISTERED",
      _onPatientEvent,
    );

    SocketService().removeListener(
      "PATIENT_UPDATED",
      _onPatientEvent,
    );

    SocketService().removeListener(
      "PATIENT_DELETED",
      _onPatientEvent,
    );

    super.dispose();
  }

  void _setupSocketListener() {
    if (_listenerAdded) return;

    _listenerAdded = true;

    _onPatientEvent = (data) async {
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        await _refreshPatientData();
      }
    };
    
    SocketService().addListener(
      [
        'PATIENT_REGISTERED',
        'PATIENT_UPDATED',
        'PATIENT_DELETED',
      ],
      _onPatientEvent,
    );
  }

  Future<void> _loadPatientData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString("userId");

      if (userId == null || userId!.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = "Please login first";
        });
        return;
      }

      final response = await ApiService().getPatients(
        userId: int.parse(userId!),
      );

      patientsList = List<Map<String, dynamic>>.from(
        response.data['data'] ?? [],
      );

      currentPatient = patientsList.isNotEmpty ? patientsList.first : {};

      setState(() {
        isLoading = false;
        errorMessage = patientsList.isEmpty ? "No patients found" : null;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'Not Available';
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return "${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)}";
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateTimeString) {
    if (dateTimeString.isEmpty) return 'Not Available';
    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      return "${dateTime.year}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)} ${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}";
    } catch (e) {
      return dateTimeString;
    }
  }

  String _twoDigits(int n) {
    return n.toString().padLeft(2, '0');
  }

  Future<void> _refreshPatientData() async {
    await _loadPatientData();
  }

  String _getValue(String key, {String defaultValue = ''}) {
    try {
      final value = currentPatient[key];
      if (value == null) return defaultValue;
      if (value is String && value.isEmpty) return defaultValue;
      if (value is int && value == 0) return defaultValue;
      return value.toString();
    } catch (e) {
      return defaultValue;
    }
  }

  String _getLocationValue(String key, {String defaultValue = ''}) {
    try {
      final location = currentPatient['location'];
      if (location == null) return defaultValue;
      if (location is Map) {
        final value = location[key];
        if (value == null) return defaultValue;
        if (value is String && value.isEmpty) return defaultValue;
        if (value is int && value == 0) return defaultValue;
        return value.toString();
      }
      return defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }

  bool _hasValue(String key) {
    try {
      final value = currentPatient[key];
      if (value == null) return false;
      if (value is String && value.isEmpty) return false;
      if (value is int && value == 0) return false;
      return true;
    } catch (e) {
      return false;
    }
  }

  bool _hasLocation() {
    try {
      final location = currentPatient['location'];
      if (location == null) return false;
      if (location is Map) {
        final place = location['place'];
        final pincode = location['pincode'];
        if (place != null && place.toString().isNotEmpty) return true;
        if (pincode != null && pincode != 0) return true;
        return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void _changePatient(int index) {
    setState(() {
      selectedPatientIndex = index;
      currentPatient = patientsList[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1024;
    final isLargeScreen = screenWidth >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Patient Details',
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
        backgroundColor: const Color(0xFF28A745),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, 
            color: Colors.white, 
            size: isSmallScreen 
                ? screenWidth * 0.06 
                : isMediumScreen 
                    ? screenWidth * 0.04 
                    : screenWidth * 0.03,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: isSmallScreen 
            ? kToolbarHeight 
            : isMediumScreen 
                ? kToolbarHeight * 1.1 
                : kToolbarHeight * 1.2,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: isSmallScreen ? 4 : 6,
              ),
            )
          : errorMessage != null
              ? _buildErrorWidget(screenWidth, screenHeight)
              : RefreshIndicator(
                  onRefresh: _refreshPatientData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: isLargeScreen
                        ? _buildLargeScreenLayout(screenWidth, screenHeight)
                        : _buildSmallMediumScreenLayout(screenWidth, screenHeight),
                  ),
                ),
    );
  }

  Widget _buildSmallMediumScreenLayout(double screenWidth, double screenHeight) {
    return Column(
      children: [
        if (patientsList.length > 1)
          _buildPatientDropdown(screenWidth, screenHeight),
        
        if (patientsList.length > 1)
          SizedBox(height: screenHeight * 0.015),
        
        _buildPatientHeader(screenWidth, screenHeight),
        
        if (_hasValue('patientId') || _hasValue('id'))
          SizedBox(height: screenHeight * 0.025),
        
        if (_hasValue('patientId') || _hasValue('id'))
          _buildPatientIdSection(screenWidth, screenHeight),
        
        SizedBox(height: screenHeight * 0.025),
        
        _buildPersonalInfoSection(screenWidth, screenHeight),
        
        if (_hasLocation() || _hasValue('addressLine'))
          SizedBox(height: screenHeight * 0.025),
        
        if (_hasLocation() || _hasValue('addressLine'))
          _buildLocationSection(screenWidth, screenHeight),
        
        SizedBox(height: screenHeight * 0.025),
        
        _buildStatusSection(screenWidth, screenHeight),
        
        SizedBox(height: screenHeight * 0.03),
      ],
    );
  }

  Widget _buildLargeScreenLayout(double screenWidth, double screenHeight) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Panel - Patient List
        Expanded(
          flex: 1,
          child: Column(
            children: [
              if (patientsList.length > 1)
                _buildPatientDropdown(screenWidth, screenHeight),
              _buildPatientHeader(screenWidth, screenHeight),
            ],
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        // Right Panel - Patient Details
        Expanded(
          flex: 2,
          child: Column(
            children: [
              if (_hasValue('patientId') || _hasValue('id'))
                _buildPatientIdSection(screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.02),
              _buildPersonalInfoSection(screenWidth, screenHeight),
              if (_hasLocation() || _hasValue('addressLine'))
                SizedBox(height: screenHeight * 0.02),
              if (_hasLocation() || _hasValue('addressLine'))
                _buildLocationSection(screenWidth, screenHeight),
              SizedBox(height: screenHeight * 0.02),
              _buildStatusSection(screenWidth, screenHeight),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientDropdown(double screenWidth, double screenHeight) {
    final isSmallScreen = screenWidth < 600;
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedPatientIndex,
            isExpanded: true,
            icon: Padding(
              padding: EdgeInsets.only(right: screenWidth * 0.03),
              child: Icon(
                Icons.arrow_drop_down,
                color: const Color(0xFF28A745),
                size: isSmallScreen 
                    ? screenWidth * 0.07 
                    : screenWidth * 0.05,
              ),
            ),
            iconSize: isSmallScreen 
                ? screenWidth * 0.07 
                : screenWidth * 0.05,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.01,
            ),
            dropdownColor: Colors.white,
            style: TextStyle(
              fontSize: isSmallScreen 
                  ? screenWidth * 0.04 
                  : screenWidth * 0.03,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            items: patientsList.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> patient = entry.value;
              String patientName = patient['name'] ?? 'Patient ${index + 1}';
              String patientId = patient['patientId'] ?? '';
              
              return DropdownMenuItem<int>(
                value: index,
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        isSmallScreen 
                            ? screenWidth * 0.02 
                            : screenWidth * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF28A745).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          isSmallScreen 
                              ? screenWidth * 0.02 
                              : screenWidth * 0.015,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        color: const Color(0xFF28A745),
                        size: isSmallScreen 
                            ? screenWidth * 0.04 
                            : screenWidth * 0.03,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            patientName,
                            style: TextStyle(
                              fontSize: isSmallScreen 
                                  ? screenWidth * 0.04 
                                  : screenWidth * 0.03,
                              fontWeight: FontWeight.w600,
                              color: selectedPatientIndex == index 
                                  ? const Color(0xFF28A745) 
                                  : Colors.black87,
                            ),
                          ),
                          if (patientId.isNotEmpty)
                            Text(
                              patientId,
                              style: TextStyle(
                                fontSize: isSmallScreen 
                                    ? screenWidth * 0.03 
                                    : screenWidth * 0.025,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (selectedPatientIndex == index)
                      Icon(
                        Icons.check_circle,
                        color: const Color(0xFF28A745),
                        size: isSmallScreen 
                            ? screenWidth * 0.05 
                            : screenWidth * 0.04,
                      ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (int? newIndex) {
              if (newIndex != null) {
                _changePatient(newIndex);
              }
            },
            selectedItemBuilder: (context) {
              return patientsList.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> patient = entry.value;
                String patientName = patient['name'] ?? 'Patient ${index + 1}';
                
                return Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(
                        isSmallScreen 
                            ? screenWidth * 0.015 
                            : screenWidth * 0.01,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF28A745).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(
                          isSmallScreen 
                              ? screenWidth * 0.02 
                              : screenWidth * 0.015,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        color: const Color(0xFF28A745),
                        size: isSmallScreen 
                            ? screenWidth * 0.035 
                            : screenWidth * 0.025,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.025),
                    Expanded(
                      child: Text(
                        patientName,
                        style: TextStyle(
                          fontSize: isSmallScreen 
                              ? screenWidth * 0.04 
                              : screenWidth * 0.03,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF28A745),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${selectedPatientIndex! + 1}/${patientsList.length}',
                      style: TextStyle(
                        fontSize: isSmallScreen 
                            ? screenWidth * 0.03 
                            : screenWidth * 0.025,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(double screenWidth, double screenHeight) {
    final isSmallScreen = screenWidth < 600;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add,
              color: Colors.grey,
              size: isSmallScreen 
                  ? screenWidth * 0.15 
                  : screenWidth * 0.1,
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              'No Patient Details Found',
              style: TextStyle(
                fontSize: isSmallScreen 
                    ? screenWidth * 0.05 
                    : screenWidth * 0.035,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'Please book a doctor appointment first',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmallScreen 
                    ? screenWidth * 0.04 
                    : screenWidth * 0.03,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            ElevatedButton.icon(
              onPressed: _refreshPatientData,
              icon: Icon(
                Icons.refresh, 
                size: isSmallScreen 
                    ? screenWidth * 0.05 
                    : screenWidth * 0.04,
              ),
              label: Text(
                'Try again',
                style: TextStyle(
                  fontSize: isSmallScreen 
                      ? screenWidth * 0.04 
                      : screenWidth * 0.03,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF28A745),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: screenHeight * 0.02,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader(double screenWidth, double screenHeight) {
    final isSmallScreen = screenWidth < 600;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getValue('name').isEmpty ? 'Patient Name' : _getValue('name'),
            style: TextStyle(
              color: Colors.black87,
              fontSize: isSmallScreen 
                  ? screenWidth * 0.06 
                  : screenWidth * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          
          Wrap(
            alignment: WrapAlignment.start,
            spacing: screenWidth * 0.025,
            runSpacing: screenHeight * 0.005,
            children: [
              if (_hasValue('patientId'))
                _buildInfoChipLight(
                  icon: Icons.badge_outlined,
                  label: _getValue('patientId'),
                  screenWidth: screenWidth,
                ),
              if (_hasValue('age'))
                _buildInfoChipLight(
                  icon: Icons.calendar_today_outlined,
                  label: '${_getValue('age')} yrs',
                  screenWidth: screenWidth,
                ),
              if (_hasValue('gender'))
                _buildInfoChipLight(
                  icon: Icons.wc_outlined,
                  label: _getValue('gender'),
                  screenWidth: screenWidth,
                ),
              _buildStatusChip(screenWidth),
            ],
          ),
          SizedBox(height: screenHeight * 0.005),
          
          Divider(
            height: screenHeight * 0.02,
            thickness: screenWidth * 0.0025,
            color: Colors.grey[200],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChipLight({
    required IconData icon,
    required String label,
    required double screenWidth,
  }) {
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenWidth * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        border: Border.all(
          color: Colors.grey[300]!,
          width: screenWidth * 0.0025,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.grey[600],
            size: isSmallScreen 
                ? screenWidth * 0.035 
                : screenWidth * 0.025,
          ),
          SizedBox(width: screenWidth * 0.01),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: isSmallScreen 
                  ? screenWidth * 0.03 
                  : screenWidth * 0.025,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(double screenWidth) {
    final isActive = currentPatient['isActive'] == true;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenWidth * 0.015,
      ),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        border: Border.all(
          color: isActive ? Colors.green[300]! : Colors.red[300]!,
          width: screenWidth * 0.0025,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.verified : Icons.block,
            color: isActive ? Colors.green[700] : Colors.red[700],
            size: isSmallScreen 
                ? screenWidth * 0.035 
                : screenWidth * 0.025,
          ),
          SizedBox(width: screenWidth * 0.01),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: isActive ? Colors.green[700] : Colors.red[700],
              fontSize: isSmallScreen 
                  ? screenWidth * 0.03 
                  : screenWidth * 0.025,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientIdSection(double screenWidth, double screenHeight) {
    final isSmallScreen = screenWidth < 600;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          side: BorderSide(color: Colors.grey[200]!, width: screenWidth * 0.0025),
        ),
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(
                  isSmallScreen 
                      ? screenWidth * 0.02 
                      : screenWidth * 0.015,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF28A745).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
                child: Icon(
                  Icons.qr_code,
                  color: const Color(0xFF28A745),
                  size: isSmallScreen 
                      ? screenWidth * 0.06 
                      : screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient ID',
                      style: TextStyle(
                        fontSize: isSmallScreen 
                            ? screenWidth * 0.032 
                            : screenWidth * 0.025,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _getValue('patientId').isEmpty ? 'Not Available' : _getValue('patientId'),
                      style: TextStyle(
                        fontSize: isSmallScreen 
                            ? screenWidth * 0.04 
                            : screenWidth * 0.032,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF28A745),
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasValue('id'))
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF28A745).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                  child: Text(
                    'ID: ${_getValue('id')}',
                    style: TextStyle(
                      fontSize: isSmallScreen 
                          ? screenWidth * 0.032 
                          : screenWidth * 0.025,
                      color: const Color(0xFF28A745),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, double screenWidth) {
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenWidth * 0.02,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF28A745).withOpacity(0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.025),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
              isSmallScreen 
                  ? screenWidth * 0.02 
                  : screenWidth * 0.015,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF28A745),
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isSmallScreen 
                  ? screenWidth * 0.045 
                  : screenWidth * 0.035,
            ),
          ),
          SizedBox(width: screenWidth * 0.025),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen 
                  ? screenWidth * 0.04 
                  : screenWidth * 0.032,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF28A745),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(double screenWidth, double screenHeight) {
    final isSmallScreen = screenWidth < 600;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Personal Information', Icons.person_outline, screenWidth),
          SizedBox(height: screenHeight * 0.012),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
              side: BorderSide(color: Colors.grey[200]!, width: screenWidth * 0.0025),
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.person_outline,
                    label: 'Full Name',
                    value: _getValue('name').isEmpty ? 'Not Available' : _getValue('name'),
                    screenWidth: screenWidth,
                  ),
                  if (_hasValue('mobileNumber')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Mobile Number',
                      value: _getValue('mobileNumber'),
                      screenWidth: screenWidth,
                    ),
                  ],
                  if (_hasValue('email')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _getValue('email'),
                      screenWidth: screenWidth,
                    ),
                  ],
                  if (_hasValue('dob')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      label: 'Date of Birth',
                      value: _formatDate(_getValue('dob')),
                      screenWidth: screenWidth,
                    ),
                  ],
                  if (_hasValue('gender')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.wc,
                      label: 'Gender',
                      value: _getValue('gender'),
                      screenWidth: screenWidth,
                    ),
                  ],
                  if (_hasValue('bloodGroup')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.bloodtype,
                      label: 'Blood Group',
                      value: _getValue('bloodGroup'),
                      screenWidth: screenWidth,
                    ),
                  ],
                  if (_hasValue('maritalStatus')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.family_restroom,
                      label: 'Marital Status',
                      value: _getValue('maritalStatus'),
                      screenWidth: screenWidth,
                    ),
                  ],
                  if (_hasValue('patientType')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.medical_information,
                      label: 'Patient Type',
                      value: _getValue('patientType'),
                      screenWidth: screenWidth,
                    ),
                  ],
                  if (_hasValue('guardianName')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.person,
                      label: 'Guardian Name',
                      value: _getValue('guardianName'),
                      screenWidth: screenWidth,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Location Information', Icons.location_on, screenWidth),
          SizedBox(height: screenHeight * 0.012),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
              side: BorderSide(color: Colors.grey[200]!, width: screenWidth * 0.0025),
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  if (_hasValue('addressLine'))
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address Line',
                      value: _getValue('addressLine'),
                      screenWidth: screenWidth,
                    ),
                  if (_hasValue('addressLine') && _hasLocation())
                    _buildDivider(screenWidth),
                  if (_hasLocation()) ...[
                    if (_getLocationValue('place').isNotEmpty) ...[
                      _buildInfoRow(
                        icon: Icons.place,
                        label: 'Place',
                        value: _getLocationValue('place'),
                        screenWidth: screenWidth,
                      ),
                      if (_getLocationValue('pincode').isNotEmpty)
                        _buildDivider(screenWidth),
                    ],
                    if (_getLocationValue('pincode').isNotEmpty)
                      _buildInfoRow(
                        icon: Icons.pin_drop,
                        label: 'Pincode',
                        value: _getLocationValue('pincode'),
                        screenWidth: screenWidth,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Status Information', Icons.info_outline, screenWidth),
          SizedBox(height: screenHeight * 0.012),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
              side: BorderSide(color: Colors.grey[200]!, width: screenWidth * 0.0025),
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.check_circle_outline,
                    label: 'Status',
                    value: currentPatient['isActive'] == true ? 'Active' : 'Inactive',
                    screenWidth: screenWidth,
                  ),
                  _buildDivider(screenWidth),
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Created At',
                    value: _getValue('createdAt').isEmpty 
                        ? 'Not Available' 
                        : _formatDateTime(_getValue('createdAt')),
                    screenWidth: screenWidth,
                  ),
                  if (_hasValue('updatedAt')) ...[
                    _buildDivider(screenWidth),
                    _buildInfoRow(
                      icon: Icons.update,
                      label: 'Last Updated',
                      value: _formatDateTime(_getValue('updatedAt')),
                      screenWidth: screenWidth,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required double screenWidth,
  }) {
    final isSmallScreen = screenWidth < 600;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(
              isSmallScreen 
                  ? screenWidth * 0.015 
                  : screenWidth * 0.01,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF28A745).withOpacity(0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF28A745),
              size: isSmallScreen 
                  ? screenWidth * 0.04 
                  : screenWidth * 0.035,
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          SizedBox(
            width: isSmallScreen 
                ? screenWidth * 0.28 
                : screenWidth * 0.22,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isSmallScreen 
                    ? screenWidth * 0.035 
                    : screenWidth * 0.028,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen 
                    ? screenWidth * 0.035 
                    : screenWidth * 0.028,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(double screenWidth) {
    return Divider(
      height: 0,
      thickness: screenWidth * 0.0025,
      color: Colors.grey[300],
    );
  }
}