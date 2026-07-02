import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hosta/data/models/review_model.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:hosta/services/api_service.dart';
import 'package:hosta/services/socket-service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    log("🔥 Review Event => $data");

    await _fetchRating();
    await fetchReviews();
    await fetchMyReview();

    if (mounted) setState(() {});
  };

  _onRatingEvent = (data) async {
    log("⭐ Rating Event => $data");

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
log("RATING RESPONSE => $res");

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
 Future<void> fetchReviews({bool loadMore = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('userId');

      final res = await ApiService().getReviews(
       hospitalId: widget.hospitalId,
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
    } catch (e) {
      log("MY REVIEW ERROR => $e");
    }
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
    debugPrint(e.toString());
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
    debugPrint(e.toString());
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
    debugPrint(e.toString());
  }
}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
  return Padding(
  padding: EdgeInsets.all(screenWidth * 0.04),
  child: SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        const Text(
          "Ratings and Reviews",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),

        _ratingOverview(),
        const SizedBox(height: 20),

        myReview != null
            ? _buildMyReviewCard()
            : _buildWriteReviewCard(),

        const SizedBox(height: 20),

        Text(
          "Patient Reviews",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * .045,
          ),
        ),

        const SizedBox(height: 10),

        /// ✅ LOADING / EMPTY / DATA (FIXED)
        if (isreviewsLoading)
          const Center(child: CircularProgressIndicator())
        else if (reviews.isEmpty)
          const Text("No reviews yet")
        else
          Column(
            children: (showAllReviews
                    ? reviews
                    : reviews.take(5))
                .map((r) => _reviewTile(r, screenWidth))
                .toList(),
          ),

        const SizedBox(height: 10),

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
            child: const Text(
              "See All Reviews",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        const Divider(),

      ],
    ),
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
        content: const Text("Please login to write a review."),
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
           onTap: () {
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

  await fetchReviews(); // fresh reload
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
  } 
 on DioException catch (e) {
  Navigator.pop(context);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "You can review this hospital only after completing your consultation.",
      ),
    ),
  );
}
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

                    await fetchMyReview();
                    await fetchReviews();

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
}
