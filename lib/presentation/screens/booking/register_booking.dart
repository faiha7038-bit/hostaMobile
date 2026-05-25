import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:hosta/data/models/doctor_model.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:hosta/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterBooking extends StatefulWidget {
  final Doctor doctor;
  const RegisterBooking({super.key, required this.doctor});

  @override
  State<RegisterBooking> createState() => _RegisterBookingState();
}

class _RegisterBookingState extends State<RegisterBooking> {
  final TextEditingController patientNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController placeController = TextEditingController();
  DateTime? dob;
  DateTime? appointmentDate;
  String? selectedTimeSlot;
  bool _isSubmitting = false;
  final _formKey = GlobalKey<FormState>();

  List<String> get availableTimeSlots {
    List<String> slots = [];
    if (widget.doctor.consulting.morningSession != null) {
      slots.add(widget.doctor.consulting.morningSession!.range);
    }
    if (widget.doctor.consulting.eveningSession != null) {
      slots.add(widget.doctor.consulting.eveningSession!.range);
    }
    if (widget.doctor.outDoorConsulting != null) {
      slots.add(widget.doctor.outDoorConsulting!.time.range);
    }
    return slots;
  }

  @override
  void initState() {
    super.initState();
    if (availableTimeSlots.isNotEmpty) {
      selectedTimeSlot = availableTimeSlots.first;
    }
  }

  Future<void> _selectDate(BuildContext context, bool isPastOnly) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isPastOnly ? (dob ?? DateTime(2000)) : (appointmentDate ?? now),
      firstDate: isPastOnly ? DateTime(1900) : now,
      lastDate: isPastOnly ? now : now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.green, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isPastOnly) dob = picked;
        else appointmentDate = picked;
      });
    }
  }

  String formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<void> _handleBooking() async {
    if (_isSubmitting) return;

    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString('userId');
    if (storedUserId == null || storedUserId.isEmpty) {
      _showLoginDialog();
      return;
    }

    // if (patientNameController.text.isEmpty ||
    //     phoneController.text.isEmpty ||
    //     placeController.text.isEmpty ||
    //     dob == null ||
    //     appointmentDate == null) {
    //   showTopSnackBar(context, 'Please fill all required fields', isError: true);
    //   return;
    // }
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
    // if (availableTimeSlots.isNotEmpty && selectedTimeSlot == null) {
    //   showTopSnackBar(context, 'Please select a time slot', isError: true);
    //   return;
    // }

    setState(() => _isSubmitting = true);

    final bookingData = {
      'userId': int.parse(storedUserId),
      'patient_dob': formatDate(dob!),
      'patient_name': patientNameController.text,
      'patient_place': placeController.text,
      'patient_phone': phoneController.text,
      'hospitalId': int.parse(widget.doctor.hospitalId.toString()),
      'doctorId': int.parse(widget.doctor.id.toString()),
      'booking_date': formatDate(appointmentDate!),
      'department': widget.doctor.specialty,
      'displayName': widget.doctor.name,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    try {
      final apiService = ApiService();
      final response = await apiService.createBooking(bookingData);

      if (mounted && Navigator.canPop(context)) Navigator.pop(context); // close loader

      if (response.statusCode == 201 || response.data['success'] == true) {
        if (mounted) {
          showTopSnackBar(context, '✅ Booking successful! Appointment confirmed with Dr. ${widget.doctor.name}');
          Navigator.pop(context); // close booking screen
        }
      } else {
        if (mounted) showTopSnackBar(context, response.data['message'] ?? 'Booking failed', isError: true);
      }
    } on DioException catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      String errorMsg = "Booking failed";
      if (e.response?.data is Map) errorMsg = e.response?.data['message'] ?? errorMsg;
      if (mounted) showTopSnackBar(context, errorMsg, isError: true);
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) showTopSnackBar(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign In Required', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Please sign in to book appointments and access all features.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const Signin()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Sign In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
     appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Book Appointment", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green[50],
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Text(widget.doctor.name.isNotEmpty ? widget.doctor.name[0].toUpperCase() : 'D', style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(' ${widget.doctor.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(widget.doctor.specialty, style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTextField(controller: patientNameController, label: 'Patient Name', icon: Icons.person),
                    const SizedBox(height: 16),
                    _buildTextField(controller: phoneController, label: 'Phone Number', icon: Icons.phone, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildDateField(label: 'Date of Birth', value: dob, onTap: () => _selectDate(context, true)),
                    const SizedBox(height: 16),
                    _buildTextField(controller: placeController, label: 'Place', icon: Icons.location_on),
                    const SizedBox(height: 16),
                    _buildDateField(label: 'Appointment Date', value: appointmentDate, onTap: () => _selectDate(context, false)),
                    // if (availableTimeSlots.isNotEmpty) ...[
                    //   const SizedBox(height: 16),
                    //   DropdownButtonFormField<String>(
                    //     value: selectedTimeSlot,
                    //     hint: const Text('Select Time Slot'),
                    //     decoration: InputDecoration(
                    //       labelText: 'Consulting Time',
                    //       prefixIcon: const Icon(Icons.access_time, color: Colors.green),
                    //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    //     ),
                    //     items: availableTimeSlots.map((slot) => DropdownMenuItem(value: slot, child: Text(slot))).toList(),
                    //     onChanged: (value) => setState(() => selectedTimeSlot = value),
                    //   ),
                    // ],
                    if (widget.doctor.consulting.getAvailableSlots().isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Available Timings:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...widget.doctor.consulting.getAvailableSlots().map(
                              (slot) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• ${slot.title}: ${slot.time}')),
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
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('CONFIRM BOOKING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text}) {
  //   return TextField(
  //     controller: controller,
  //     keyboardType: keyboardType,
  //     decoration: InputDecoration(
  //       labelText: label,
  //       prefixIcon: Icon(icon, color: Colors.green),
  //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  //       focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green)),
  //     ),
  //   );
  // }
Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    validator: (value) {
      if (value == null || value.trim().isEmpty) {
        return '$label is required';
      }

      // Phone validation
      if (label == 'Phone Number') {
        if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
          return 'Enter valid 10 digit phone number';
          
        }
        
      }

      // Patient name validation
      if (label == 'Patient Name') {
        if (value.trim().length < 3) {
          return 'Name must be at least 3 characters';
        }
      }

      return null;
    },
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.green),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    ),
  );
}
  Widget _buildDateField({required String label, required DateTime? value, required VoidCallback onTap}) {
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
            Text(value == null ? "Select Date" : "${value.day}/${value.month}/${value.year}", style: TextStyle(color: value == null ? Colors.grey : Colors.black)),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}