import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hosta/data/models/doctor_model.dart';
import 'package:hosta/data/models/review_model.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:hosta/presentation/screens/booking/register_booking.dart';
import 'package:hosta/services/socket-service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

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
    // Use the doctor passed from previous screen
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

    log("⭐ REVIEW/RATING EVENT => $data");

    await _fetchRating();
    await _fetchMyReview();

    currentPage = 1;
    hasMore = true;

    await _fetchReviews();

    if (mounted) {
      setState(() {});
    }
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

  log("USER NAME => ${prefs.getString("userName")}");
  log("USER IMAGE => ${prefs.getString("userImage")}");
  setState(() {
    currentUserName = prefs.getString("userName") ?? "User";
    currentUserImage = prefs.getString("userImage"); // if stored
  });
}
Future<void> _fetchRating() async {
  try {
    final res = await ApiService().getRating(
      hospitalId: "",
      //hospitalId: widget.doctor.hospitalId.toString(),
      doctorId: widget.doctor.id.toString(),
    );
log("RATING RESPONSE => $res");
log("HOSPITAL ID => ${widget.doctor.hospitalId}");
log("DOCTOR ID => ${widget.doctor.id}");
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

    log("AVG => $avgRating");
    log("TOTAL => $totalReviews");
    log("BREAKDOWN => $ratingBreakdown");
  } catch (e) {
    log("RATING ERROR => $e");
  }
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
              title: const Text("Edit Review"),
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
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
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
                  child: const Text("Update"),
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
      log("PAGINATION => ${res.data['pagination']}");
log("fetchres${res.data}");
log("CURRENT PAGE => $currentPage");

log("HAS NEXT PAGE => ${res.data['pagination']['hasNextPage']}");
      final data = res.data['data'] as List;
log("DATA LENGTH => ${data.length}");
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
        log("HAS MORE => ${res.data['pagination']['hasNextPage']}");
        log("REVIEWS => ${newData.length}");
      });
    } catch (e) {
      setState(() => loadMoreLoading = false);
      log("REVIEWS ERROR => $e");
      
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
log("GET REVIEWS => ${res.data}");
      final data = res.data['data'] as List;

      for (final item in data) {
        if (item['userId'].toString() == userId) {
          setState(() {
            myReview = Review.fromJson(item);
          });
          break;
        }
      }
    } catch (e) {
      log("MY REVIEW ERROR => $e");
    }
  }

  Future<void> _fetchDoctorDetails() async {
    try {
      final response =
          await ApiService().getDoctorById(widget.doctor.id.toString());

      log("DOCTOR RESPONSE => ${response.data}");

      if (response.data['success'] == true) {
        setState(() {
          doctorDetails = Doctor.fromJson(response.data['data']);
        });
      }
    } catch (e) {
      log("ERROR => $e");
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
        body:
            const Center(child: CircularProgressIndicator(color: Colors.green)),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.green),
                  const SizedBox(width: 10),
                  Text(
                    "${doctorDetails!.appointmentCount} Total Appointments",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// TIMINGS
            Text(
              "Available Days",
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: screenHeight * 0.012),
            Wrap(
              spacing: 8,
              children: doctorDetails!.availableDays.map((day) {
                return Chip(
                  label: Text(day),
                  backgroundColor: Colors.green.shade50,
                  avatar:
                      const Icon(Icons.check, color: Colors.green, size: 18),
                );
              }).toList(),
            ),

            SizedBox(height: 20),

            /// Morning Session
            if (doctorDetails!.consulting.morningSession != null)
              _timingTile("Morning Session",
                  doctorDetails!.consulting.morningSession!.range, screenWidth),

            /// Evening Session
            if (doctorDetails!.consulting.eveningSession != null)
              _timingTile("Evening Session",
                  doctorDetails!.consulting.eveningSession!.range, screenWidth),

            /// Outdoor Consulting Timings
            if (doctorDetails!.outDoorConsulting != null)
              _timingTile("Outdoor Consulting",
                  doctorDetails!.outDoorConsulting!.time.range, screenWidth),

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
              " ${doctorDetails!.displayName} is a specialized ${doctorDetails!.specialty.toLowerCase()} with qualification ${doctorDetails!.qualification}. "
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
                    children: doctorDetails!.knowLanguages
                        .map((lang) => Chip(
                              label: Text(lang),
                              backgroundColor: Colors.green[50],
                            ))
                        .toList(),
                  ),
                  SizedBox(height: screenHeight * 0.025),
                ],
              ),
              Text("Ratings and Reviews",style: TextStyle(color: Colors.black,fontWeight:FontWeight.bold),),
               SizedBox(height: screenHeight * 0.025),
