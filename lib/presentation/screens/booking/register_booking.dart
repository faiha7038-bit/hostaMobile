
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:hosta/data/models/doctor_model.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:hosta/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

class RegisterBooking extends StatefulWidget {
  final Doctor doctor;
  const RegisterBooking({super.key, required this.doctor});

  @override
  State<RegisterBooking> createState() => _RegisterBookingState();
}

class _RegisterBookingState extends State<RegisterBooking> {
  List<int> getAvailableWeekdays() {
    final Map<String, int> dayMap = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
    };

    final List<int> availableDays = [];

    for (final item in widget.doctor.consultingOne) {
      if (!item.isHoliday) {
        availableDays.add(dayMap[item.day.toLowerCase()]!);
      }
    }

    for (final item in widget.doctor.consultingTwo) {
      if (!item.isHoliday) {
        availableDays.add(dayMap[item.day.toLowerCase()]!);
      }
    }

    return availableDays.toSet().toList();
  }

  final TextEditingController patientNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController placeController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  DateTime? dob;
  DateTime? appointmentDate;

  String? selectedGender;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();
  List<dynamic> _patients = [];
  int? _selectedPatientId;
  Map<String, dynamic>? _selectedPatient;
  bool _isLoadingPatients = true;
  bool _isAutoFilling = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchPatients();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null || userId.isEmpty) return;

    try {
      final apiService = ApiService();
      final response = await apiService.getAUser(userId);

      if (response.data != null) {
        final user = response.data['data'] ?? response.data;
        setState(() {
          patientNameController.text = user['name'] ?? '';
          phoneController.text =
              user['mobileNumber']?.toString() ??
              user['phone']?.toString() ??
              '';
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _fetchPatients() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString('userId');

    if (storedUserId == null) {
      setState(() => _isLoadingPatients = false);
      return;
    }

    try {
      final apiService = ApiService();
      final response = await apiService.getPatients(
        hospitalId: widget.doctor.hospitalId,
        userId: int.parse(storedUserId),
      );

      if (response.data != null && response.data['data'] != null) {
        setState(() {
          _patients = response.data['data'];
          _isLoadingPatients = false;
        });
      } else {
        setState(() => _isLoadingPatients = false);
      }
    } catch (e) {
      setState(() => _isLoadingPatients = false);
    }
  }

  void _onPatientSelected(dynamic patient) {
    String place = patient['addressLine'] ?? '';
    if ((place.isEmpty || place == 'N/A') && patient['location'] != null) {
      place = patient['location']['place'] ?? '';
    }
    setState(() {
      _selectedPatient = patient;
      _selectedPatientId = patient['id'];
      patientNameController.text = patient['name'] ?? '';
      phoneController.text = patient['mobileNumber'] ?? '';
    });
  }

  Future<void> _selectDate(BuildContext context, bool isPastOnly) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isPastOnly
          ? (dob ?? DateTime(2000))
          : (appointmentDate ?? now),
      firstDate: isPastOnly ? DateTime(1900) : now,
      lastDate: isPastOnly ? now : now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.green,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isPastOnly) {
          dob = picked;
          final age = _calculateAge(picked);
          ageController.text = age.toString();
        } else {
          appointmentDate = picked;
        }
      });
    }
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String formatDob(DateTime date) => DateFormat('dd/MM/yyyy').format(date);
  String formatBookingDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  Future<void> _handleBooking() async {
    if (_isSubmitting) return;

    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString('userId');
    if (storedUserId == null || storedUserId.isEmpty) {
      _showLoginDialog();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (dob == null) {
      showTopSnackBar(context, 'Please select date of birth', isError: true);
      return;
    }

    if (appointmentDate == null) {
      showTopSnackBar(context, 'Please select appointment date', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final bookingData = {
      'userId': int.parse(storedUserId),
      'patientId': _selectedPatient?['id'],
      'patient_dob': DateFormat('dd/MM/yyyy').format(dob!),
      'patient_age': int.parse(ageController.text),
      'patient_gender': selectedGender,
      'patient_name': patientNameController.text,
      'patient_place': placeController.text,
      'patient_phone': phoneController.text,
      'hospitalId': int.parse(widget.doctor.hospitalId.toString()),
      'hospitalName': widget.doctor.hospitalName ?? '',
      'doctorId': int.parse(widget.doctor.id.toString()),
      'booking_date': DateFormat('yyyy-MM-dd').format(appointmentDate!),
      'department': widget.doctor.specialty,
      'displayName': widget.doctor.name,
      'booking_status': 'user booking',
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    try {
      final apiService = ApiService();
      final response = await apiService.createBooking(bookingData);

      if (mounted && Navigator.canPop(context)) Navigator.pop(context);

   
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null &&
          response.data['success'] == true) {
        
        
        String? patientId;
        
        // Try different response structures
        if (response.data['data'] != null) {
          patientId = response.data['data']['patientId']?.toString();
        }
        
        if (patientId == null || patientId.isEmpty) {
          patientId = response.data['patientId']?.toString();
        }
        
        if (patientId == null || patientId.isEmpty) {
          patientId = _selectedPatient?['id']?.toString();
        }
        
        if (patientId == null || patientId.isEmpty) {
          patientId = storedUserId;
        }
        
        //  Save to SharedPreferences
        if (patientId != null && patientId.isNotEmpty) {
          await prefs.setString('patientId', patientId);
         
          
          // Verify
          String? verify = prefs.getString('patientId');
        
        }
       
        
        if (mounted) {
          showTopSnackBar(
            context,
            '✅ Booking successful! Appointment confirmed with Dr. ${widget.doctor.name}',
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted)
          showTopSnackBar(
            context,
            response.data['message'] ?? 'Booking failed',
            isError: true,
          );
      }
    } on DioException catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);

      String errorMsg = "Booking failed";
      if (e.response?.data is Map) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      }
      if (mounted) {
        showTopSnackBar(context, errorMsg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showLoginDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double dialogRadius = _clamp(screenWidth * 0.05, 12, 24);
    final double titleFontSize = _clamp(screenWidth * 0.045, 16, 24);
    final double contentFontSize = _clamp(screenWidth * 0.04, 14, 20);
    final double buttonFontSize = _clamp(screenWidth * 0.04, 14, 20);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogRadius),
        ),
        title: Text(
          'Sign In Required',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
        content: Text(
          'Please sign in to book appointments and access all features.',
          style: TextStyle(fontSize: contentFontSize),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey, fontSize: buttonFontSize),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Signin()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_clamp(screenWidth * 0.025, 6, 16)),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: _clamp(screenWidth * 0.04, 12, 24),
                vertical: _clamp(screenHeight * 0.015, 8, 16),
              ),
            ),
            child: Text(
              'Sign In',
              style: TextStyle(
                color: Colors.white,
                fontSize: buttonFontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Clamped values
    final double appBarTitleSize = _clamp(screenWidth * 0.05, 16, 24);
    final double leadingIconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double headerPadding = _clamp(screenWidth * 0.04, 12, 24);
    final double avatarRadius = _clamp(screenWidth * 0.04, 20, 40);
    final double doctorNameSize = _clamp(screenWidth * 0.045, 16, 24);
    final double doctorSubtitleSize = _clamp(screenWidth * 0.035, 12, 18);
    final double fieldRadius = _clamp(screenWidth * 0.03, 8, 16);
    final double fieldPaddingHoriz = _clamp(screenWidth * 0.04, 12, 24);
    final double fieldPaddingVert = _clamp(screenHeight * 0.015, 8, 16);
    final double labelFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double buttonFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double buttonPaddingV = _clamp(screenHeight * 0.02, 12, 20);
    final double spacing = _clamp(screenHeight * 0.02, 12, 20);
    final double dropdownFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double noPatientFontSize = _clamp(screenWidth * 0.04, 14, 20);
    final double loaderStrokeWidth = _clamp(screenWidth * 0.008, 2, 6);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Book Appointment",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: appBarTitleSize,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: leadingIconSize),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(headerPadding),
              color: Colors.green[50],
              child: Row(
                children: [
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: Colors.green,
                    child: Text(
                      widget.doctor.name.isNotEmpty
                          ? widget.doctor.name[0].toUpperCase()
                          : 'D',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _clamp(screenWidth * 0.04, 14, 22),
                      ),
                    ),
                  ),
                  SizedBox(width: headerPadding * 0.75),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ' ${widget.doctor.name}',
                          style: TextStyle(
                            fontSize: doctorNameSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.doctor.specialty,
                          style: TextStyle(
                            fontSize: doctorSubtitleSize,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '🏥 ${widget.doctor.hospitalName ?? "Hospital"}',
                          style: TextStyle(fontSize: doctorSubtitleSize),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Patient dropdown
            if (_isLoadingPatients)
              Padding(
                padding: EdgeInsets.all(fieldPaddingHoriz),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: loaderStrokeWidth,
                  ),
                ),
              )
            else if (_patients.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: fieldPaddingHoriz,
                  vertical: _clamp(screenHeight * 0.01, 6, 12),
                ),
                child: DropdownButtonFormField<int>(
                  value: _selectedPatientId,
                  decoration: InputDecoration(
                    labelText: 'Select existing patient',
                    labelStyle: TextStyle(fontSize: labelFontSize),
                    prefixIcon: const Icon(Icons.people, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fieldRadius),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: fieldPaddingHoriz * 0.75,
                      vertical: fieldPaddingVert * 0.8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: -1,
                      child: Text('+ New Patient'),
                    ),
                    ..._patients.map((patient) {
                      return DropdownMenuItem<int>(
                        value: patient['id'],
                        child: Text(
                          '${patient['patientId']} - ${patient['name']}',
                          style: TextStyle(fontSize: dropdownFontSize),
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    if (value == -1 || value == null) {
                      setState(() {
                        _selectedPatientId = null;
                        _selectedPatient = null;
                        placeController.clear();
                        ageController.clear();
                        selectedGender = null;
                        dob = null;
                      });
                      _loadUserData();
                      return;
                    }
                    final patient = _patients.firstWhere(
                      (p) => p['id'] == value,
                    );
                    setState(() {
                      _selectedPatientId = value;
                      _selectedPatient = patient;
                    });
                    _onPatientSelected(patient);
                  },
                ),
              )
            else
              Padding(
                padding: EdgeInsets.all(fieldPaddingHoriz),
                child: Text(
                  'No existing patients found. Please fill the form below.',
                  style: TextStyle(
                    fontSize: noPatientFontSize,
                    color: Colors.grey[600],
                  ),
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(fieldPaddingHoriz),
                child: Column(
                  children: [
                    _buildTextField(
                      context: context,
                      controller: patientNameController,
                      label: 'Patient Name',
                      icon: Icons.person,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    SizedBox(height: spacing),
                    _buildTextField(
                      context: context,
                      controller: phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    SizedBox(height: spacing),
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        value: selectedGender,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          labelStyle: TextStyle(fontSize: labelFontSize),
                          prefixIcon: const Icon(Icons.people, color: Colors.green),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fieldRadius),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fieldRadius),
                            borderSide: const BorderSide(color: Colors.green),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: fieldPaddingHoriz * 0.75,
                            vertical: fieldPaddingVert * 0.8,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedGender = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select gender';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: spacing),
                    _buildDateField(
                      context: context,
                      label: 'Date of Birth',
                      value: dob,
                      onTap: () => _selectDate(context, true),
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    SizedBox(height: spacing),
                    _buildTextField(
                      context: context,
                      controller: ageController,
                      label: 'Age',
                      icon: Icons.badge,
                      keyboardType: TextInputType.number,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    SizedBox(height: spacing),
                    _buildTextField(
                      context: context,
                      controller: placeController,
                      label: 'Place',
                      icon: Icons.location_on,
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    SizedBox(height: spacing),
                    _buildDateField(
                      context: context,
                      label: 'Appointment Date',
                      value: appointmentDate,
                      onTap: () => _selectDate(context, false),
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    if (widget.doctor.consulting.getAvailableSlots().isNotEmpty) ...[
                      SizedBox(height: spacing),
                      Container(
                        padding: EdgeInsets.all(fieldPaddingHoriz * 0.75),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(fieldRadius),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available Timings:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: labelFontSize,
                              ),
                            ),
                            SizedBox(height: _clamp(screenHeight * 0.01, 6, 12)),
                            ...widget.doctor.consulting.getAvailableSlots().map(
                              (slot) => Padding(
                                padding: EdgeInsets.only(bottom: _clamp(screenHeight * 0.005, 4, 8)),
                                child: Text(
                                  '• ${slot.title}: ${slot.time}',
                                  style: TextStyle(fontSize: labelFontSize),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(fieldPaddingHoriz),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: buttonPaddingV),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(fieldRadius),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: _clamp(screenWidth * 0.05, 18, 28),
                          width: _clamp(screenWidth * 0.05, 18, 28),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'CONFIRM BOOKING',
                          style: TextStyle(
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required double screenWidth,
    required double screenHeight,
  }) {
    final double fieldRadius = _clamp(screenWidth * 0.03, 8, 16);
    final double fontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double iconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double paddingH = _clamp(screenWidth * 0.03, 8, 16);
    final double paddingV = _clamp(screenHeight * 0.015, 8, 16);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        if (label == 'Phone Number') {
          if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
            return 'Enter valid 10 digit phone number';
          }
        }
        if (label == 'Patient Name') {
          if (value.trim().length < 3) {
            return 'Name must be at least 3 characters';
          }
        }
        if (label == 'Age') {
          if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
            return 'Enter valid age';
          }
          final age = int.tryParse(value.trim());
          if (age == null || age <= 0 || age > 120) {
            return 'Enter valid age';
          }
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: fontSize),
        prefixIcon: Icon(icon, color: Colors.green, size: iconSize),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(fieldRadius)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: const BorderSide(color: Colors.green),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(fieldRadius),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: paddingH,
          vertical: paddingV,
        ),
      ),
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    required double screenWidth,
    required double screenHeight,
  }) {
    final double fieldRadius = _clamp(screenWidth * 0.03, 8, 16);
    final double fontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double iconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double paddingH = _clamp(screenWidth * 0.03, 8, 16);
    final double paddingV = _clamp(screenHeight * 0.015, 8, 16);

    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: fontSize),
          prefixIcon: Icon(Icons.calendar_today, color: Colors.green, size: iconSize),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: paddingH,
            vertical: paddingV,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value == null
                  ? "Select Date"
                  : "${value.day}/${value.month}/${value.year}",
              style: TextStyle(
                color: value == null ? Colors.grey : Colors.black,
                fontSize: fontSize,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey, size: iconSize * 0.8),
          ],
        ),
      ),
    );
  }
}

