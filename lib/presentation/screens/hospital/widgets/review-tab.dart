import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hosta/common/login_dialoge.dart';
import 'package:hosta/data/models/review_model.dart';
import 'package:hosta/services/api_service.dart';
import 'package:hosta/services/socket-service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

// ========== REVIEWS TAB - MAIN COMPONENT ==========
class ReviewsTab extends StatefulWidget {
  final String hospitalId;

  const ReviewsTab({
    super.key,
    required this.hospitalId,
  });

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  // Review form state
  double rating = 0;
  final TextEditingController reviewController = TextEditingController();
  double avgRating = 0;
  int totalReviews = 0;
  int selectedRating = 0;
  bool showAllReviews = false;
  bool isreviewsLoading = false;
  late Function(dynamic) _onReviewEvent;
  late Function(dynamic) _onRatingEvent;
  bool isLoading = false;
  String? currentUserImage;
  Map<int, int> ratingBreakdown = {
    5: 0,
    4: 0,
    3: 0,
    2: 0,
    1: 0,
  };
  // Edit review state
  String? editingReviewId;
  double editingRating = 0;

  List<Review> reviews = [];
  Review? myReview;

  int currentPage = 1;
  bool hasMore = true;
  bool loadMoreLoading = false;
  String? currentUserName;

