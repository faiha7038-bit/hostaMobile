import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/presentation/screens/booking/register_booking.dart';
import 'package:hosta/services/api_service.dart';
import '../../screens/doctor/doctor_detail.dart';
import '../../../data/models/doctor_model.dart';

class Doctors extends ConsumerStatefulWidget {
  final String hospitalId;
  final String specialty;

  const Doctors({super.key, required this.hospitalId, required this.specialty});

  @override
  ConsumerState<Doctors> createState() => _DoctorsState();
}

class _DoctorsState extends ConsumerState<Doctors> {
  String searchQuery = '';
  List<Doctor> doctors = [];
  bool isLoading = true;
  String? errorMessage;
 Timer? _debounceTimer;
 final ScrollController _scrollController = ScrollController();

int currentPage = 1;
bool hasNextPage = true;
bool isPaginationLoading = false;
  @override
 @override
void initState() {
  super.initState();

  _fetchDoctors();

  _scrollController.addListener(() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isPaginationLoading &&
        hasNextPage) {
      _fetchDoctors(loadMore: true);
    }
  });
}
    @override

void dispose() {
  _debounceTimer?.cancel();
  _scrollController.dispose();
  super.dispose();
}
  void _onSearchChanged(String value) {
    setState(() => searchQuery = value);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      doctors.clear();
currentPage = 1;
hasNextPage = true;
      _fetchDoctors(search: value.isEmpty ? null : value);
    });
  }
  Future<void> _fetchDoctors({
  String? search,
  bool loadMore = false,
}) async {
   if (isPaginationLoading) return;
  if (!mounted) return;

  try {
    if (loadMore) {
      setState(() {
        isPaginationLoading = true;
      });
    } else {
      setState(() {
        isLoading = true;
        errorMessage = null;
        currentPage = 1;
      });
    }

    final response = await ApiService().getDoctors(
      hospitalId: widget.hospitalId,
      speciality: widget.specialty,
      searchQuery: search,
      page: currentPage,
      limit: 10,
    );

    if (!mounted) return;

    if (response.data['success'] == true) {
      final doctorsData = response.data['data'];

      final pagination = response.data['pagination'];

      final List<Doctor> newDoctors =
          doctorsData.map<Doctor>((e) => Doctor.fromJson(e)).toList();

      setState(() {
        if (loadMore) {
          doctors.addAll(newDoctors);
        } else {
          doctors = newDoctors;
        }

        hasNextPage = pagination['hasNextPage'] ?? false;

        if (hasNextPage) {
          currentPage++;
        }

        isLoading = false;
        isPaginationLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      errorMessage = e.toString();
      isLoading = false;
      isPaginationLoading = false;
    });
  }
}
//  Future<void> _fetchDoctors({String? search, bool loadMore = false,}) async {
//     if (!mounted) return;
//     try {
//       setState(() {
//         isLoading = true;
//         errorMessage = null;
//       });
//       final response = await ApiService().getDoctors(
//         hospitalId: widget.hospitalId,
//         speciality: widget.specialty,
//         searchQuery: search,   // ✅ use the search parameter
//       );
//       if (!mounted) return;
//       if (response.data['success'] == true && response.data['data'] != null) {
//         final doctorsData = response.data['data'];
//         if (doctorsData is List) {
//           setState(() {
//             doctors = doctorsData.map((json) => Doctor.fromJson(json)).toList();
//             isLoading = false;
//           });
//         } else {
//           setState(() {
//             errorMessage = 'Invalid data format';
//             isLoading = false;
//           });
//         }
//       } else {
//         setState(() {
//           errorMessage = response.data['message'] ?? 'Failed to load doctors';
//           isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Error loading doctors: $e';
//         isLoading = false;
//       });
//     }
//   }

  // List<Doctor> get filteredDoctors {
  //   if (searchQuery.isEmpty) return doctors;
  //   return doctors.where((doctor) =>
  //     doctor.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
  //     doctor.specialty.toLowerCase().contains(searchQuery.toLowerCase()) ||
  //     (doctor.hospitalName?.toLowerCase() ?? '').contains(searchQuery.toLowerCase())
  //   ).toList();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text("Doctors", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Navigator.pop(context)),
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
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search_rounded, color: Colors.grey[500], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                  onChanged: _onSearchChanged,
                // onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(hintText: 'Search doctors by name or specialty...', hintStyle: TextStyle(color: Colors.grey[500]), border: InputBorder.none),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget _buildContent() {
  if (isLoading) return const Center(child: CircularProgressIndicator(color: Colors.green));
  if (errorMessage != null) { /* error widget unchanged */ }
  
  // No doctors at all (initial load, no search query)
  if (doctors.isEmpty && searchQuery.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_services, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text('No Doctors found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[700])),
        ],
      ),
    );
  }
  
  // No results for the search
  if (doctors.isEmpty && searchQuery.isNotEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medical_information, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text('No doctors found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Try adjusting your search', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }
  
  // Display doctors from API (already filtered)
  return Padding(
    padding: const EdgeInsets.all(16),
    child: GridView.builder(
      controller: _scrollController,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
    itemCount: doctors.length + (isPaginationLoading ? 1 : 0),  
      itemBuilder: (context, index) {

  if (index == doctors.length) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
    );
  }

  return _buildDoctorCard(doctors[index]);
},
    ),
  );
}

  Widget _buildDoctorCard(Doctor doctor) {
    String firstLetter = doctor.displayName.isNotEmpty ? doctor.displayName[0].toUpperCase() : (doctor.firstName.isNotEmpty ? doctor.firstName[0].toUpperCase() : 'D');
    String consultationInfo = "";
    if (doctor.outDoorConsulting != null) {
      consultationInfo = "🏥 ${doctor.outDoorConsulting!.place}";
    } else if (doctor.consulting.morningSession != null || doctor.consulting.eveningSession != null) {
      consultationInfo = "⏰ Available Today";
    } else {
      consultationInfo = "Consultation Available";
    }
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctor: doctor))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(width: 45, height: 45, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: Center(child: Text(firstLetter, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doctor.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text(doctor.specialty, style: TextStyle(fontSize: 11, color: Colors.green[600], fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(doctor.qualification, style: TextStyle(fontSize: 10, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.currency_rupee, size: 12, color: Colors.grey),
                  const SizedBox(width: 2),
                  Text(doctor.fees, style: TextStyle(fontSize: 12, color: Colors.green[600], fontWeight: FontWeight.w600)),
                  const Text(" fee", style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            if (consultationInfo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Text(consultationInfo, style: TextStyle(fontSize: 9, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            const Spacer(),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              child: ElevatedButton(
                 onPressed: doctor.bookingOpen
      ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegisterBooking(
                doctor: doctor,
              ),
            ),
          );
        }
      : null,

                style: ElevatedButton.styleFrom(
                  backgroundColor: doctor.bookingOpen ? Colors.green : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(doctor.bookingOpen ? 'BOOK NOW' : 'CLOSED', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

// void _showBookingSheet(Doctor doctor) {
//   if (!doctor.bookingOpen) {
//     showTopSnackBar(
//       context,
//       'Booking is currently closed for Dr. ${doctor.name}',
//       isError: true,
//     );
//     return;
//   }

//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (_) => RegisterBooking(
//         doctor: doctor,
//       ),
//     ),
//   );
// }

  // Future<void> _handleBooking(
  //   BuildContext context,
  //   Doctor doctor,
  //   String patientName,
  //   String patientPhone,
  //   String patientPlace,
  //   DateTime? patientDob,
  //   DateTime? appointmentDate,
  //   String? selectedTimeSlot,
  // ) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final storedUserId = prefs.getString('userId');
  //   if (storedUserId == null || storedUserId.isEmpty) {
  //     _showLoginDialog(context);
  //     return;
  //   }
  //   if (patientName.isEmpty || patientPhone.isEmpty || patientPlace.isEmpty || patientDob == null || appointmentDate == null) {
  //     showTopSnackBar(context, 'Please fill all required fields', isError: true);
  //     return;
  //   }
  //   String formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  //   final bookingData = {
  //     'userId': int.parse(storedUserId),
  //     'patient_dob': formatDate(patientDob),
  //     'patient_name': patientName,
  //     'patient_place': patientPlace,
  //     'patient_phone': patientPhone,
  //     'hospitalId': int.parse(doctor.hospitalId.toString()),
  //     'doctorId': int.parse(doctor.id.toString()),
  //     'booking_date': formatDate(appointmentDate),
  //     'department': doctor.specialty,
  //     'displayName': doctor.name,
  //   };
  //   print("BOOKING DATA = $bookingData");
  //   showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.green)));
  //   try {
  //     final apiService = ApiService();
  //     final response = await apiService.createBooking(bookingData);
  //     if (Navigator.canPop(context)) Navigator.pop(context);
  //     if (response.statusCode == 201 || response.data['success'] == true) {
  //       showTopSnackBar(context, '✅ Booking successful! Appointment confirmed with Dr. ${doctor.name}');
  //       Navigator.pop(context);
  //     } else {
  //       showTopSnackBar(context, response.data['message'] ?? 'Booking failed', isError: true);
  //     }
  //   } on DioException catch (e) {
  //     if (Navigator.canPop(context)) Navigator.pop(context);
  //     String errorMsg = "Booking failed";  // <-- FIXED incomplete line
  //     if (e.response?.data is Map) errorMsg = e.response?.data['message'] ?? errorMsg;
  //     showTopSnackBar(context, errorMsg, isError: true);
  //   } catch (e) {
  //     if (Navigator.canPop(context)) Navigator.pop(context);
  //     showTopSnackBar(context, 'Error: $e', isError: true);
  //   }
  // }

  // void _showLoginDialog(BuildContext context) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //       title: const Text('Sign In Required', style: TextStyle(fontWeight: FontWeight.bold)),
  //       content: const Text('Please sign in to book appointments and access all features.'),
  //       actions: [
  //         TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             Navigator.push(context, MaterialPageRoute(builder: (_) => const Signin()));
  //           },
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
  //           child: const Text('Sign In', style: TextStyle(color: Colors.white)),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

// ====================== BookingForm (fixed) ======================
// class BookingForm extends StatefulWidget {
//   final Doctor doctor;
//   final Function(
//     BuildContext context,
//     Doctor doctor,
//     String patientName,
//     String patientPhone,
//     String patientPlace,
//     DateTime? patientDob,
//     DateTime? appointmentDate,
//     String? selectedTimeSlot,
//   ) onBooking;

//   const BookingForm({super.key, required this.doctor, required this.onBooking});

//   @override
//   State<BookingForm> createState() => _BookingFormState();
// }

// class _BookingFormState extends State<BookingForm> {
//   final TextEditingController patientNameController = TextEditingController();
//   final TextEditingController phoneController = TextEditingController();
//   final TextEditingController placeController = TextEditingController();
//   DateTime? dob;
//   DateTime? appointmentDate;
//   String? selectedTimeSlot;
//   bool _isSubmitting = false;

//   List<String> get availableTimeSlots {
//     List<String> slots = [];
//     if (widget.doctor.consulting.morningSession != null) slots.add(widget.doctor.consulting.morningSession!.range);
//     if (widget.doctor.consulting.eveningSession != null) slots.add(widget.doctor.consulting.eveningSession!.range);
//     if (widget.doctor.outDoorConsulting != null) slots.add(widget.doctor.outDoorConsulting!.time.range);
//     return slots;
//   }

//   @override
//   void initState() {
//     super.initState();
//     if (availableTimeSlots.isNotEmpty) {
//       selectedTimeSlot = availableTimeSlots.first;
//     }
//   }

//   Future<void> _selectDate(BuildContext context, bool isPastOnly) async {
//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: isPastOnly ? (dob ?? DateTime(2000)) : (appointmentDate ?? now),
//       firstDate: isPastOnly ? DateTime(1900) : now,
//       lastDate: isPastOnly ? now : now.add(const Duration(days: 365)),
//       builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.green, onPrimary: Colors.white)), child: child!),
//     );
//     if (picked != null) {
//       setState(() {
//         if (isPastOnly) dob = picked;
//         else appointmentDate = picked;
//       });
//     }
//   }

//   Future<void> _handleBooking() async {
//     if (_isSubmitting) return;
//     if (availableTimeSlots.isNotEmpty && selectedTimeSlot == null) {
//       showTopSnackBar(context, 'Please select a time slot', isError: true);
//       return;
//     }
//     setState(() => _isSubmitting = true);
//     try {
//       await widget.onBooking(
//         context,
//         widget.doctor,
//         patientNameController.text,
//         phoneController.text,
//         placeController.text,
//         dob,
//         appointmentDate,
//         selectedTimeSlot,
//       );
//     } finally {
//       if (mounted) setState(() => _isSubmitting = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: MediaQuery.of(context).size.height * 0.8,
//       decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(color: Colors.green[50], borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
//             child: Row(
//               children: [
//                 CircleAvatar(backgroundColor: Colors.green, child: Text(widget.doctor.name.isNotEmpty ? widget.doctor.name[0].toUpperCase() : 'D', style: const TextStyle(color: Colors.white))),
//                 const SizedBox(width: 12),
//                 Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Book Appointment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text('Dr. ${widget.doctor.name}', style: TextStyle(color: Colors.grey[600]))])),
//                 IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
//               ],
//             ),
//           ),
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 children: [
//                   _buildTextField(controller: patientNameController, label: 'Patient Name', icon: Icons.person),
//                   const SizedBox(height: 16),
//                   _buildTextField(controller: phoneController, label: 'Phone Number', icon: Icons.phone, keyboardType: TextInputType.phone),
//                   const SizedBox(height: 16),
//                   _buildDateField(label: 'Date of Birth', value: dob, onTap: () => _selectDate(context, true)),
//                   const SizedBox(height: 16),
//                   _buildTextField(controller: placeController, label: 'Place', icon: Icons.location_on),
//                   const SizedBox(height: 16),
//                   _buildDateField(label: 'Appointment Date', value: appointmentDate, onTap: () => _selectDate(context, false)),
//                   if (availableTimeSlots.isNotEmpty) ...[
//                     const SizedBox(height: 16),
//                     DropdownButtonFormField<String>(
//                       value: selectedTimeSlot,
//                       hint: const Text('Select Time Slot'),
//                       decoration: InputDecoration(
//                         labelText: 'Consulting Time',
//                         prefixIcon: const Icon(Icons.access_time, color: Colors.green),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                       ),
//                       items: availableTimeSlots.map((slot) => DropdownMenuItem(value: slot, child: Text(slot))).toList(),
//                       onChanged: (value) => setState(() => selectedTimeSlot = value),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.all(20),
//             child: SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                onPressed:widget. doctor.bookingOpen
//     ? () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => RegisterBooking(
//               doctor:widget. doctor,
//             ),
//           ),
//         );
//       }
//     : null,
//                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
//                 child: _isSubmitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('CONFIRM BOOKING', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text}) {
//     return TextField(
//       controller: controller,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon, color: Colors.green),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green)),
//       ),
//     );
//   }

//   Widget _buildDateField({required String label, required DateTime? value, required VoidCallback onTap}) {
//     return InkWell(
//       onTap: onTap,
//       child: InputDecorator(
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: Icon(Icons.calendar_today, color: Colors.green),
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(value == null ? "Select Date" : "${value.day}/${value.month}/${value.year}", style: TextStyle(color: value == null ? Colors.grey : Colors.black)),
//             const Icon(Icons.arrow_drop_down, color: Colors.grey),
//           ],
//         ),
//       ),
//     );
//   }
// }