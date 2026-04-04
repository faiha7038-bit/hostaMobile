import 'package:flutter/material.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:hosta/presentation/screens/doctor/doctors.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../services/api_service.dart';

class HospitalDetailsPage extends StatefulWidget {
  final String hospitalId;
  final Map<String, dynamic> hospital;

  const HospitalDetailsPage({
    super.key, 
    required this.hospitalId,
    required this.hospital
  });

  @override
  State<HospitalDetailsPage> createState() => _HospitalDetailsPageState();
}

class _HospitalDetailsPageState extends State<HospitalDetailsPage> {
  late Map<String, dynamic> hospital;
  bool isLoading = true;
  bool isReviewLoading = false;
  double rating = 0;
  final TextEditingController reviewController = TextEditingController();
  
  // For editing reviews
  String? editingReviewId;
  double editingRating = 0;
  final TextEditingController editingReviewController = TextEditingController();
  
  // User authentication
  String? currentUserId;
  String? currentUserName;
  String? currentUserEmail;

  // Separate list for reviews
  List<dynamic> reviews = [];

  @override
  void initState() {
    super.initState();
    hospital = widget.hospital;
    _initializeUser();
    _loadInitialData();
  }

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserId = prefs.getString('userId');
      currentUserName = prefs.getString('userName');
      currentUserEmail = prefs.getString('userEmail');
    });
  }

  Future<void> _loadInitialData() async {
    try {
      print("🔄 Loading initial data for hospital ID: ${widget.hospitalId}");
      
      // Fetch hospital details
      await _fetchHospitalDetails();
      
      // Fetch reviews separately - THIS IS THE KEY FIX
      await _fetchHospitalReviews();
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error loading initial data: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchHospitalDetails() async {
    try {
      print("🏥 Fetching hospital details for ID: ${widget.hospitalId}");
      final response = await ApiService().getAHospitals(widget.hospitalId);
      setState(() {
        hospital = response.data;
      });
      print("✅ Hospital details fetched successfully");
    } catch (e) {
      print("❌ Error fetching hospital details: $e");
    }
  }

  // ========== REVIEW OPERATIONS ==========

  Future<void> _fetchHospitalReviews() async {
    try {
      print("📝 Fetching reviews for hospital ID: ${widget.hospitalId}");
      final response = await ApiService().getAHospitalsReview(widget.hospitalId);
      print('✅ Reviews API Response received: ${response.data}');
      
      // Handle the response based on your API structure
      if (response.data != null) {
        if (response.data is Map && response.data.containsKey("data")) {
          // If response is { "data": [...] }
          setState(() {
            reviews = response.data["data"] ?? [];
          });
        } else if (response.data is List) {
          // If response is directly the array [...]
          setState(() {
            reviews = response.data;
          });
        } else {
          // If response is something else
          setState(() {
            reviews = [];
          });
        }
      } else {
        setState(() {
          reviews = [];
        });
      }
      
      print('✅ Final reviews count: ${reviews.length}');
      print('✅ Reviews list: $reviews');
    } catch (e) {
      print("❌ Error fetching reviews: $e");
      setState(() {
        reviews = [];
      });
    }
  }

  Future<void> _createReview() async {
    // Check authentication first
    final isAuthenticated = await _checkAuthentication();
    if (!isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to submit a review")),
      );
      return;
    }

    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a rating")),
      );
      return;
    }

    if (reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write a review")),
      );
      return;
    }

    setState(() => isReviewLoading = true);

    try {
      final Map<String, dynamic> reviewData = {
        "userId": currentUserId!,
        "rating": rating,
        "comment": reviewController.text.trim(),
        "hospitalId": widget.hospitalId,
      };

      // Create temporary review for instant UI update
      final tempReview = {
        "_id": "temp_${DateTime.now().millisecondsSinceEpoch}",
        "userId": {
          "_id": currentUserId,
          "name": currentUserName ?? "You",
          "email": currentUserEmail ?? "",
        },
        "rating": rating,
        "comment": reviewController.text.trim(),
        "createdAt": DateTime.now().toIso8601String(),
        "isTemp": true,
        "isSubmitting": true,
      };

      // Add to UI instantly - SHOW SUBMITTING CARD IMMEDIATELY
      setState(() {
        reviews = [tempReview, ...reviews];
      });

      // Clear form immediately after adding to UI
      _clearReviewForm();

      // Call API with new endpoint
      await ApiService().createAHospitalReview(reviewData);
      
      // Refresh reviews from server to get actual data
      await _fetchHospitalReviews();
                  showTopSnackBar(context, "Review submitted successfully!");

      setState(() => isReviewLoading = false);

    } catch (e) {
      // If API call fails, remove the temporary review
      _removeTempReview();
      setState(() => isReviewLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting review: $e")),
      );
    }
  }

  Future<void> _updateReview(String reviewId) async {
    // Check authentication
    final isAuthenticated = await _checkAuthentication();
    if (!isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to update your review"), backgroundColor: Colors.green,),
      );
      return;
    }

    if (editingRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a rating"), backgroundColor: Colors.green,),
      );
      return;
    }

    if (editingReviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write a review"), backgroundColor: Colors.green,),
      );
      return;
    }

    setState(() => isReviewLoading = true);

    try {
      final Map<String, dynamic> reviewData = {
        "rating": editingRating,
        "comment": editingReviewController.text.trim(),
      };

      // Update UI instantly with optimistic update - SHOW UPDATING IMMEDIATELY
      setState(() {
        final reviewIndex = reviews.indexWhere((review) => review["_id"] == reviewId);
        if (reviewIndex != -1) {
          reviews[reviewIndex] = {
            ...reviews[reviewIndex],
            "rating": editingRating,
            "comment": editingReviewController.text.trim(),
            "isUpdating": true,
          };
        }
      });

      // Clear editing form immediately
      _cancelEdit();

      // Call API with new endpoint
      await ApiService().updateAHospitalReview(reviewId, reviewData);

      // Refresh reviews from server
      await _fetchHospitalReviews();

            showTopSnackBar(context, "Review updated successfully!");

      setState(() => isReviewLoading = false);

    } catch (e) {
      // If API call fails, refresh to get original data
      await _fetchHospitalReviews();
      setState(() => isReviewLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating review: $e")),
      );
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    // Check authentication
    final isAuthenticated = await _checkAuthentication();
    if (!isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to delete your review"), backgroundColor: Colors.green,),
      );
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Review"),
        content: const Text("Are you sure you want to delete this review?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isReviewLoading = true);

      // Store the review to restore if API fails
      final reviewToDeleteIndex = reviews.indexWhere((review) => review["_id"] == reviewId);
      if (reviewToDeleteIndex == -1) {
        setState(() => isReviewLoading = false);
        return;
      }
      
      final reviewToDelete = Map<String, dynamic>.from(reviews[reviewToDeleteIndex]);

      // Delete from UI instantly - REMOVE IMMEDIATELY
      setState(() {
        reviews = reviews.where((review) => review["_id"] != reviewId).toList();
      });

      try {
        // Call API with new endpoint
        await ApiService().deleteAHospitalReview(reviewId);


            showTopSnackBar(context, "Review deleted successfully!");


        setState(() => isReviewLoading = false);

      } catch (e) {
        // If API call fails, restore the review
        setState(() {
          reviews = [reviewToDelete, ...reviews];
        });
        setState(() => isReviewLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting review: $e"), backgroundColor: Colors.red,),
        );
      }
    }
  }

  void _removeTempReview() {
    setState(() {
      reviews = reviews.where((review) => review["isTemp"] != true).toList();
    });
  }

  void _clearReviewForm() {
    reviewController.clear();
    setState(() {
      rating = 0;
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // ========== AUTHENTICATION CHECK ==========
  
  Future<bool> _checkAuthentication() async {
    if (currentUserId != null) {
      return true;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Signin()),
    );
    
    if (result == true) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        currentUserId = prefs.getString('userId');
        currentUserName = prefs.getString('userName');
        currentUserEmail = prefs.getString('userEmail');
      });
      return currentUserId != null;
    }
    
    return false;
  }

  String _formatTime(String time24) {
    try {
      final parts = time24.split(":");
      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final suffix = hour >= 12 ? "PM" : "AM";
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return "$hour:${minute.toString().padLeft(2, '0')} $suffix";
    } catch (_) {
      return time24;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return dateString;
    }
  }

  void _startEditReview(Map<String, dynamic> review) async {
    final isAuthenticated = await _checkAuthentication();
    if (!isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to edit your review")),
      );
      return;
    }

    setState(() {
      editingReviewId = review["_id"];
      editingRating = (review["rating"] ?? 0).toDouble();
      editingReviewController.text = review["comment"] ?? "";
    });
  }

  void _cancelEdit() {
    setState(() {
      editingReviewId = null;
      editingRating = 0;
      editingReviewController.clear();
    });
  }

  // ========== NAVIGATION TO DOCTORS PAGE ==========
  
  void _navigateToDoctorsPage(String specialtyName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Doctors(
          hospitalId: widget.hospitalId,
          specialty: specialtyName,
        ),
      ),
    );
  }

  // ========== SAFE REVIEW DATA ACCESS METHODS ==========

  bool _isCurrentUserReview(Map<String, dynamic> review) {
    try {
      if (currentUserId == null) return false;
      if (review["userId"] == null) return false;
      
      final userData = review["userId"];
      final userId = userData["_id"]?.toString();
      return userId == currentUserId;
    } catch (e) {
      print("Error checking review ownership: $e");
      return false;
    }
  }

  String _getUserName(Map<String, dynamic> review) {
    try {
      if (review["userId"] == null) return "Anonymous";
      return review["userId"]["name"]?.toString() ?? "Anonymous";
    } catch (e) {
      print("Error getting user name: $e");
      return "Anonymous";
    }
  }

  String _getUserInitial(String userName) {
    try {
      if (userName.isEmpty) return "U";
      return userName[0].toUpperCase();
    } catch (e) {
      return "U";
    }
  }

  int _getRating(Map<String, dynamic> review) {
    try {
      return (review["rating"] ?? 0).toInt();
    } catch (e) {
      return 0;
    }
  }

  String _getComment(Map<String, dynamic> review) {
    try {
      return review["comment"]?.toString() ?? "";
    } catch (e) {
      return "";
    }
  }

  String _getReviewDate(Map<String, dynamic> review) {
    try {
      return review["createdAt"]?.toString() ?? "";
    } catch (e) {
      return "";
    }
  }

  bool _isTempReview(Map<String, dynamic> review) {
    try {
      return review["isTemp"] == true;
    } catch (e) {
      return false;
    }
  }

  bool _isSubmittingReview(Map<String, dynamic> review) {
    try {
      return review["isSubmitting"] == true;
    } catch (e) {
      return false;
    }
  }

  bool _isUpdatingReview(Map<String, dynamic> review) {
    try {
      return review["isUpdating"] == true;
    } catch (e) {
      return false;
    }
  }

  void _navigateToLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Signin()),
    );
    
    if (result == true) {
      await _initializeUser();
    }
  }

  // ========== MAP METHODS ==========

  String _getGoogleMapsUrl() {
    final lat = hospital["latitude"]?.toString() ?? "0";
    final lng = hospital["longitude"]?.toString() ?? "0";
    final name = hospital["name"] ?? "Hospital";
    final address = hospital["address"] ?? "";
    
    // Use Google Maps URL scheme that works on both iOS and Android
    if (address.isNotEmpty) {
      return "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('$name $address')}";
    } else {
      return "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    }
  }

  Future<void> _openMaps() async {
    final mapsUrl = _getGoogleMapsUrl();
    final uri = Uri.parse(mapsUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open maps")),
      );
    }
  }

  // ========== BUILD METHODS ==========

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    final imageUrl = hospital["image"]?["imageUrl"] ?? "";

    return DefaultTabController(
      length: 5,
      child: Scaffold(
       backgroundColor: const Color(0xFFECFDF5),

        body: SafeArea(
          child: Column(
            children: [
              // ===== Top Image =====
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(bottom: Radius.circular(20)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            height: 270,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'images/hospital.jpg',
                                height: 270,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            'images/hospital.jpg',
                            height: 270,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),

              // ===== Tabs =====
              const SizedBox(height: 8),
              const TabBar(
                isScrollable: true,
                labelColor: Colors.green,
                unselectedLabelColor: Colors.black,
                indicatorColor: Colors.green,
                labelStyle:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: "Information"),
                  Tab(text: "Specialties"),
                  Tab(text: "Working Hours"),
                  Tab(text: "Location"),
                  Tab(text: "Reviews"),
                ],
              ),

              // ===== Tab Views =====
              Expanded(
                child: TabBarView(
                  children: [
                    _buildInfoTab(hospital),
                    _buildSpecialtiesTab(hospital),
                    _buildHoursTab(hospital),
                    _buildLocationTab(),
                    _buildReviewsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== INFO TAB =====================
  Widget _buildInfoTab(Map<String, dynamic> hospital) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow(Icons.location_on, hospital["address"] ?? "No address provided"),
        _infoRow(Icons.phone, hospital["phone"] ?? "No phone number", onTap: () {
          if (hospital["phone"] != null) {
            _makePhoneCall(hospital["phone"]);
          }
        }),
        _infoRow(Icons.email, hospital["email"] ?? "No email provided"),
        _infoRow(Icons.medical_services, hospital["type"] ?? "Unknown type"),
        if (hospital["about"] != null && hospital["about"].isNotEmpty)
          _infoRow(Icons.info, hospital["about"]),
        if (hospital["emergencyContact"] != null && hospital["emergencyContact"] != "00000000")
          _infoRow(Icons.emergency, "Emergency: ${hospital["emergencyContact"]}", onTap: () {
            _makePhoneCall(hospital["emergencyContact"]);
          }),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.green, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== SPECIALTIES TAB =====================
  Widget _buildSpecialtiesTab(Map<String, dynamic> hospital) {
    final specialties = hospital["specialties"] as List? ?? [];
    
    if (specialties.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No specialties available",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: specialties.length,
      itemBuilder: (context, index) {
        final specialty = specialties[index];
        final specialtyName = specialty["name"] ?? "Unnamed Specialty";
        final doctorsCount = (specialty["doctors"] as List? ?? []).length;
        
        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _navigateToDoctorsPage(specialtyName),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          specialtyName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                            color: Color.fromARGB(255, 12, 94, 15),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                  
                  if (specialty["description"] != null && specialty["description"].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        specialty["description"],
                      ),
                    ),
                  
                  if (specialty["department_info"] != null && specialty["department_info"].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Department: ${specialty["department_info"]}",
                        style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                      ),
                    ),
                  
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.medical_services, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          "$doctorsCount doctors available",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "View Doctors",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===================== HOURS TAB =====================
  Widget _buildHoursTab(Map<String, dynamic> hospital) {
    final workingHoursClinic = hospital["working_hours_clinic"] as List?;
    final workingHours = hospital["working_hours"] as List?;

    if (workingHoursClinic != null && workingHoursClinic.isNotEmpty) {
      return _buildHoursTabNewFormat(workingHoursClinic);
    } else if (workingHours != null && workingHours.isNotEmpty) {
      return _buildHoursTabOldFormat(workingHours);
    } else {
      return const Center(
        child: Text("No working hours available", style: TextStyle(fontSize: 16)),
      );
    }
  }

  Widget _buildHoursTabNewFormat(List<dynamic> workingHoursClinic) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workingHoursClinic.length,
      itemBuilder: (context, index) {
        final item = workingHoursClinic[index];
        final isHoliday = item["is_holiday"] == true;
        final morningSession = item["morning_session"];
        final eveningSession = item["evening_session"];

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(
              item["day"],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isHoliday ? Colors.red : Colors.black,
              ),
            ),
            subtitle: isHoliday
                ? const Text("Holiday", style: TextStyle(color: Colors.red))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (morningSession["open"] != null && morningSession["open"].isNotEmpty)
                        Text("🌅 Morning: ${_formatTime(morningSession["open"])} - ${_formatTime(morningSession["close"])}"),
                      if (eveningSession["open"] != null && eveningSession["open"].isNotEmpty)
                        Text("🌇 Evening: ${_formatTime(eveningSession["open"])} - ${_formatTime(eveningSession["close"])}"),
                      if (item["has_break"] == true)
                        const Text("⏸️ Has break time", style: TextStyle(color: Colors.orange)),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHoursTabOldFormat(List<dynamic> workingHours) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workingHours.length,
      itemBuilder: (context, index) {
        final item = workingHours[index];
        final isHoliday = item["is_holiday"] == true;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(
              item["day"],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isHoliday ? Colors.red : Colors.black,
              ),
            ),
            subtitle: isHoliday
                ? const Text("Holiday", style: TextStyle(color: Colors.red))
                : Text(
                    "🕒 ${_formatTime(item["opening_time"])} - ${_formatTime(item["closing_time"])}",
                    style: const TextStyle(fontSize: 13),
                  ),
          ),
        );
      },
    );
  }

  // ===================== LOCATION TAB =====================
  Widget _buildLocationTab() {
    final lat = hospital["latitude"]?.toString() ?? "0";
    final lng = hospital["longitude"]?.toString() ?? "0";
    
    // Check if coordinates are valid
    if (lat == "0" && lng == "0") {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Location not available",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Map Preview
        Expanded(
          child: _LocationMapPreview(
            latitude: double.tryParse(lat) ?? 0,
            longitude: double.tryParse(lng) ?? 0,
            hospitalName: hospital["name"] ?? "Hospital",
            address: hospital["address"] ?? "",
          ),
        ),
        
        // Open in Maps Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _openMaps,
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            label: const Text(
              "Open in Google Maps",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===================== REVIEWS TAB =====================
  Widget _buildReviewsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Authentication Status
          if (currentUserId == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Login to submit or manage reviews",
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Reviews List
       Expanded(
  child: isReviewLoading
      ? const Center(child: CircularProgressIndicator())
      : reviews.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.reviews, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No reviews yet",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    "Be the first to review!",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              // ✅ FIX ADDED HERE
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),

              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                final isOwnReview = _isCurrentUserReview(review);
                final isTempReview = _isTempReview(review);
                final isSubmittingReview = _isSubmittingReview(review);
                final isUpdatingReview = _isUpdatingReview(review);
                final userName = _getUserName(review);
                final userInitial = _getUserInitial(userName);
                final rating = _getRating(review);
                final comment = _getComment(review);
                final reviewDate = _getReviewDate(review);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: isTempReview
                      ? Colors.grey[100]
                      : (isUpdatingReview
                          ? Colors.blue[50]
                          : (isSubmittingReview
                              ? Colors.yellow[50]
                              : null)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // (rest of your code unchanged)
                      ],
                    ),
                  ),
                );
              },
            ),
),

          const Divider(),

          // Review Form (Create or Edit)
          if (editingReviewId != null) 
            _buildEditReviewForm()
          else
            _buildCreateReviewForm(),
        ],
      ),
    );
  }

  Widget _buildCreateReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Write a Review:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        _buildRatingStars(rating, (newRating) {
          setState(() => rating = newRating);
        }),
        const SizedBox(height: 10),
        TextField(
          controller: reviewController,
          decoration: InputDecoration(
            hintText: currentUserId == null 
                ? "Please login to write a review"
                : "Share your experience...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          maxLines: 3,
          enabled: currentUserId != null && !isReviewLoading,
        ),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton.icon(
            onPressed: currentUserId == null ? _navigateToLogin : (isReviewLoading ? null : _createReview),
            icon: Icon(currentUserId == null ? Icons.login : Icons.send, color: Colors.white),
            label: Text(
              currentUserId == null 
                  ? "Login to Review" 
                  : (isReviewLoading ? "Submitting..." : "Submit Review"),
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentUserId == null ? Colors.orange : Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Edit Your Review:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
        ),
        const SizedBox(height: 10),
        _buildRatingStars(editingRating, (newRating) {
          setState(() => editingRating = newRating);
        }),
        const SizedBox(height: 10),
        TextField(
          controller: editingReviewController,
          decoration: InputDecoration(
            hintText: "Edit your review...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          maxLines: 3,
          enabled: !isReviewLoading,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: isReviewLoading ? null : () => _updateReview(editingReviewId!),
              icon: const Icon(Icons.save, color: Colors.white),
              label: Text(
                isReviewLoading ? "Updating..." : "Update Review",
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: isReviewLoading ? null : _cancelEdit,
              icon: const Icon(Icons.cancel),
              label: const Text("Cancel"),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingStars(double currentRating, Function(double) onRatingChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < currentRating ? Icons.star : Icons.star_border,
            color: currentUserId == null ? Colors.grey : Colors.amber,
            size: 30,
          ),
          onPressed: currentUserId == null ? _navigateToLogin : () => onRatingChanged(index + 1.0),
        );
      }),
    );
  }
}

