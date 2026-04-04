import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:hosta/data/models/doctor_model.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

class Doctors extends StatefulWidget {
  final String hospitalId;
  final String specialty;
  
  const Doctors({super.key, required this.hospitalId, required this.specialty});

  @override
  State<Doctors> createState() => _DoctorsState();
}

class _DoctorsState extends State<Doctors> {
  String searchQuery = '';
  List<Hospital> hospitals = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    try {
      final response = await ApiService().getDoctors(
        id: widget.hospitalId,
        specialty: widget.specialty,
      );

      
      if (response.data['success'] == true) {
        setState(() {
          hospitals = (response.data['hospitals'] as List)
              .map((hospitalJson) => Hospital.fromJson(hospitalJson))
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response.data['message'] ?? 'Failed to load doctors';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading doctors: $e';
        isLoading = false;
      });
    }
  }

  List<Doctor> get allDoctors {
    List<Doctor> doctors = [];
    for (var hospital in hospitals) {
      doctors.addAll(hospital.doctors.map((doctor) => doctor.copyWith(
        hospitalName: hospital.name,
        hospitalAddress: hospital.address,
        hospitalPhone: hospital.phone,
        hospitalId: hospital.id,
      )));
    }
    return doctors;
  }

  List<Doctor> get filteredDoctors {
    if (searchQuery.isEmpty) return allDoctors;
    
    return allDoctors.where((doctor) {
      final name = doctor.name.toLowerCase();
      final specialty = doctor.specialty.toLowerCase();
      final hospitalName = doctor.hospitalName?.toLowerCase() ?? '';
      
      return name.contains(searchQuery.toLowerCase()) ||
          specialty.contains(searchQuery.toLowerCase()) ||
          hospitalName.contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Doctors",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        bottom: false, // Important for keyboard handling
        child: Column(
          children: [
            // Search
            _buildSearchBar(),
            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            SizedBox(width: 16),
            Icon(Icons.search_rounded, color: Colors.grey[500], size: 20),
            SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search doctors, specialties...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.green));
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchDoctors,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: Text('Try Again', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results Count
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.white,
          child: Row(
            children: [
              Text(
                '${filteredDoctors.length} Doctors',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Spacer(),
            ],
          ),
        ),
        SizedBox(height: 8),
        // Doctors Grid
        Expanded(
          child: filteredDoctors.isEmpty
              ? _buildEmptyState()
              : _buildDoctorsGrid(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          SizedBox(height: 20),
          Text(
            'No doctors found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsGrid() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.82,
        ),
        itemCount: filteredDoctors.length,
        itemBuilder: (context, index) {
          final doctor = filteredDoctors[index];
          return _buildDoctorCard(doctor);
        },
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    String firstLetter = 'D';
    if (doctor.name.trim().isNotEmpty) {
      firstLetter = doctor.name.trim()[0].toUpperCase();
    }
    
    return GestureDetector(
      onTap: () => _showDoctorDetails(context, doctor),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Header with Avatar
            Container(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.green[500],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        firstLetter,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name.isNotEmpty ? doctor.name : 'Unknown Doctor',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 3),
                        Text(
                          doctor.specialty,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Doctor Details
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (doctor.qualification != null && doctor.qualification!.isNotEmpty)
                    Text(
                      doctor.qualification!,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.local_hospital_rounded, size: 11, color: Colors.grey[500]),
                      SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          doctor.hospitalName ?? 'Hospital',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Spacer(),
            
            // Book Button
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: () => _showBookingSheet(context, doctor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: doctor.bookingOpen ? Colors.green : Colors.grey[400],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12),
                    SizedBox(width: 4),
                    Text(
                      doctor.bookingOpen ? 'BOOK' : 'CLOSED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDoctorDetails(BuildContext context, Doctor doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DoctorDetailsSheet(doctor: doctor, onBook: _showBookingSheet);
      },
    );
  }

  void _showBookingSheet(BuildContext context, Doctor doctor) {
    if (!doctor.bookingOpen) {
        showTopSnackBar(context, 'Booking is currently closed for Dr. ${doctor.name}', isError: true);

      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BookingForm(doctor: doctor, onBooking: _handleBooking);
      },
    );
  }

  Future<void> _handleBooking(
    BuildContext context,
    Doctor doctor,
    String patientName,
    String patientPhone,
    String patientPlace,
    DateTime? patientDob,
    DateTime? appointmentDate,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString('userId');

    if (storedUserId == null) {
      _showLoginDialog(context);
      return;
    }

    if (patientName.isEmpty || patientPhone.isEmpty || patientPlace.isEmpty || 
        patientDob == null || appointmentDate == null) {
              showTopSnackBar(context, 'Please fill all required fields', isError: true);      
      return;
    }

    final now = DateTime.now();
    final selectedDate = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
    final currentDate = DateTime(now.year, now.month, now.day);
    
    if (selectedDate.isBefore(currentDate)) {
        showTopSnackBar(context, 'Please select a future date for appointment', isError: true);      
      return;
    }

    final selectedDay = _getDayName(appointmentDate.weekday);
    final isDayAvailable = doctor.consulting.any((day) => 
        day.day.toLowerCase() == selectedDay.toLowerCase() && day.sessions.isNotEmpty);

    if (!isDayAvailable) {
              showTopSnackBar(context, 'Dr. ${doctor.name} is not available on $selectedDay. Please select an available day.', isError: true);      
      return;
    }

    final bookingData = {
      'userId': storedUserId,
      'specialty': doctor.specialty,
      'doctor_name': doctor.name,
      'booking_date': appointmentDate.toIso8601String(),
      'patient_name': patientName,
      'patient_phone': patientPhone,
      'patient_place': patientPlace,
      'patient_dob': patientDob.toIso8601String(),
    };

    try {
  final response = await ApiService().createBooking(
    doctor.hospitalId!,
    bookingData,
  );

  if (response.statusCode == 201 || response.data['status'] == 201) {
    showTopSnackBar(
      context,
      'Appointment booked successfully with Dr. ${doctor.name}!',
    );
    Navigator.pop(context);
  } else {
    showTopSnackBar(
      context,
      response.data['message'] ?? 'Booking failed',
      isError: true,
    );
  }

} on DioException catch (dioError) {
  // Extract backend error
  String errorMessage = "Something went wrong";

  if (dioError.response != null) {
    try {
      errorMessage = dioError.response?.data['message'] ?? errorMessage;
    } catch (_) {}
  }

  showTopSnackBar(context, errorMessage, isError: true);

} catch (e) {
  showTopSnackBar(context, 'Error: $e', isError: true);
}

  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }

  void _showNotification(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessNotification(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 4),
        elevation: 6,
        margin: EdgeInsets.all(20),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign In Required', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Please sign in to book appointments and access all features.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Sign In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Modern Doctor Details Sheet
class DoctorDetailsSheet extends StatelessWidget {
  final Doctor doctor;
  final Function(BuildContext, Doctor) onBook;

  const DoctorDetailsSheet({super.key, required this.doctor, required this.onBook});

  @override
  Widget build(BuildContext context) {
    String firstLetter = 'D';
    if (doctor.name.trim().isNotEmpty) {
      firstLetter = doctor.name.trim()[0].toUpperCase();
    }
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.green[500],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      firstLetter,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        doctor.specialty,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (doctor.qualification != null)
                        Text(
                          doctor.qualification!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hospital Info
                  _buildInfoCard(
                    icon: Icons.local_hospital_rounded,
                    title: doctor.hospitalName ?? 'Hospital',
                    subtitle: doctor.hospitalAddress ?? 'Address not available',
                    color: Colors.green,
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Available Timings
                  Text(
                    'Available Days & Timings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  if (doctor.consulting.isNotEmpty)
                    _buildTimingsList(doctor.consulting)
                  else
                    _buildNoTimings(),
                  
                  SizedBox(height: 20),
                  
                  // About Doctor
                  Text(
                    'About Doctor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Dr. ${doctor.name} is a specialized ${doctor.specialty.toLowerCase()} with extensive experience in patient care. '
                    'Available for consultations as per the schedule above.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Action Buttons
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onBook(context, doctor);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: doctor.bookingOpen ? Colors.green : Colors.grey,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          doctor.bookingOpen ? 'Book Now' : 'Closed',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildInfoCard({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingsList(List<ConsultingDay> consultingDays) {
    return Column(
      children: consultingDays.map((day) {
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.calendar_today, color: Colors.green, size: 20),
            ),
            title: Text(
              day.day,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            subtitle: day.sessions.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: day.sessions.map((session) {
                      return Text(
                        '${session.startTime} - ${session.endTime}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  )
                : Text(
                    'Not Available',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoTimings() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(Icons.schedule_rounded, size: 40, color: Colors.grey[400]),
          SizedBox(height: 8),
          Text(
            'No schedule available',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Please contact the hospital for schedule',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}



class BookingForm extends StatefulWidget {
  final Doctor doctor;
  final Function(
    BuildContext context,
    Doctor doctor,
    String patientName,
    String patientPhone,
    String patientPlace,
    DateTime? patientDob,
    DateTime? appointmentDate,
  ) onBooking;

  const BookingForm({super.key, required this.doctor, required this.onBooking});

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final TextEditingController patientNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController placeController = TextEditingController();
  DateTime? dob;
  DateTime? appointmentDate;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _placeFocusNode = FocusNode();
  
  // Add loading state
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      if (_phoneFocusNode.hasFocus) {
        _scrollToField(1);
      }
    });
    _placeFocusNode.addListener(() {
      if (_placeFocusNode.hasFocus) {
        _scrollToField(2);
      }
    });
  }

  void _scrollToField(int fieldIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        (fieldIndex * 80.0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _phoneFocusNode.dispose();
    _placeFocusNode.dispose();
    super.dispose();
  }

  List<String> get availableDays {
    return widget.doctor.consulting
        .where((day) => day.sessions.isNotEmpty)
        .map((day) => day.day)
        .toList();
  }

  int _getWeekdayNumber(String dayName) {
    final normalizedDayName = dayName.toLowerCase().trim();
    switch (normalizedDayName) {
      case 'monday': return 1;
      case 'tuesday': return 2;
      case 'wednesday': return 3;
      case 'thursday': return 4;
      case 'friday': return 5;
      case 'saturday': return 6;
      case 'sunday': return 7;
      default: 
        return 0;
    }
  }

  bool _isDateEnabled(DateTime date) {
    if (availableDays.isEmpty) {
      return true;
    }
    
    final dayName = _getDayName(date.weekday);
    final isEnabled = availableDays.any((availableDay) {
      final normalizedAvailableDay = availableDay.toLowerCase().trim();
      final normalizedDayName = dayName.toLowerCase().trim();
      final matches = normalizedAvailableDay == normalizedDayName;
      
      if (matches) {
        print("✅ Date ${date.day}/${date.month}/${date.year} ($dayName) is enabled - matches available day: $availableDay");
      }
      
      return matches;
    });
    
    if (!isEnabled) {
      print("❌ Date ${date.day}/${date.month}/${date.year} ($dayName) is disabled - not in available days: $availableDays");
    }
    
    return isEnabled;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return 'Unknown';
    }
  }

  // Updated method to handle booking with loading state
  Future<void> _handleBooking() async {
    if (_isSubmitting) return; // Prevent multiple submissions
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onBooking(
        context,
        widget.doctor,
        patientNameController.text,
        phoneController.text,
        placeController.text,
        dob,
        appointmentDate,
      );
      
      // If booking is successful, the parent will close the sheet
      // If there's an error, we'll catch it below and reset the loading state
    } catch (e) {
      // Error is handled in parent, but we still need to reset loading state
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String firstLetter = 'D';
    if (widget.doctor.name.trim().isNotEmpty) {
      firstLetter = widget.doctor.name.trim()[0].toUpperCase();
    }
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green[500],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      firstLetter,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book Appointment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Dr. ${widget.doctor.name}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isSubmitting)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Available Days & Timings Preview
                    _buildTimingsPreview(),
                    
                    SizedBox(height: 24),
                    
                    // Patient Details Form
                    Text(
                      'Patient Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    _buildInputField('Full Name', patientNameController, Icons.person_outline),
                    SizedBox(height: 16),
                    _buildInputField(
                      'Phone Number', 
                      phoneController, 
                      Icons.phone_android_outlined, 
                      focusNode: _phoneFocusNode,
                      keyboardType: TextInputType.phone
                    ),
                    SizedBox(height: 16),
                    _buildDateField('Date of Birth', dob, Icons.cake_outlined, (picked) => setState(() => dob = picked), isPastOnly: true),
                    SizedBox(height: 16),
                    _buildInputField(
                      'Place', 
                      placeController, 
                      Icons.location_on_outlined,
                      focusNode: _placeFocusNode,
                    ),
                    SizedBox(height: 16),
                    _buildDateField('Appointment Date', appointmentDate, Icons.calendar_today_outlined, (picked) => setState(() => appointmentDate = picked), isPastOnly: false),
                    
                    // Available Days Info
                    if (availableDays.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.green[600], size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Doctor is available on: ${availableDays.join(', ')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          
          // Book Button with loading state
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: _isSubmitting
                  ? _buildLoadingButton()
                  : _buildBookButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return ElevatedButton(
      onPressed: _handleBooking,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Text(
        'CONFIRM BOOKING',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoadingButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'BOOKING...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingsPreview() {
    final availableDays = widget.doctor.consulting.where((day) => day.sessions.isNotEmpty).toList();
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Available Days & Timings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (availableDays.isNotEmpty)
            Column(
              children: availableDays.map((day) {
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.calendar_today, color: Colors.green, size: 18),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              day.day,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                            if (day.sessions.isNotEmpty)
                              ...day.sessions.map((session) {
                                return Text(
                                  '${session.startTime} - ${session.endTime}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            )
          else
            Text(
              'No available timings',
              style: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      enabled: !_isSubmitting, // Disable fields when submitting
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, IconData icon, Function(DateTime) onPicked, {required bool isPastOnly}) {
    return InkWell(
      onTap: _isSubmitting ? null : () async {
        final now = DateTime.now();
        final firstDate = isPastOnly ? DateTime(1900) : now;
        final lastDate = isPastOnly ? now : DateTime(now.year + 1);
        
        try {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? now,
            firstDate: firstDate,
            lastDate: lastDate,
            selectableDayPredicate: isPastOnly ? null : _isDateEnabled,
          );
          
          if (picked != null) {
            print("✅ Date selected: ${picked.day}/${picked.month}/${picked.year}");
            setState(() => onPicked(picked));
          } else {
            print("❌ Date selection cancelled");
          }
        } catch (e) {
          print("❌ Error in date picker: $e");
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? now,
            firstDate: firstDate,
            lastDate: lastDate,
          );
          if (picked != null) {
            setState(() => onPicked(picked));
          }
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[500]),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.green),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date == null ? "Select Date" : "${date.day}/${date.month}/${date.year}",
              style: TextStyle(
                fontSize: 14, 
                color: date == null ? Colors.grey[400] : Colors.grey[800]
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}