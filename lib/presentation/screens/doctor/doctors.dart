import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:hosta/data/models/doctor_model.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:hosta/presentation/screens/doctor/doctor_detail.dart';
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
  List<Doctor> doctors = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    // Add mounted check
    if (!mounted) return;

    try {
      print("🔵 Calling API with ID: ${widget.hospitalId}");
      print("🔵 Specialty: ${widget.specialty}");

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await ApiService().getDoctors(
        hospitalId: widget.hospitalId,
        speciality: widget.specialty,
      );

      if (!mounted) return;

      print("📡 API Response: ${response.data}");

      if (response.data['success'] == true && response.data['data'] != null) {
        final doctorsData = response.data['data'];

        if (doctorsData is List) {
          if (mounted) {
            setState(() {
              doctors = doctorsData
                  .map((doctorJson) => Doctor.fromJson(doctorJson))
                  .toList();
              isLoading = false;
            });
          }
          print("✅ Loaded ${doctors.length} doctors");
        } else {
          if (mounted) {
            setState(() {
              errorMessage = 'Invalid data format';
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = response.data['message'] ?? 'Failed to load doctors';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("❌ Error: $e");
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading doctors: $e';
          isLoading = false;
        });
      }
    }
  }

  List<Doctor> get filteredDoctors {
    if (searchQuery.isEmpty) return doctors;

    return doctors.where((doctor) {
      final name = doctor.name.toLowerCase();
      final specialty = doctor.specialty.toLowerCase();
      final hospitalName = doctor.hospitalName?.toLowerCase() ?? '';
      //   final department = doctor.department.toLowerCase();

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
        title: const Text(
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
        bottom: false,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search_rounded, color: Colors.grey[500], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search doctors by name or specialty...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildContent() {
  if (isLoading) return const Center(child: CircularProgressIndicator(color: Colors.green));
  if (errorMessage != null) { /* error UI */ }

  // 🔥 No doctors for this specialty at all (API returned empty list)
  if (doctors.isEmpty && searchQuery.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text('No specialty found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text('This hospital does not have ${widget.specialty} doctors.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.all(16),
    child: GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: filteredDoctors.length,
      itemBuilder: (context, index) => _buildDoctorCard(filteredDoctors[index]),
    ),
  );
}

  // Widget _buildContent() {
  //   if (isLoading) {
  //     return const Center(
  //       child: CircularProgressIndicator(color: Colors.green),
  //     );
  //   }

  //   if (errorMessage != null) {
  //     return Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
  //           const SizedBox(height: 16),
  //           Text(
  //             errorMessage!,
  //             style: TextStyle(color: Colors.grey[600]),
  //             textAlign: TextAlign.center,
  //           ),
  //           const SizedBox(height: 20),
  //           ElevatedButton(
  //             onPressed: _fetchDoctors,
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.green,
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //             ),
  //             child: const Text(
  //               'Try Again',
  //               style: TextStyle(color: Colors.white),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }

  //   if (filteredDoctors.isEmpty) {
  //     return Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Icon(Icons.medical_information, size: 80, color: Colors.grey[300]),
  //           const SizedBox(height: 20),
  //           Text(
  //             'No doctors found',
  //             style: TextStyle(fontSize: 18, color: Colors.grey[600]),
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             'Try adjusting your search',
  //             style: TextStyle(fontSize: 14, color: Colors.grey[500]),
  //           ),
  //         ],
  //       ),
  //     );
  //   }

  //   return Padding(
  //     padding: const EdgeInsets.all(16),
  //     child: GridView.builder(
  //       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
  //         crossAxisCount: 2,
  //         mainAxisSpacing: 16,
  //         crossAxisSpacing: 16,
  //         childAspectRatio: 0.75,
  //       ),
  //       itemCount: filteredDoctors.length,
  //       itemBuilder: (context, index) {
  //         final doctor = filteredDoctors[index];
  //         return _buildDoctorCard(doctor);
  //       },
  //     ),
  //   );
  // }

  Widget _buildDoctorCard(Doctor doctor) {
    String firstLetter = doctor.displayName.isNotEmpty
        ? doctor.displayName[0].toUpperCase()
        : doctor.firstName.isNotEmpty
        ? doctor.firstName[0].toUpperCase()
        : 'D';

    // Get consultation info
    String consultationInfo = "";
    if (doctor.outDoorConsulting != null) {
      consultationInfo = "🏥 ${doctor.outDoorConsulting!.place}";
    } else if (doctor.consulting.morningSession != null ||
        doctor.consulting.eveningSession != null) {
      consultationInfo = "⏰ Available Today";
    } else {
      consultationInfo = "Consultation Available";
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorDetailScreen(doctor: doctor),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Header with Avatar
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        firstLetter,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
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

            // Qualification
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                doctor.qualification,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Fees
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  const Icon(
                    Icons.currency_rupee,
                    size: 12,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    doctor.fees,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    " fee",
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Consultation info
            if (consultationInfo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                child: Text(
                  consultationInfo,
                  style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            const Spacer(),

            // Book Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: doctor.bookingOpen
                    ? () => _showBookingSheet(doctor)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: doctor.bookingOpen
                      ? Colors.green
                      : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  doctor.bookingOpen ? 'BOOK NOW' : 'CLOSED',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingSheet(Doctor doctor) {
    if (!doctor.bookingOpen) {
      showTopSnackBar(
        context,
        'Booking is currently closed for Dr. ${doctor.name}',
        isError: true,
      );
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

    if (patientName.isEmpty ||
        patientPhone.isEmpty ||
        patientPlace.isEmpty ||
        patientDob == null ||
        appointmentDate == null) {
      showTopSnackBar(
        context,
        'Please fill all required fields',
        isError: true,
      );
      return;
    }

    final bookingData = {
      'userId': storedUserId,
      'specialty': doctor.specialty,
      'doctor_id': doctor.id.toString(),
      'doctor_name': doctor.name,
      'booking_date': appointmentDate.toIso8601String(),
      'patient_name': patientName,
      'patient_phone': patientPhone,
      'patient_place': patientPlace,
      'patient_dob': patientDob.toIso8601String(),
    };

    try {
      final response = await ApiService().createBooking(
        doctor.hospitalId.toString(),
        bookingData,
      );

      if (response.statusCode == 201 ||
          response.data['status'] == 201 ||
          response.data['success'] == true) {
        showTopSnackBar(
          context,
          'Appointment booked successfully with Dr. ${doctor.name}!',
        );
        Navigator.pop(context); // Close booking form
      } else {
        showTopSnackBar(
          context,
          response.data['message'] ?? 'Booking failed',
          isError: true,
        );
      }
    } on DioException catch (dioError) {
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

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sign In Required',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Please sign in to book appointments and access all features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Sign In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// BookingForm class remains the same as before
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
  )
  onBooking;

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
  bool _isSubmitting = false;

  Future<void> _selectDate(BuildContext context, bool isPastOnly) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isPastOnly
          ? (dob ?? DateTime(2000))
          : (appointmentDate ?? now),
      firstDate: isPastOnly ? DateTime(1900) : now,
      lastDate: isPastOnly ? now : now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isPastOnly) {
          dob = picked;
        } else {
          appointmentDate = picked;
        }
      });
    }
  }

  Future<void> _handleBooking() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(
                    widget.doctor.name.isNotEmpty
                        ? widget.doctor.name[0].toUpperCase()
                        : 'D',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Book Appointment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Dr. ${widget.doctor.name}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Form Fields
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildTextField(
                    controller: patientNameController,
                    label: 'Patient Name',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(
                    label: 'Date of Birth',
                    value: dob,
                    onTap: () => _selectDate(context, true),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: placeController,
                    label: 'Place',
                    icon: Icons.location_on,
                  ),
                  const SizedBox(height: 16),
                  _buildDateField(
                    label: 'Appointment Date',
                    value: appointmentDate,
                    onTap: () => _selectDate(context, false),
                  ),

                  // Show available timings if available
                  if (widget.doctor.consulting
                      .getAvailableSlots()
                      .isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Available Timings:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...widget.doctor.consulting.getAvailableSlots().map(
                            (slot) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('• ${slot.title}: ${slot.time}'),
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

          // Submit Button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'CONFIRM BOOKING',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.calendar_today, color: Colors.green),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