  final TextEditingController editingReviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRating();
    fetchReviews();
    fetchMyReview();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    reviewController.dispose();
    editingReviewController.dispose();
    SocketService().removeListener("REVIEW_REGISTERED", _onReviewEvent);
    SocketService().removeListener("REVIEW_UPDATED", _onReviewEvent);
    SocketService().removeListener("RATING_REGISTERED", _onRatingEvent);
    SocketService().removeListener("RATING_UPDATED", _onRatingEvent);
    super.dispose();
  }

  void _setupSocketListeners() {
    _onReviewEvent = (data) async {
      await _fetchRating();
      await fetchReviews();
      await fetchMyReview();
      if (mounted) setState(() {});
    };

    _onRatingEvent = (data) async {
      await _fetchRating();
      if (mounted) setState(() {});
    };

    SocketService().addListener(
      ["REVIEW_REGISTERED", "REVIEW_UPDATED"],
      _onReviewEvent,
    );

    SocketService().addListener(
      ["RATING_REGISTERED", "RATING_UPDATED"],
      _onRatingEvent,
    );
  }

  Future<void> _fetchRating() async {
    try {
      final res = await ApiService().getRating(
        hospitalId: widget.hospitalId,
        doctorId: "",
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

  Future<void> fetchReviews({bool loadMore = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId');

      final res = await ApiService().getReviews(
        hospitalId: widget.hospitalId,
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

  Future<void> fetchMyReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) return;

      final res = await ApiService().getReviews(
        hospitalId: widget.hospitalId,
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

  Future<void> createReview(
    int rating,
    String comment,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("userId");

      await ApiService().createReview({
        "userId": int.parse(userId!),
        "hospitalId": int.parse(widget.hospitalId),
        "rating": rating,
        "comment": comment,
      });

      await _fetchRating();
      await fetchReviews();
      await fetchMyReview();
    } catch (e) {
      
    }
  }

  Future<void> updateReview(
    String reviewId,
    int rating,
    String comment,
  ) async {
    try {
      await ApiService().updateReview(
        reviewId,
        {
          "rating": rating,
          "comment": comment,
        },
      );

      await _fetchRating();
      await fetchReviews();
      await fetchMyReview();
    } catch (e) {
      
    }
  }

  Future<void> deleteReview(
    String reviewId,
  ) async {
    try {
      await ApiService().deleteReview(reviewId);

      setState(() {
        myReview = null;
      });

      await _fetchRating();
      await fetchReviews();
    } catch (e) {
      
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Clamped responsive values
    final double padding = _clamp(screenWidth * 0.04, 12, 24);
    final double titleSize = _clamp(screenWidth * 0.045, 16, 24);
    final double starSize = _clamp(screenWidth * 0.07, 24, 40);
    final double iconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double spacing = _clamp(screenHeight * 0.02, 12, 24);
    final double cardPadding = _clamp(screenWidth * 0.03, 8, 16);
    final double radius = _clamp(screenWidth * 0.03, 8, 16);
    final double textSize = _clamp(screenWidth * 0.04, 14, 22);
    final double smallTextSize = _clamp(screenWidth * 0.03, 10, 16);
    final double avatarRadius = _clamp(screenWidth * 0.045, 14, 24);
    final double avgTextSize = _clamp(screenWidth * 0.12, 32, 56);
    final double ratingStarSize = _clamp(screenWidth * 0.045, 14, 24);
    final double barHeight = _clamp(screenHeight * 0.008, 4, 10);
    final double dividerThickness = _clamp(screenWidth * 0.0015, 0.5, 2);
    final double reviewPadding = _clamp(screenWidth * 0.03, 8, 16);
    final double reviewRadius = _clamp(screenWidth * 0.03, 8, 16);
    final double reviewTileMargin = _clamp(screenHeight * 0.012, 6, 16);
    final double writeReviewPadding = _clamp(screenWidth * 0.03, 8, 16);
    final double myReviewPadding = _clamp(screenWidth * 0.04, 12, 24);
    final double popupIconSize = _clamp(screenWidth * 0.04, 12, 20);

    return Padding(
      padding: EdgeInsets.all(padding),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Ratings and Reviews",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: titleSize,
              ),
            ),

            _ratingOverview(
              screenWidth,
              screenHeight,
              avgRating,
              totalReviews,
              ratingBreakdown,
              avgTextSize,
              ratingStarSize,
              barHeight,
              smallTextSize,
            ),
            SizedBox(height: spacing),

            myReview != null
                ? _buildMyReviewCard(
                    screenWidth,
                    screenHeight,
                    myReview!,
                    avatarRadius,
                    popupIconSize,
                    smallTextSize,
                    radius,
                  )
                : _buildWriteReviewCard(
                    screenWidth,
                    screenHeight,
                    selectedRating,
                    radius,
                    writeReviewPadding,
                    smallTextSize,
                    starSize,
                    cardPadding,
                  ),

            SizedBox(height: spacing),

            Text(
              "Patient Reviews",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: textSize,
              ),
            ),

            SizedBox(height: _clamp(screenHeight * 0.012, 8, 16)),

            if (isreviewsLoading)
              Center(
                child: CircularProgressIndicator(
                  color: Colors.green,
                  strokeWidth: _clamp(screenWidth * 0.008, 2, 6),
                ),
              )
            else if (reviews.isEmpty)
              Text(
                "No reviews yet",
                style: TextStyle(fontSize: smallTextSize),
              )
            else
              Column(
                children: (showAllReviews ? reviews : reviews.take(5))
                    .map((r) => _reviewTile(
                          r,
                          screenWidth,
                          screenHeight,
                          avatarRadius,
                          ratingStarSize,
                          smallTextSize,
                          reviewPadding,
                          reviewRadius,
                          reviewTileMargin,
                        ))
                    .toList(),
              ),

            SizedBox(height: _clamp(screenHeight * 0.012, 8, 16)),

            if (totalReviews > 5 && !showAllReviews)
              TextButton(
                onPressed: () async {
                  setState(() {
                    showAllReviews = true;
                  });
                  currentPage = 2;
                  while (hasMore && currentPage <= 20) {
                    await fetchReviews();
                    currentPage++;
                  }
                },
                child: Text(
                  "See All Reviews",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: smallTextSize,
                  ),
                ),
              ),

            Divider(thickness: dividerThickness),
          ],
        ),
      ),
    );
  }

  Widget _buildWriteReviewCard(
    double screenWidth,
    double screenHeight,
    int selectedRating,
    double radius,
    double padding,
    double smallTextSize,
    double starSize,
    double cardPadding,
  ) {
    return Container(
      padding: EdgeInsets.all(cardPadding),
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
              fontSize: _clamp(screenWidth * 0.04, 14, 22),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            "Tell others what you think",
            style: TextStyle(
              color: Colors.grey,
              fontSize: smallTextSize,
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
                    this.selectedRating = index + 1;
                  });
                  _showReviewDialog(initialRating: index + 1);
                },
                child: Icon(
                  isSelected ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: starSize,
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
                fontSize: _clamp(screenWidth * 0.04, 14, 22),
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
    Review myReview,
    double avatarRadius,
    double popupIconSize,
    double smallTextSize,
    double radius,
  ) {
    return Container(
      padding: EdgeInsets.all(_clamp(screenWidth * 0.04, 12, 24)),
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
              fontSize: _clamp(screenWidth * 0.045, 16, 24),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenHeight * 0.012),
          Row(
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundImage: myReview.imageUrl != null && myReview.imageUrl!.isNotEmpty
                    ? NetworkImage(myReview.imageUrl!)
                    : null,
                child: myReview.imageUrl == null || myReview.imageUrl!.isEmpty
                    ? Text(
                        myReview.name.isNotEmpty
                            ? myReview.name[0].toUpperCase()
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
                      myReview.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: _clamp(screenWidth * 0.04, 14, 22),
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < myReview.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: _clamp(screenWidth * 0.04, 12, 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                iconSize: popupIconSize,
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
                      await ApiService().deleteReview(myReview.id.toString());
                      setState(() {
                        this.myReview = null;
                        reviews = [];
                        currentPage = 1;
                        hasMore = true;
                      });
                      await fetchReviews();
                    }
                  }
                },
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            myReview.comment,
            style: TextStyle(fontSize: smallTextSize),
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
    double avgTextSize,
    double starSize,
    double barHeight,
    double smallTextSize,
  ) {
    return Container(
      padding: EdgeInsets.all(_clamp(screenWidth * 0.04, 12, 24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_clamp(screenWidth * 0.03, 8, 16)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                avgRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: avgTextSize,
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
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: smallTextSize,
                ),
              ),
            ],
          ),
          SizedBox(width: _clamp(screenWidth * 0.05, 12, 32)),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                int star = 5 - i;
                int count = ratingBreakdown[star] ?? 0;
                double percent = totalReviews == 0 ? 0 : count / totalReviews;
                return Row(
                  children: [
                    Text(
                      "$star",
                      style: TextStyle(fontSize: smallTextSize),
                    ),
                    SizedBox(width: _clamp(screenWidth * 0.015, 4, 12)),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: barHeight,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation(Colors.blue),
                      ),
                    ),
                    SizedBox(width: _clamp(screenWidth * 0.015, 4, 12)),
                    Text(
                      count.toString(),
                      style: TextStyle(fontSize: smallTextSize),
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

  Widget _reviewTile(
    Review review,
    double screenWidth,
    double screenHeight,
    double avatarRadius,
    double starSize,
    double smallTextSize,
    double padding,
    double radius,
    double margin,
  ) {
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
                radius: avatarRadius,
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
                    fontSize: _clamp(screenWidth * 0.04, 14, 22),
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
          SizedBox(height: screenHeight * 0.008),
          Text(
            review.comment,
            style: TextStyle(
              color: Colors.grey,
              fontSize: smallTextSize,
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
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: _clamp(screenWidth * 0.035, 12, 18),
                      ),
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
                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getString('userId');

                      final body = {
                        "userId": int.parse(userId!),
                        "hospitalId": widget.hospitalId,
                        "rating": stars,
                        "comment": controller.text.trim(),
                      };

                      final res = await ApiService().createReview(body);

                      Navigator.pop(context);

                      await fetchMyReview();
                      await fetchReviews();
                      await _fetchRating();

                      setState(() {
                        selectedRating = 0;
                      });
                    } on DioException catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "You can review this hospital only after completing your consultation.",
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

  void _showEditReviewDialog() {
    final controller = TextEditingController(text: myReview!.comment);
    int stars = myReview!.rating;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                "Edit Review",
                style: TextStyle(
                  fontSize: _clamp(screenWidth * 0.045, 16, 24),
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
                          size: _clamp(screenWidth * 0.07, 24, 40),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: screenHeight * 0.012),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          _clamp(screenWidth * 0.025, 8, 16),
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
                    await ApiService().updateReview(
                      myReview!.id.toString(),
                      {
                        "rating": stars,
                        "comment": controller.text.trim(),
                      },
                    );

                    Navigator.pop(context);

                    await fetchMyReview();
                    await fetchReviews();

                    setState(() {});
                  },
                  child: Text(
                    "Update",
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