_ratingOverview(),
   SizedBox(height: screenHeight * 0.025),
           /// REVIEWS
            
            myReview != null ? _buildMyReviewCard() : _buildWriteReviewCard(),

            const SizedBox(height: 20),

            Text(
              "Patient Reviews",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            if (reviewsLoading)
              const Center(child: CircularProgressIndicator())
            else if (reviews.isEmpty)
              const Text("No reviews yet")
            else
             Column(
  children: (showAllReviews ? reviews : reviews.take(5))
      .map((r) => _reviewTile(r, screenWidth))
      .toList(),
),

            //const SizedBox(height: 10),
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
     child: const Text("See All Reviews",
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
            SizedBox(height: screenHeight * 0.012),

            // SizedBox(height: screenHeight * 0.03),

            /// BOOK BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(10)),
                    backgroundColor: Colors.green),
                onPressed:
                  (doctorDetails!.bookingOpen && doctorDetails!.isActive)
                    ? () async {
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString('userId') ?? '';

                        if (userId.isEmpty) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text(
                                "Login Required",
                                style: TextStyle(color: Colors.green),
                              ),
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
                                        builder: (_) => const Signin(),
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
                            builder: (context) =>
                                RegisterBooking(doctor: widget.doctor),
                          ),
                        );
                      }
                    : null,
                child: Text(
                 ( doctorDetails!.bookingOpen && doctorDetails!.isActive) ? "Book Appointment" : "CLOSED",
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
              shape: BoxShape.circle,
            ),
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
          SizedBox(width: isSmallScreen ? 12.0 : 20.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.displayName,
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
                Text(
                  "${doctor.experience} Years Experience",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.star,
                        size: isSmallScreen ? 14 : 16, color: Colors.amber),
                   Text("$avgRating",
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                    Text(" ($totalReviews)",
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
          Icon(Icons.currency_rupee,
              color: Colors.green, size: isSmallScreen ? 20 : 24),
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
          Icon(Icons.access_time,
              size: isSmallScreen ? 16 : 18, color: Colors.green),
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

  Widget _reviewTile(Review review, double screenWidth) {
    final isSmallScreen = screenWidth < 600;

    final name = review.name;
    final imageUrl = review.imageUrl;
    final rating = review.rating;
    final comment = review.comment;

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
          /// NAME + STARS
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage:
                    imageUrl != null && imageUrl.toString().isNotEmpty
                        ? NetworkImage(imageUrl)
                        : null,
                child: imageUrl == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : "P",
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          /// COMMENT
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

  Widget _buildWriteReviewCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Rate this doctor",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Tell others what you think",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
         Row(
  mainAxisAlignment: MainAxisAlignment.start,
  children: List.generate(5, (index) {
    final isSelected = index < selectedRating;

    return GestureDetector(
    onTap: () async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');

  if (userId == null || userId.isEmpty) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Login Required"),
        content: const Text(
          "Please login to rate this doctor.",
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
                  builder: (_) => const Signin(),
                ),
              );
            },
            child: const Text("Login"),
          ),
        ],
      ),
    );
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
        size: 28,
      ),
    );
  }),
),
          const SizedBox(height: 12),
          GestureDetector(
onTap: () async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');

  if (userId == null || userId.isEmpty) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Login Required",
          style: TextStyle(color: Colors.green),
        ),
        content: const Text(
          "Please login to write a review.",
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
                  builder: (_) => const Signin(),
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

  _showReviewDialog(initialRating: selectedRating);
},
            child: Text(
              "Write a review",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyReviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Review",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundImage:
                    myReview!.imageUrl != null && myReview!.imageUrl!.isNotEmpty
                        ? NetworkImage(myReview!.imageUrl!)
                        : null,
                child: myReview!.imageUrl == null || myReview!.imageUrl!.isEmpty
                    ? Text(
                        myReview!.name.isNotEmpty
                            ? myReview!.name[0].toUpperCase()
                            : "U",
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      myReview!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
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
                          size: 16,
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
                        title: const Text("Delete Review"),
                        content: const Text(
                          "Are you sure you want to delete this review?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );

 if (confirm == true)  {
  await ApiService().deleteReview(myReview!.id.toString());

  setState(() {
    myReview = null;
    reviews = [];
    currentPage = 1;
    hasMore = true;
  });
await _fetchRating();
  await _fetchReviews(); // fresh reload
}
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(myReview!.comment),
        ],
      ),
    );
  }
Widget _ratingOverview() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        
        /// LEFT SIDE (4.5 + stars + count)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              avgRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 48,
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
                  size: 18,
                );
              }),
            ),

            const SizedBox(height: 5),

            Text(
              "$totalReviews reviews",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),

        const SizedBox(width: 20),

        /// RIGHT SIDE (bars)
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
                  Text("$star"),
                  const SizedBox(width: 6),

                  Expanded(
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade300,
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.blue),
                    ),
                  ),

                  const SizedBox(width: 6),

                  Text(count.toString()),
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

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),

            /// ⭐ HEADER
            title: const Text(
              "Add Review",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// 👤 USER INFO ROW
Row(
  children: [
    CircleAvatar(
      backgroundColor: Colors.green,
      backgroundImage: (currentUserImage != null && currentUserImage!.isNotEmpty)
          ? NetworkImage(currentUserImage!)
          : null,
      child: (currentUserImage == null || currentUserImage!.isEmpty)
          ? const Icon(Icons.person, color: Colors.white)
          : null,
    ),

    const SizedBox(width: 10),

    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentUserName ?? "User",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text(
          "Posting publicly",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    ),
  ],
),

                const SizedBox(height: 16),

                /// ⭐ STARS
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
                          isSelected
                              ? Icons.star
                              : Icons.star_border,
                          size: 34,
                          color: isSelected
                              ? Colors.amber
                              : Colors.grey.shade400,
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 12),

                /// ✍️ COMMENT BOX
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Describe your experience (optional)",
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.green),
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                onPressed: () async {
                   log("SUBMIT CLICKED");
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
log("createreview=${res.data}");
  Navigator.pop(context);

  await _fetchMyReview();
  await _fetchReviews();
  await _fetchRating();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.green,
      content: Text("You can review only after your consultation is completed."),
    ),
  );
}
                 // setState(() {});
                },
                child: const Text(
                  "Submit",
                  style: TextStyle(color: Colors.white),
                ),
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