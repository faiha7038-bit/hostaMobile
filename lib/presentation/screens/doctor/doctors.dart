import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:hosta/presentation/screens/booking/register_booking.dart';
import 'package:hosta/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
log("responseofdoctor${response.data}");
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
                decoration: InputDecoration(hintText: 'Search doctors ', hintStyle: TextStyle(color: Colors.grey[500]), border: InputBorder.none),
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
         // Text('Try adjusting your search', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
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
    ? () async {
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString('userId') ?? '';

        if (userId.isEmpty) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Login Required",style: TextStyle(color: Colors.green),),
              content: const Text(
                "Please login to book an appointment.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Signin(),
                      ),
                    );
                  },
                  child: const Text(
                    "Login",
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ],
            ),
          );
          return;
        }

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

}