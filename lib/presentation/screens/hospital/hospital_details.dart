import 'package:flutter/material.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:hosta/presentation/screens/doctor/doctors.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:hosta/presentation/screens/hospital/widgets/hours-tab.dart';
import 'package:hosta/presentation/screens/hospital/widgets/info-tab.dart';
import 'package:hosta/presentation/screens/hospital/widgets/location.dart';
import 'package:hosta/presentation/screens/hospital/widgets/review-tab.dart';
import 'package:hosta/presentation/screens/hospital/widgets/specialities.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
      
      await _fetchHospitalDetails();
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

  Future<void> _fetchHospitalReviews() async {
    try {
      print("📝 Fetching reviews for hospital ID: ${widget.hospitalId}");
      final response = await ApiService().getAHospitalsReview(widget.hospitalId);
      print('✅ Reviews API Response received: ${response.data}');
      
      if (response.data != null) {
        if (response.data is Map && response.data.containsKey("data")) {
          setState(() {
            reviews = response.data["data"] ?? [];
          });
        } else if (response.data is List) {
          setState(() {
            reviews = response.data;
          });
        } else {
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
    } catch (e) {
      print("❌ Error fetching reviews: $e");
      setState(() {
        reviews = [];
      });
    }
  }

  Future<void> _createReview({required double rating, required String comment}) async {
    setState(() => isReviewLoading = true);

    try {
      final Map<String, dynamic> reviewData = {
        "userId": currentUserId!,
        "rating": rating,
        "comment": comment,
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
        "comment": comment,
        "createdAt": DateTime.now().toIso8601String(),
        "isTemp": true,
        "isSubmitting": true,
      };

      setState(() {
        reviews = [tempReview, ...reviews];
      });

      await ApiService().createAHospitalReview(reviewData);
      await _fetchHospitalReviews();
      showTopSnackBar(context, "Review submitted successfully!");

      setState(() => isReviewLoading = false);
    } catch (e) {
      setState(() {
        reviews = reviews.where((review) => review["isTemp"] != true).toList();
      });
      setState(() => isReviewLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting review: $e")),
      );
    }
  }

  Future<void> _updateReview(String reviewId, {required double rating, required String comment}) async {
    setState(() => isReviewLoading = true);

    try {
      final Map<String, dynamic> reviewData = {
        "rating": rating,
        "comment": comment,
      };

      setState(() {
        final reviewIndex = reviews.indexWhere((review) => review["_id"] == reviewId);
        if (reviewIndex != -1) {
          reviews[reviewIndex] = {
            ...reviews[reviewIndex],
            "rating": rating,
            "comment": comment,
            "isUpdating": true,
          };
        }
      });

      await ApiService().updateAHospitalReview(reviewId, reviewData);
      await _fetchHospitalReviews();
      showTopSnackBar(context, "Review updated successfully!");

      setState(() => isReviewLoading = false);
    } catch (e) {
      await _fetchHospitalReviews();
      setState(() => isReviewLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating review: $e")),
      );
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    setState(() => isReviewLoading = true);

    final reviewToDeleteIndex = reviews.indexWhere((review) => review["_id"] == reviewId);
    if (reviewToDeleteIndex == -1) {
      setState(() => isReviewLoading = false);
      return;
    }
    
    final reviewToDelete = Map<String, dynamic>.from(reviews[reviewToDeleteIndex]);

    setState(() {
      reviews = reviews.where((review) => review["_id"] != reviewId).toList();
    });

    try {
      await ApiService().deleteAHospitalReview(reviewId);
      showTopSnackBar(context, "Review deleted successfully!");
      setState(() => isReviewLoading = false);
    } catch (e) {
      setState(() {
        reviews = [reviewToDelete, ...reviews];
      });
      setState(() => isReviewLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting review: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

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

  void _navigateToLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Signin()),
    );
    
    if (result == true) {
      await _initializeUser();
    }
  }

  String _getGoogleMapsUrl() {
    final lat = hospital["latitude"]?.toString() ?? "0";
    final lng = hospital["longitude"]?.toString() ?? "0";
    final name = hospital["name"] ?? "Hospital";
    final address = hospital["address"] ?? "";
    
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
              // Top Image
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
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
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),

              // Tabs
              const SizedBox(height: 8),
              const TabBar(
                isScrollable: true,
                labelColor: Colors.green,
                unselectedLabelColor: Colors.black,
                indicatorColor: Colors.green,
                labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                tabs: [
                  Tab(text: "Information"),
                  Tab(text: "Specialties"),
                  Tab(text: "Working Hours"),
                  Tab(text: "Location"),
                  Tab(text: "Reviews"),
                ],
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  children: [
                    InfoTab(hospital: hospital, makePhoneCall: _makePhoneCall),
                    SpecialtiesTab(
                      hospital: hospital,
                      onSpecialtyTap: _navigateToDoctorsPage,
                    ),
                    HoursTab(
                      hospital: hospital,
                      formatTime: _formatTime,
                    ),
                    LocationTab(
                      hospital: hospital,
                      onOpenMaps: _openMaps,
                    ),
                    ReviewsTab(
                      hospitalId: widget.hospitalId,
                      reviews: reviews,
                      currentUserId: currentUserId,
                      currentUserName: currentUserName,
                      currentUserEmail: currentUserEmail,
                      isReviewLoading: isReviewLoading,
                      onCreateReview: () async {
                        // This will be handled by the ReviewsTab's internal state
                        // The actual implementation needs to be adjusted
                      },
                      onUpdateReview: (reviewId) {},
                      onDeleteReview: _deleteReview,
                      onNavigateToLogin: _navigateToLogin,
                      onInitializeUser: _initializeUser,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}