import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:hosta/presentation/screens/doctor/doctors.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:hosta/presentation/screens/hospital/widgets/hours-tab.dart';
import 'package:hosta/presentation/screens/hospital/widgets/info-tab.dart';
import 'package:hosta/presentation/screens/hospital/widgets/location.dart';
import 'package:hosta/presentation/screens/hospital/widgets/review-tab.dart';
import 'package:hosta/presentation/screens/hospital/widgets/specialities.dart';
import 'package:hosta/providers/hospital-details-provider.dart';
import 'package:url_launcher/url_launcher.dart';

class HospitalDetailsPage extends ConsumerStatefulWidget {
  final String hospitalId;
  final Map<String, dynamic> hospital;

  const HospitalDetailsPage({
    super.key,
    required this.hospitalId,
    required this.hospital,
  });

  @override
  ConsumerState<HospitalDetailsPage> createState() => _HospitalDetailsPageState();
}

class _HospitalDetailsPageState extends ConsumerState<HospitalDetailsPage> {
  late Map<String, dynamic> hospital;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    hospital = widget.hospital;
    _initializeData();
  }

  Future<void> _initializeData() async {
    await ref.read(userProvider.notifier).initializeUser();
    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      print("🔄 Loading initial data for hospital ID: ${widget.hospitalId}");
      
      // Fetch hospital details and reviews
      await ref.read(hospitalDetailsProvider(widget.hospitalId).future);
      await ref.read(hospitalReviewsProvider(widget.hospitalId).future);
      
      // Update local hospital data
      final hospitalData = ref.read(hospitalDetailsProvider(widget.hospitalId));
      hospitalData.whenData((data) {
        setState(() {
          hospital = data;
        });
      });
      
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
      final hospitalData = await ref.read(hospitalDetailsProvider(widget.hospitalId).future);
      setState(() {
        hospital = hospitalData;
      });
      print("✅ Hospital details fetched successfully");
    } catch (e) {
      print("❌ Error fetching hospital details: $e");
    }
  }

  Future<void> _createReview({required double rating, required String comment}) async {
    final userState = ref.read(userProvider);
    
    if (userState.userId == null) return;

    final reviewOps = ref.read(reviewOperationsProvider);
    
    await reviewOps.createReview(
      hospitalId: widget.hospitalId,
      rating: rating,
      comment: comment,
      userId: userState.userId!,
      userName: userState.userName ?? "You",
      userEmail: userState.userEmail ?? "",
      onSuccess: () {
        showTopSnackBar(context, "Review submitted successfully!");
        _fetchHospitalReviews();
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );
  }

  Future<void> _updateReview(String reviewId, {required double rating, required String comment}) async {
    final reviewOps = ref.read(reviewOperationsProvider);
    
    await reviewOps.updateReview(
      reviewId: reviewId,
      hospitalId: widget.hospitalId,
      rating: rating,
      comment: comment,
      onSuccess: () {
        showTopSnackBar(context, "Review updated successfully!");
        _fetchHospitalReviews();
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );
  }

  Future<void> _deleteReview(String reviewId) async {
    final reviewOps = ref.read(reviewOperationsProvider);
    
    await reviewOps.deleteReview(
      reviewId: reviewId,
      hospitalId: widget.hospitalId,
      onSuccess: () {
        showTopSnackBar(context, "Review deleted successfully!");
        _fetchHospitalReviews();
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      },
    );
  }

  Future<void> _fetchHospitalReviews() async {
    // Refresh the reviews provider
    ref.invalidate(hospitalReviewsProvider(widget.hospitalId));
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<bool> _checkAuthentication() async {
    final userState = ref.read(userProvider);
    
    if (userState.userId != null) {
      return true;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Signin()),
    );
    
    if (result == true) {
      await ref.read(userProvider.notifier).refreshUser();
      final updatedUserState = ref.read(userProvider);
      return updatedUserState.userId != null;
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
      await ref.read(userProvider.notifier).refreshUser();
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
    // Watch for hospital details changes
    final hospitalDetailsAsync = ref.watch(hospitalDetailsProvider(widget.hospitalId));
    final reviewsAsync = ref.watch(hospitalReviewsProvider(widget.hospitalId));
    final isReviewLoading = ref.watch(reviewLoadingProvider);
    final userState = ref.watch(userProvider);

    if (isLoading || userState.isLoading) {
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
                      reviews: reviewsAsync.when(
                        data: (reviews) => reviews,
                        loading: () => [],
                        error: (_, __) => [],
                      ),
                      currentUserId: userState.userId,
                      currentUserName: userState.userName,
                      currentUserEmail: userState.userEmail,
                      isReviewLoading: isReviewLoading,
                      onCreateReview: () async {
                        // This will be handled by the ReviewsTab's internal state
                      },
                      onUpdateReview: (reviewId) {},
                      onDeleteReview: _deleteReview,
                      onNavigateToLogin: _navigateToLogin,
                      onInitializeUser: () async {
                        await ref.read(userProvider.notifier).initializeUser();
                      },
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