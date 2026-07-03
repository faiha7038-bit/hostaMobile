import 'package:flutter/material.dart';
import 'package:hosta/common/login_dialoge.dart';
import 'package:hosta/data/models/doctor_model.dart';
import 'package:hosta/data/models/review_model.dart';
import 'package:hosta/presentation/screens/booking/register_booking.dart';
import 'package:hosta/services/socket-service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

class DoctorDetailScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  bool isLoading = false;
  bool _listenerAdded = false;
  Doctor? doctorDetails;
  String? errorMessage;
  List<Review> reviews = [];
  Review? myReview;
  bool reviewsLoading = false;
  int appointmentCount = 0;
  int currentPage = 1;
  bool hasMore = true;
  bool loadMoreLoading = false;
  String? currentUserName;
  String? currentUserImage;
  int selectedRating = 0;
  double avgRating = 0.0;
  int totalReviews = 0;
  bool canReview = false;
  bool showAllReviews = false;
  late Function(dynamic) _onReviewEvent;
  Map<int, int> ratingBreakdown = {
    5: 0,
    4: 0,
    3: 0,
    2: 0,
    1: 0,
  };

  @override
  void initState() {
    super.initState();
    doctorDetails = widget.doctor;
    _fetchDoctorDetails();
    _fetchReviews();
    _fetchMyReview();
    _loadUser();
    _fetchRating();
    _setupSocketListener();
  }

  @override
  void dispose() {
    SocketService().removeListener("RATING_REGISTERED", _onReviewEvent);
    SocketService().removeListener("RATING_UPDATED", _onReviewEvent);
    SocketService().removeListener("REVIEW_REGISTERED", _onReviewEvent);
    SocketService().removeListener("REVIEW_UPDATED", _onReviewEvent);
    super.dispose();
  }

  void _setupSocketListener() {
    if (_listenerAdded) return;
    _listenerAdded = true;
    _onReviewEvent = (data) async {
      if (!mounted) return;
      await _fetchRating();
      await _fetchMyReview();
      currentPage = 1;
      hasMore = true;
      await _fetchReviews();
      if (mounted) setState(() {});
    };
    SocketService().addListener(
      [
        'RATING_REGISTERED',
        'RATING_UPDATED',
        'REVIEW_REGISTERED',
        'REVIEW_UPDATED',
      ],
      _onReviewEvent,
    );
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUserName = prefs.getString("userName") ?? "User";
      currentUserImage = prefs.getString("userImage");
    });
  }

  Future<void> _fetchRating() async {
    try {
      final res = await ApiService().getRating(
        hospitalId: "",
        doctorId: widget.doctor.id.toString(),
      );
      final data = res['data'];
      setState(() {
        avgRating = (data['averageRating'] ?? 0).toDouble();
        totalReviews = data['totalReviews'] ?? 0;
        final breakdown = data['ratingBreakdown'] ?? {};
        ratingBreakdown = {
          5: breakdown['5']?['count'] ?? 0,
          4: breakdown['4']?['count'] ?? 0,
          3: breakdown['3']?['count'] ?? 0,
          2: breakdown['2']?['count'] ?? 0,
          1: breakdown['1']?['count'] ?? 0,
        };
      });
    } catch (e) {}
  }

  void _showEditReviewDialog() {
    final controller = TextEditingController(text: myReview!.comment);
    int stars = myReview!.rating;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                "Edit Review",
                style: TextStyle(
                  fontSize: _clamp(MediaQuery.of(context).size.width * 0.045, 16, 24),
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                        child: Icon(
                          Icons.star,
                          color: index < stars ? Colors.amber : Colors.grey,
                          size: _clamp(MediaQuery.of(context).size.width * 0.07, 24, 40),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.012),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          _clamp(MediaQuery.of(context).size.width * 0.025, 8, 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: _clamp(MediaQuery.of(context).size.width * 0.04, 14, 20),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await ApiService().updateReview(
                      myReview!.id.toString(),
                      {
                        "rating": stars,
                        "comment": controller.text.trim(),
                      },
                    );
                    Navigator.pop(context);
                    await _fetchRating();
                    await _fetchMyReview();
                    await _fetchReviews();
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        _clamp(MediaQuery.of(context).size.width * 0.025, 8, 16),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: _clamp(MediaQuery.of(context).size.width * 0.04, 12, 24),
                      vertical: _clamp(MediaQuery.of(context).size.height * 0.015, 8, 16),
                    ),
                  ),
                  child: Text(
                    "Update",
                    style: TextStyle(
                      fontSize: _clamp(MediaQuery.of(context).size.width * 0.04, 14, 20),
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _fetchReviews({bool loadMore = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId');
      final res = await ApiService().getReviews(
        doctorId: widget.doctor.id.toString(),
        page: currentPage,
        limit: 5,
      );
      final data = res.data['data'] as List;
      final newData = data
          .where((e) => e['userId'].toString() != currentUserId)
          .map<Review>((e) => Review.fromJson(e))
          .toList();
      setState(() {
        if (loadMore) {
          reviews.addAll(newData);
        } else {
          reviews = newData;
        }
        hasMore = res.data['pagination']['hasNextPage'] ?? false;
        loadMoreLoading = false;
      });
    } catch (e) {
      setState(() => loadMoreLoading = false);
    }
  }

  Future<void> _fetchMyReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null || userId.isEmpty) return;
      final res = await ApiService().getReviews(
        doctorId: widget.doctor.id.toString(),
      );
      final data = res.data['data'] as List;
      for (final item in data) {
        if (item['userId'].toString() == userId) {
          setState(() {
            myReview = Review.fromJson(item);
          });
          break;
        }
      }
    } catch (e) {}
  }

  Future<void> _fetchDoctorDetails() async {
    try {
      final response =
          await ApiService().getDoctorById(widget.doctor.id.toString());
      if (response.data['success'] == true) {
        setState(() {
          doctorDetails = Doctor.fromJson(response.data['data']);
        });
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isLandscape = screenWidth > screenHeight;

    // Responsive clamped values for reuse
    final double appBarHeight = _clamp(isSmallScreen ? 56 : 70, 50, 80);
    final double appBarTitleSize = _clamp(isSmallScreen ? 18 : 22, 16, 28);
    final double pagePadding = _clamp(isSmallScreen ? 12.0 : screenWidth * 0.02, 8, 24);
    final double defaultPadding = _clamp(isSmallScreen ? 12.0 : 16.0, 8, 24);
    final double defaultFontSize = _clamp(isSmallScreen ? 14 : 16, 12, 20);
    final double smallFontSize = _clamp(isSmallScreen ? 12 : 14, 10, 18);
    final double titleFontSize = _clamp(isSmallScreen ? 16 : 20, 14, 26);
    final double iconSize = _clamp(isSmallScreen ? 20 : 24, 16, 32);
    final double avatarSize = _clamp(isLandscape ? 50.0 : (isSmallScreen ? 60.0 : 80.0), 40, 100);
    final double radius = _clamp(screenWidth * 0.03, 8, 20);
    final double spacingSmall = screenHeight * 0.012;
    final double spacingMedium = screenHeight * 0.015;
    final double spacingLarge = screenHeight * 0.025;
    final double starSize = _clamp(isSmallScreen ? 14 : 16, 12, 20);

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          toolbarHeight: appBarHeight,
          title: Text(
            "Doctor Details",
            style: TextStyle(
              fontSize: appBarTitleSize,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.green,
            strokeWidth: _clamp(screenWidth * 0.008, 2, 6),
          ),
        ),
      );
    }

    if (errorMessage != null || doctorDetails == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          toolbarHeight: appBarHeight,
          title: Text(
            "Doctor Details",
            style: TextStyle(
              fontSize: appBarTitleSize,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: _clamp(screenWidth * 0.15, 40, 80),
                color: Colors.grey,
              ),
              SizedBox(height: spacingMedium),
              Text(
                errorMessage ?? 'Doctor not found',
                style: TextStyle(fontSize: defaultFontSize),
              ),
              SizedBox(height: spacingLarge),
              ElevatedButton(
                onPressed: _fetchDoctorDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: _clamp(screenWidth * 0.06, 16, 40),
                    vertical: _clamp(screenHeight * 0.015, 8, 20),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(fontSize: defaultFontSize, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        toolbarHeight: appBarHeight,
        title: Text(
          "Doctor Details",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: appBarTitleSize,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: _clamp(screenWidth * 0.055, 20, 32),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _doctorHeader(
              screenWidth,
              screenHeight,
              isSmallScreen,
              isLandscape,
              avatarSize,
              starSize,
              defaultFontSize,
              smallFontSize,
            ),

            SizedBox(height: spacingLarge),

            _infoCard(
              icon: Icons.local_hospital,
              title: doctorDetails!.hospitalName ?? 'Hospital',
              subtitle: doctorDetails!.address.fullAddress,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              isSmallScreen: isSmallScreen,
            ),

            SizedBox(height: spacingMedium),

            if (doctorDetails!.outDoorConsulting != null)
              _infoCard(
                icon: Icons.location_on,
                title: "OUTDOOR CONSULTING",
                subtitle: doctorDetails!.outDoorConsulting!.place,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                isSmallScreen: isSmallScreen,
              ),

            SizedBox(height: spacingMedium),

            _feesCard(screenWidth, screenHeight, isSmallScreen),

            SizedBox(height: spacingLarge),

            Container(
              padding: EdgeInsets.all(defaultPadding * 0.75),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    color: Colors.green,
                    size: _clamp(screenWidth * 0.055, 20, 32),
                  ),
                  SizedBox(width: _clamp(screenWidth * 0.025, 6, 16)),
                  Text(
                    "${doctorDetails!.appointmentCount} Total Appointments",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: defaultFontSize,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: spacingLarge),

            Text(
              "Available Days",
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: spacingSmall),

            Wrap(
              spacing: _clamp(screenWidth * 0.02, 4, 12),
              runSpacing: _clamp(screenHeight * 0.01, 4, 12),
              children: doctorDetails!.availableDays.map((day) {
                return Chip(
                  label: Text(
                    day,
                    style: TextStyle(fontSize: smallFontSize),
                  ),
                  backgroundColor: Colors.green.shade50,
                  avatar: Icon(
                    Icons.check,
                    color: Colors.green,
                    size: _clamp(screenWidth * 0.045, 14, 24),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: spacingLarge),

            if (doctorDetails!.consulting.morningSession != null)
              _timingTile(
                "Morning Session",
                doctorDetails!.consulting.morningSession!.range,
                screenWidth,
                screenHeight,
                isSmallScreen,
              ),

            if (doctorDetails!.consulting.eveningSession != null)
              _timingTile(
                "Evening Session",
                doctorDetails!.consulting.eveningSession!.range,
                screenWidth,
                screenHeight,
                isSmallScreen,
              ),

            if (doctorDetails!.outDoorConsulting != null)
              _timingTile(
                "Outdoor Consulting",
                doctorDetails!.outDoorConsulting!.time.range,
                screenWidth,
                screenHeight,
                isSmallScreen,
              ),

            SizedBox(height: spacingLarge),

            Text(
              "About Doctor",
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: spacingSmall),

            Text(
              " ${doctorDetails!.displayName} is a specialized ${doctorDetails!.specialty.toLowerCase()} with qualification ${doctorDetails!.qualification}. "
              "Experienced in ${doctorDetails!.department} department with expertise in ${doctorDetails!.specialist}.",
              style: TextStyle(
                color: Colors.grey,
                fontSize: isSmallScreen ? 13 : 15,
                height: 1.4,
              ),
            ),

            SizedBox(height: spacingLarge),

            if (doctorDetails!.knowLanguages.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Languages Known",
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: spacingSmall),
                  Wrap(
                    spacing: _clamp(screenWidth * 0.02, 4, 12),
                    runSpacing: _clamp(screenHeight * 0.01, 4, 12),
                    children: doctorDetails!.knowLanguages
                        .map((lang) => Chip(
                              label: Text(
                                lang,
                                style: TextStyle(fontSize: smallFontSize),
                              ),
                              backgroundColor: Colors.green[50],
                            ))
                        .toList(),
                  ),
                  SizedBox(height: spacingLarge),
                ],
              ),

            Text(
              "Ratings and Reviews",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: titleFontSize,
              ),
            ),
            SizedBox(height: spacingLarge),

            _ratingOverview(
              screenWidth,
              screenHeight,
              avgRating,
              totalReviews,
              ratingBreakdown,
            ),

            SizedBox(height: spacingLarge),

            myReview != null
                ? _buildMyReviewCard(
                    screenWidth,
                    screenHeight,
                    isSmallScreen,
                  )
                : _buildWriteReviewCard(
                    screenWidth,
                    screenHeight,
                    isSmallScreen,
                  ),

            const SizedBox(height: 20),

            Text(
              "Patient Reviews",
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (reviewsLoading)
              Center(
                child: CircularProgressIndicator(
                  color: Colors.green,
                  strokeWidth: _clamp(screenWidth * 0.008, 2, 6),
                ),
              )
            else if (reviews.isEmpty)
              Text(
                "No reviews yet",
                style: TextStyle(
                  fontSize: defaultFontSize,
                  color: Colors.grey,
                ),
              )
            else
              Column(
                children: (showAllReviews ? reviews : reviews.take(5))
                    .map((r) => _reviewTile(r, screenWidth, screenHeight, isSmallScreen))
                    .toList(),
              ),

            if (totalReviews > 5 && !showAllReviews)
              TextButton(
                onPressed: () async {
                  setState(() {
                    showAllReviews = true;
                  });
                  currentPage = 2;
                  while (hasMore && currentPage <= 20) {
                    await _fetchReviews(loadMore: true);
                    currentPage++;
                  }
                },
                child: Text(
                  "See All Reviews",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: defaultFontSize,
                  ),
                ),
              ),

            SizedBox(height: spacingMedium),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radius),
                  ),
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(
                    vertical: _clamp(screenHeight * 0.02, 12, 24),
                  ),
                ),
                onPressed: (doctorDetails!.bookingOpen && doctorDetails!.isActive)
                    ? () async {
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString('userId') ?? '';
                        if (userId.isEmpty) {
                          showLoginRequiredDialog(context);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RegisterBooking(doctor: widget.doctor),
                          ),
                        );
                      }
                    : null,
                child: Text(
                  (doctorDetails!.bookingOpen && doctorDetails!.isActive)
                      ? "Book Appointment"
                      : "CLOSED",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
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

  // ---------- Helper widgets ----------

  Widget _doctorHeader(
    double screenWidth,
    double screenHeight,
    bool isSmallScreen,
    bool isLandscape,
    double avatarSize,
    double starSize,
    double defaultFontSize,
    double smallFontSize,
  ) {
    final doctor = doctorDetails!;
    final String firstLetter = doctor.displayName.isNotEmpty
        ? doctor.displayName[0].toUpperCase()
        : doctor.firstName[0].toUpperCase();

    final double padding = _clamp(isSmallScreen ? 12.0 : 20.0, 8, 32);
    final double radius = _clamp(screenWidth * 0.05, 12, 24);
    final double nameSize = _clamp(isSmallScreen ? 16 : 20, 14, 28);
    final double subtitleSize = _clamp(isSmallScreen ? 12 : 14, 10, 18);
    final double smallSize = _clamp(isSmallScreen ? 11 : 13, 10, 16);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: doctor.imageUrl != null && doctor.imageUrl!.isNotEmpty
                  ? Image.network(
                      doctor.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.green,
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
                        );
                      },
                    )
                  : Container(
                      color: Colors.green,
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
            ),
          ),
          SizedBox(width: _clamp(isSmallScreen ? 12.0 : 20.0, 8, 32)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: nameSize,
                  ),
                ),
                Text(
                  doctor.specialty,
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: subtitleSize,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${doctor.experience} Years Experience",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: smallFontSize,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: starSize,
                      color: Colors.amber,
                    ),
                    Text(
                      "$avgRating",
                      style: TextStyle(fontSize: smallFontSize),
                    ),
                    Text(
                      " ($totalReviews)",
                      style: TextStyle(fontSize: smallFontSize),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${doctor.fees} Consultation Fee",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                    fontSize: smallSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feesCard(
    double screenWidth,
    double screenHeight,
    bool isSmallScreen,
  ) {
    final doctor = doctorDetails!;
    final double padding = _clamp(isSmallScreen ? 12.0 : 16.0, 8, 24);
    final double radius = _clamp(screenWidth * 0.04, 10, 20);
    final double iconSize = _clamp(isSmallScreen ? 20 : 24, 16, 32);
    final double titleSize = _clamp(isSmallScreen ? 14 : 16, 12, 22);
    final double feeSize = _clamp(isSmallScreen ? 16 : 20, 14, 28);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.currency_rupee,
            color: Colors.green,
            size: iconSize,
          ),
          SizedBox(width: _clamp(screenWidth * 0.025, 6, 16)),
          Text(
            "Consultation Fee",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: titleSize,
            ),
          ),
          const Spacer(),
          Text(
            "₹${doctor.fees}",
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: feeSize,
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
    required double screenHeight,
    required bool isSmallScreen,
  }) {
    final double padding = _clamp(isSmallScreen ? 12.0 : 16.0, 8, 24);
    final double radius = _clamp(screenWidth * 0.04, 10, 20);
    final double iconSize = _clamp(isSmallScreen ? 20 : 24, 16, 32);
    final double titleSize = _clamp(isSmallScreen ? 14 : 16, 12, 22);
    final double subtitleSize = _clamp(isSmallScreen ? 12 : 14, 10, 18);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: iconSize),
          SizedBox(width: _clamp(screenWidth * 0.03, 8, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: titleSize,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: subtitleSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timingTile(
    String title,
    String time,
    double screenWidth,
    double screenHeight,
    bool isSmallScreen,
  ) {
    final double padding = _clamp(isSmallScreen ? 10.0 : 12.0, 6, 20);
    final double radius = _clamp(screenWidth * 0.03, 8, 16);
    final double iconSize = _clamp(isSmallScreen ? 16 : 18, 14, 28);
    final double titleSize = _clamp(isSmallScreen ? 14 : 16, 12, 22);
    final double timeSize = _clamp(isSmallScreen ? 12 : 14, 10, 18);

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.008),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            size: iconSize,
            color: Colors.green,
          ),
          SizedBox(width: _clamp(screenWidth * 0.025, 6, 16)),
          Text(
            title,
            style: TextStyle(fontSize: titleSize),
          ),
          const Spacer(),
          Text(
            time,
            style: TextStyle(
              color: Colors.green,
              fontSize: timeSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewTile(
    Review review,
    double screenWidth,
    double screenHeight,
    bool isSmallScreen,
  ) {
    final double margin = _clamp(screenHeight * 0.01, 6, 16);
    final double padding = _clamp(isSmallScreen ? 10.0 : 12.0, 8, 20);
    final double radius = _clamp(screenWidth * 0.03, 8, 16);
    final double nameSize = _clamp(isSmallScreen ? 14 : 16, 12, 22);
    final double commentSize = _clamp(isSmallScreen ? 12 : 14, 10, 18);
    final double starSize = _clamp(screenWidth * 0.04, 12, 20);

    return Container(
      margin: EdgeInsets.only(bottom: margin),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: _clamp(screenWidth * 0.045, 14, 24),
                backgroundImage: review.imageUrl != null && review.imageUrl!.isNotEmpty
                    ? NetworkImage(review.imageUrl!)
                    : null,
                child: review.imageUrl == null
                    ? Text(
                        review.name.isNotEmpty ? review.name[0].toUpperCase() : "P",
                        style: TextStyle(
                          fontSize: _clamp(screenWidth * 0.04, 12, 20),
                        ),
                      )
                    : null,
              ),
              SizedBox(width: _clamp(screenWidth * 0.025, 6, 16)),
              Expanded(
                child: Text(
                  review.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: nameSize,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: starSize,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _clamp(screenHeight * 0.008, 4, 12)),
          Text(
            review.comment,
            style: TextStyle(
              color: Colors.grey,
              fontSize: commentSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteReviewCard(
    double screenWidth,
    double screenHeight,
    bool isSmallScreen,
  ) {
    final double padding = _clamp(screenWidth * 0.03, 8, 16);
    final double radius = _clamp(screenWidth * 0.03, 8, 16);
    final double titleSize = _clamp(screenWidth * 0.04, 14, 22);
    final double subtitleSize = _clamp(screenWidth * 0.03, 10, 16);
    final double iconSize = _clamp(screenWidth * 0.07, 24, 40);
    final double textSize = _clamp(screenWidth * 0.04, 14, 22);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Rate this doctor",
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            "Tell others what you think",
            style: TextStyle(
              color: Colors.grey,
              fontSize: subtitleSize,
            ),
          ),
          SizedBox(height: screenHeight * 0.012),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(5, (index) {
              final isSelected = index < selectedRating;
              return GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final userId = prefs.getString('userId');
                  if (userId == null || userId.isEmpty) {
                    showLoginRequiredDialog(context);
                    return;
                  }
                  setState(() {
                    selectedRating = index + 1;
                  });
                  _showReviewDialog(initialRating: index + 1);
                },
                child: Icon(
                  isSelected ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: iconSize,
                ),
              );
            }),
          ),
          SizedBox(height: screenHeight * 0.012),
          GestureDetector(
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final userId = prefs.getString('userId');
              if (userId == null || userId.isEmpty) {
                showLoginRequiredDialog(context);
                return;
              }
              _showReviewDialog(initialRating: selectedRating);
            },
            child: Text(
              "Write a review",
              style: TextStyle(
                fontSize: textSize,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReviewCard(
    double screenWidth,
    double screenHeight,
    bool isSmallScreen,
  ) {
    final double padding = _clamp(screenWidth * 0.04, 12, 24);
    final double radius = _clamp(screenWidth * 0.03, 8, 16);
    final double titleSize = _clamp(screenWidth * 0.045, 16, 24);
    final double nameSize = _clamp(screenWidth * 0.04, 14, 22);
    final double commentSize = _clamp(screenWidth * 0.035, 12, 18);
    final double iconSize = _clamp(screenWidth * 0.04, 12, 20);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Review",
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenHeight * 0.012),
          Row(
            children: [
              CircleAvatar(
                radius: _clamp(screenWidth * 0.05, 18, 32),
                backgroundImage: myReview!.imageUrl != null && myReview!.imageUrl!.isNotEmpty
                    ? NetworkImage(myReview!.imageUrl!)
                    : null,
                child: myReview!.imageUrl == null || myReview!.imageUrl!.isEmpty
                    ? Text(
                        myReview!.name.isNotEmpty
                            ? myReview!.name[0].toUpperCase()
                            : "U",
                        style: TextStyle(
                          fontSize: _clamp(screenWidth * 0.04, 14, 22),
                        ),
                      )
                    : null,
              ),
              SizedBox(width: _clamp(screenWidth * 0.025, 6, 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      myReview!.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: nameSize,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < myReview!.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: iconSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: "edit",
                    child: Text("Edit"),
                  ),
                  const PopupMenuItem(
                    value: "delete",
                    child: Text("Delete"),
                  ),
                ],
                onSelected: (value) async {
                  if (value == "edit") {
                    _showEditReviewDialog();
                  }
                  if (value == "delete") {
                       final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(
                          "Delete Review",
                          style: TextStyle(
                            fontSize: _clamp(screenWidth * 0.05, 18, 28),
                          ),
                        ),
                        content: Text(
                          "Are you sure you want to delete this review?",
                          style: TextStyle(
                            fontSize: _clamp(screenWidth * 0.04, 14, 22),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: _clamp(screenWidth * 0.04, 14, 22),
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              "Delete",
                              style: TextStyle(
                                fontSize: _clamp(screenWidth * 0.04, 14, 22),
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ApiService().deleteReview(myReview!.id.toString());
                      setState(() {
                        myReview = null;
                        reviews = [];
                        currentPage = 1;
                        hasMore = true;
                      });
                      await _fetchRating();
                      await _fetchReviews();
                    }
                  }
                },
                iconSize: _clamp(screenWidth * 0.055, 20, 32),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            myReview!.comment,
            style: TextStyle(fontSize: commentSize),
          ),
        ],
      ),
    );
  }

  Widget _ratingOverview(
    double screenWidth,
    double screenHeight,
    double avgRating,
    int totalReviews,
    Map<int, int> ratingBreakdown,
  ) {
    final double padding = _clamp(screenWidth * 0.04, 12, 24);
    final double radius = _clamp(screenWidth * 0.03, 8, 16);
    final double avgSize = _clamp(screenWidth * 0.12, 32, 56);
    final double starSize = _clamp(screenWidth * 0.045, 14, 24);
    final double textSize = _clamp(screenWidth * 0.035, 12, 18);
    final double barHeight = _clamp(screenHeight * 0.008, 4, 10);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: avgSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < avgRating.round()
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: starSize,
                  );
                }),
              ),
              SizedBox(height: screenHeight * 0.005),
              Text(
                "$totalReviews reviews",
                style: TextStyle(color: Colors.grey, fontSize: textSize),
              ),
            ],
          ),
          SizedBox(width: _clamp(screenWidth * 0.05, 12, 32)),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                int star = 5 - i;
                int count = ratingBreakdown[star] ?? 0;
                double percent = totalReviews == 0
                    ? 0
                    : count / totalReviews;
                return Row(
                  children: [
                    Text(
                      "$star",
                      style: TextStyle(fontSize: textSize),
                    ),
                    SizedBox(width: _clamp(screenWidth * 0.015, 4, 12)),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: barHeight,
                        backgroundColor: Colors.grey.shade300,
                        valueColor:
                            const AlwaysStoppedAnimation(Colors.blue),
                      ),
                    ),
                    SizedBox(width: _clamp(screenWidth * 0.015, 4, 12)),
                    Text(
                      count.toString(),
                      style: TextStyle(fontSize: textSize),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog({int initialRating = 0}) {
    final controller = TextEditingController();
    int stars = initialRating;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  _clamp(screenWidth * 0.04, 10, 24),
                ),
              ),
              title: Text(
                "Add Review",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: _clamp(screenWidth * 0.045, 16, 24),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.green,
                        backgroundImage: (currentUserImage != null && currentUserImage!.isNotEmpty)
                            ? NetworkImage(currentUserImage!)
                            : null,
                        child: (currentUserImage == null || currentUserImage!.isEmpty)
                            ? Icon(
                                Icons.person,
                                color: Colors.white,
                                size: _clamp(screenWidth * 0.055, 20, 32),
                              )
                            : null,
                        radius: _clamp(screenWidth * 0.05, 18, 32),
                      ),
                      SizedBox(width: _clamp(screenWidth * 0.025, 6, 16)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUserName ?? "User",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: _clamp(screenWidth * 0.04, 14, 22),
                            ),
                          ),
                          Text(
                            "Posting publicly",
                            style: TextStyle(
                              fontSize: _clamp(screenWidth * 0.03, 10, 16),
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.016),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final isSelected = index < stars;
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            stars = index + 1;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            isSelected ? Icons.star : Icons.star_border,
                            size: _clamp(screenWidth * 0.085, 28, 48),
                            color: isSelected ? Colors.amber : Colors.grey.shade400,
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: screenHeight * 0.012),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Describe your experience (optional)",
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          _clamp(screenWidth * 0.025, 8, 16),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.green),
                        borderRadius: BorderRadius.circular(
                          _clamp(screenWidth * 0.025, 8, 16),
                        ),
                      ),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      fontSize: _clamp(screenWidth * 0.04, 14, 20),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        _clamp(screenWidth * 0.025, 8, 16),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: _clamp(screenWidth * 0.04, 12, 24),
                      vertical: _clamp(screenHeight * 0.015, 8, 16),
                    ),
                  ),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final userId = prefs.getString('userId');
                    final body = {
                      "userId": int.parse(userId!),
                      "hospitalId": doctorDetails!.hospitalId,
                      "doctorId": widget.doctor.id,
                      "rating": stars,
                      "comment": controller.text.trim(),
                    };
                    try {
                      final res = await ApiService().createReview(body);
                      Navigator.pop(context);
                      await _fetchMyReview();
                      await _fetchReviews();
                      await _fetchRating();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.green,
                          content: Text(
                            "You can review only after your consultation is completed.",
                            style: TextStyle(
                              fontSize: _clamp(screenWidth * 0.035, 12, 18),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    "Submit",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: _clamp(screenWidth * 0.04, 14, 20),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}