// 🌐 Map Preview Widget - FIXED VERSION
class _LocationMapPreview extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String hospitalName;
  final String address;

  const _LocationMapPreview({
    required this.latitude,
    required this.longitude,
    required this.hospitalName,
    required this.address,
  });

  @override
  State<_LocationMapPreview> createState() => _LocationMapPreviewState();
}

class _LocationMapPreviewState extends State<_LocationMapPreview> {
  late final WebViewController _controller;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final mapsUrl = _getGoogleMapsUrl();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print("WebView loading: $progress%");
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() => isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            print("WebView error: ${error.description}");
            setState(() {
              isLoading = false;
              hasError = true;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(mapsUrl));
  }

  String _getGoogleMapsUrl() {
    // Use OpenStreetMap as a free alternative that works without API key
    // This will show a proper interactive map
    return "https://www.openstreetmap.org/export/embed.html?bbox=${widget.longitude-0.01}%2C${widget.latitude-0.01}%2C${widget.longitude+0.01}%2C${widget.latitude+0.01}&layer=mapnik&marker=${widget.latitude}%2C${widget.longitude}";
  }

  String _getAlternativeMapUrl() {
    // Alternative: Use Google Maps with simple search (no API key needed for basic display)
    final query = "${widget.hospitalName} ${widget.address}".trim();
    if (query.isNotEmpty) {
      return "https://maps.google.com/maps?q=${Uri.encodeComponent(query)}&output=embed";
    } else {
      return "https://maps.google.com/maps?q=${widget.latitude},${widget.longitude}&output=embed";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // WebView
        WebViewWidget(controller: _controller),

        // Loading Indicator
        if (isLoading)
          Container(
            color: Colors.white,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "Loading map...",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

        // Error Message
        if (hasError && !isLoading)
          Container(
            color: Colors.grey[100],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "Map not available",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _initializeWebView,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text("Retry", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),

        // Hospital Info Overlay
        if (!isLoading && !hasError)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.hospitalName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (widget.address.isNotEmpty)
                    Text(
                      widget.address,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}