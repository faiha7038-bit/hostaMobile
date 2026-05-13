import 'package:flutter/material.dart';
import 'package:hosta/data/models/doctor_model.dart';
import 'package:hosta/common/top_snackbar.dart';
import '../../../services/api_service.dart';

class DoctorDetailScreen extends StatefulWidget {
  final Doctor doctor; // Doctor object received from previous screen
  
  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  bool isLoading = false;
  Doctor? doctorDetails;
  String? errorMessage;
  
  int appointmentCount = 0;
  double rating = 4.5;
  int reviewCount = 38;

  List<Map<String, dynamic>> reviews = [
    {"name": "Rahul", "stars": 5, "comment": "Very friendly doctor"},
    {"name": "Anjali", "stars": 4, "comment": "Good experience"},
  ];

  @override
  void initState() {
    super.initState();
    // Use the doctor passed from previous screen
    doctorDetails = widget.doctor;
    _fetchDoctorDetails();
  }
  
  Future<void> _fetchDoctorDetails() async {
    if (doctorDetails != null) return; // Already have data
    
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      final response = await ApiService().getDoctorById(widget.doctor.id.toString());
      
      if (!mounted) return;
      
      print("📡 Doctor Details Response: ${response.data}");
      
      if (response.data['success'] == true && response.data['data'] != null) {
        setState(() {
          doctorDetails = Doctor.fromJson(response.data['data']);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response.data['message'] ?? 'Failed to load doctor details';
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching doctor details: $e");
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading doctor details';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text("Doctor Details"),
        ),
        body: const Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }
    
    if (errorMessage != null || doctorDetails == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          title: const Text("Doctor Details"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text(errorMessage ?? 'Doctor not found'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchDoctorDetails,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenWidth < 600;
    final isLandscape = screenWidth > screenHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        toolbarHeight: isSmallScreen ? 56 : 70,
        title: Text(
          "Doctor Details",
          style: TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 22,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isSmallScreen ? 12.0 : screenWidth * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER - Using real doctor data
            _doctorHeader(screenWidth, isLandscape),

            SizedBox(height: screenHeight * 0.025),

            /// HOSPITAL INFO
            _infoCard(
              icon: Icons.local_hospital,
              title: doctorDetails!.hospitalName ?? 'Hospital',
              subtitle: doctorDetails!.address.fullAddress,
              screenWidth: screenWidth,
            ),

            SizedBox(height: screenHeight * 0.015),

            /// CONSULTATION TYPE (Outdoor Consulting)
            if (doctorDetails!.outDoorConsulting != null)
              _infoCard(
                icon: Icons.location_on,
                title: "OUTDOOR CONSULTING",
                subtitle: doctorDetails!.outDoorConsulting!.place,
                screenWidth: screenWidth,
              ),

            SizedBox(height: screenHeight * 0.015),

            /// FEES - Using real fee data
            _feesCard(screenWidth),

            SizedBox(height: screenHeight * 0.025),

            /// TIMINGS
            Text(
              "Available Timings",
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: screenHeight * 0.012),

            /// Morning Session
            if (doctorDetails!.consulting.morningSession != null)
              _timingTile(
                "Morning Session", 
                doctorDetails!.consulting.morningSession!.range, 
                screenWidth
              ),
            
            /// Evening Session
            if (doctorDetails!.consulting.eveningSession != null)
              _timingTile(
                "Evening Session", 
                doctorDetails!.consulting.eveningSession!.range, 
                screenWidth
              ),
            
            /// Outdoor Consulting Timings
            if (doctorDetails!.outDoorConsulting != null)
              _timingTile(
                "Outdoor Consulting", 
                doctorDetails!.outDoorConsulting!.time.range, 
                screenWidth
              ),

            SizedBox(height: screenHeight * 0.025),

            /// ABOUT DOCTOR
            Text(
              "About Doctor",
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: screenHeight * 0.01),

            Text(
              "Dr. ${doctorDetails!.name} is a specialized ${doctorDetails!.specialty.toLowerCase()} with qualification ${doctorDetails!.qualification}. "
              "Experienced in ${doctorDetails!.department} department with expertise in ${doctorDetails!.specialist}.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: isSmallScreen ? 13 : 15,
              ),
            ),

            SizedBox(height: screenHeight * 0.025),

            /// LANGUAGES
            if (doctorDetails!.knowLanguages.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Languages Known",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Wrap(
                    spacing: 8,
                    children: doctorDetails!.knowLanguages.map((lang) => Chip(
                      label: Text(lang),
                      backgroundColor: Colors.green[50],
                    )).toList(),
                  ),
                  SizedBox(height: screenHeight * 0.025),
                ],
              ),

            /// REVIEWS
            Text(
              "Patient Reviews",
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: screenHeight * 0.012),

            ...reviews.map(
              (r) => _reviewTile(r["name"], r["stars"], r["comment"], screenWidth),
            ),

            SizedBox(height: screenHeight * 0.012),

            /// ADD REVIEW BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showReviewDialog(),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                ),
                child: const Text("Write a Review"),
              ),
            ),

            SizedBox(height: screenHeight * 0.03),

            /// BOOK BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: doctorDetails!.bookingOpen 
                    ? () => _showBookingSheet(doctorDetails!)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: doctorDetails!.bookingOpen ? Colors.green : Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                ),
                child: Text(
                  doctorDetails!.bookingOpen ? "BOOK APPOINTMENT" : "CLOSED",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doctorHeader(double screenWidth, bool isLandscape) {
    final isSmallScreen = screenWidth < 600;
    final avatarSize = isLandscape ? 50.0 : (isSmallScreen ? 60.0 : 80.0);
    final doctor = doctorDetails!;
    
    String firstLetter = doctor.displayName.isNotEmpty 
        ? doctor.displayName[0].toUpperCase() 
        : doctor.firstName[0].toUpperCase();
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: TextStyle(
                  fontSize: avatarSize / 2,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 12.0 : 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 16 : 20,
                  ),
                ),
                Text(
                  doctor.specialty,
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star, size: isSmallScreen ? 14 : 16, color: Colors.amber),
                    Text("$rating", style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                    Text(
                      " ($reviewCount)",
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${doctor.fees} Consultation Fee",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                    fontSize: isSmallScreen ? 11 : 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feesCard(double screenWidth) {
    final isSmallScreen = screenWidth < 600;
    final doctor = doctorDetails!;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(Icons.currency_rupee, color: Colors.green, size: isSmallScreen ? 20 : 24),
          const SizedBox(width: 10),
          Text(
            "Consultation Fee",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
          const Spacer(),
          Text(
            "₹${doctor.fees}",
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 16 : 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required double screenWidth,
  }) {
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: isSmallScreen ? 20 : 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timingTile(String title, String time, double screenWidth) {
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.access_time, size: isSmallScreen ? 16 : 18, color: Colors.green),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
          ),
          const Spacer(),
          Text(
            time,
            style: TextStyle(
              color: Colors.green,
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewTile(String name, int stars, String comment, double screenWidth) {
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(isSmallScreen ? 10.0 : 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(
                  stars,
                  (index) => Icon(
                    Icons.star,
                    size: isSmallScreen ? 12 : 14,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment,
            style: TextStyle(
              color: Colors.grey,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog() {
    final controller = TextEditingController();
    int stars = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Add Review"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            stars = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.star,
                            size: 28,
                            color: index < stars ? Colors.amber : Colors.grey[300],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Write your review",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;

                    setState(() {
                      reviews.add({
                        "name": "You",
                        "stars": stars,
                        "comment": controller.text,
                      });
                      reviewCount++;
                    });

                    Navigator.pop(context);
                  },
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  void _showBookingSheet(Doctor doctor) {
    // Navigate to booking screen or show bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        child: const Placeholder(), // Replace with your booking form
      ),
    );
  }
}