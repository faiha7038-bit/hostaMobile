import 'package:flutter/material.dart';

// ========== REVIEWS TAB - MAIN COMPONENT ==========
class ReviewsTab extends StatefulWidget {
  final String hospitalId;
  final List<dynamic> reviews;
  final String? currentUserId;
  final String? currentUserName;
  final String? currentUserEmail;
  final bool isReviewLoading;
  final VoidCallback onCreateReview;
  final Function(String) onUpdateReview;
  final Function(String) onDeleteReview;
  final VoidCallback onNavigateToLogin;
  final Function onInitializeUser;

  const ReviewsTab({
    super.key,
    required this.hospitalId,
    required this.reviews,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserEmail,
    required this.isReviewLoading,
    required this.onCreateReview,
    required this.onUpdateReview,
    required this.onDeleteReview,
    required this.onNavigateToLogin,
    required this.onInitializeUser,
  });

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  // Review form state
  double rating = 0;
  final TextEditingController reviewController = TextEditingController();
  
  // Edit review state
  String? editingReviewId;
  double editingRating = 0;
  final TextEditingController editingReviewController = TextEditingController();

  @override
  void dispose() {
    reviewController.dispose();
    editingReviewController.dispose();
    super.dispose();
  }

  void _clearReviewForm() {
    reviewController.clear();
    setState(() {
      rating = 0;
    });
  }

  void _startEditReview(Map<String, dynamic> review) {
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

  void _handleCreateReview() {
    if (widget.currentUserId == null) {
      widget.onNavigateToLogin();
      return;
    }

    if (rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a rating")),
      );
      return;
    }

    if (reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please write a review")),
      );
      return;
    }

    widget.onCreateReview();
    _clearReviewForm();
  }

  void _handleUpdateReview() {
    if (editingRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a rating")),
      );
      return;
    }

    if (editingReviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please write a review")),
      );
      return;
    }

    widget.onUpdateReview(editingReviewId!);
    _cancelEdit();
  }

  void _handleDeleteReview(String reviewId) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Review",
          style: TextStyle(fontSize: screenWidth * 0.045),
        ),
        content: Text(
          "Are you sure you want to delete this review?",
          style: TextStyle(fontSize: screenWidth * 0.04),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(fontSize: screenWidth * 0.04),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteReview(reviewId);
            },
            child: Text(
              "Delete",
              style: TextStyle(
                color: Colors.red,
                fontSize: screenWidth * 0.04,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for review data
  bool _isCurrentUserReview(Map<String, dynamic> review) {
    try {
      if (widget.currentUserId == null) return false;
      if (review["userId"] == null) return false;
      final userData = review["userId"];
      final userId = userData["_id"]?.toString();
      return userId == widget.currentUserId;
    } catch (e) {
      return false;
    }
  }

  String _getUserName(Map<String, dynamic> review) {
    try {
      if (review["userId"] == null) return "Anonymous";
      return review["userId"]["name"]?.toString() ?? "Anonymous";
    } catch (e) {
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (_) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        children: [
          // Authentication Status
          if (widget.currentUserId == null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.03),
              margin: EdgeInsets.only(bottom: screenHeight * 0.02),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                border: Border.all(color: Colors.orange, width: screenWidth * 0.0025),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Colors.orange[700],
                    size: screenWidth * 0.05,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Text(
                      "Login to submit or manage reviews",
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Reviews List
          Expanded(
            child: widget.isReviewLoading
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: screenWidth * 0.008,
                    ),
                  )
                : widget.reviews.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.reviews,
                              size: screenWidth * 0.16,
                              color: Colors.grey,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              "No reviews yet",
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "Be the first to review!",
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        // ✅ FIX: shrinkWrap false, AlwaysScrollableScrollPhysics
                        shrinkWrap: false,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: widget.reviews.length,
                        itemBuilder: (context, index) {
                          final review = widget.reviews[index];
                          final isOwnReview = _isCurrentUserReview(review);
                          final isTemp = _isTempReview(review);
                          final isSubmitting = _isSubmittingReview(review);
                          final isUpdating = _isUpdatingReview(review);
                          final userName = _getUserName(review);
                          final userInitial = _getUserInitial(userName);
                          final ratingValue = _getRating(review);
                          final comment = _getComment(review);
                          final reviewDate = _getReviewDate(review);

                          return Card(
                            margin: EdgeInsets.only(bottom: screenHeight * 0.0125),
                            color: isTemp
                                ? Colors.grey[100]
                                : (isUpdating
                                    ? Colors.blue[50]
                                    : (isSubmitting
                                        ? Colors.yellow[50]
                                        : null)),
                            child: Padding(
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.green[100],
                                        radius: screenWidth * 0.045,
                                        child: Text(
                                          userInitial,
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.035,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.03),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: screenWidth * 0.04,
                                              ),
                                            ),
                                            if (isSubmitting)
                                              Text(
                                                "Submitting...",
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.03,
                                                  color: Colors.orange,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              )
                                            else if (isUpdating)
                                              Text(
                                                "Updating...",
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.03,
                                                  color: Colors.blue,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(5, (starIndex) {
                                          return Icon(
                                            starIndex < ratingValue
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: screenWidth * 0.045,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  if (comment.isNotEmpty) ...[
                                    SizedBox(height: screenHeight * 0.01),
                                    Text(
                                      comment,
                                      style: TextStyle(fontSize: screenWidth * 0.035),
                                    ),
                                  ],
                                  if (reviewDate.isNotEmpty) ...[
                                    SizedBox(height: screenHeight * 0.005),
                                    Text(
                                      _formatDate(reviewDate),
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                  if (isOwnReview && !isTemp && !isSubmitting && !isUpdating) ...[
                                    SizedBox(height: screenHeight * 0.01),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _startEditReview(review),
                                          icon: Icon(
                                            Icons.edit,
                                            size: screenWidth * 0.04,
                                          ),
                                          label: Text(
                                            "Edit",
                                            style: TextStyle(fontSize: screenWidth * 0.035),
                                          ),
                                          style: TextButton.styleFrom(
                                            minimumSize: Size.zero,
                                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.02),
                                        TextButton.icon(
                                          onPressed: () => _handleDeleteReview(review["_id"]),
                                          icon: Icon(
                                            Icons.delete,
                                            size: screenWidth * 0.04,
                                            color: Colors.red,
                                          ),
                                          label: Text(
                                            "Delete",
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: screenWidth * 0.035,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            minimumSize: Size.zero,
                                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          Divider(thickness: screenWidth * 0.0025),

          // Review Form (Create or Edit)
          if (editingReviewId != null)
            _buildEditReviewForm(screenWidth, screenHeight)
          else
            _buildCreateReviewForm(screenWidth, screenHeight),
        ],
      ),
    );
  }

  // ========== CREATE REVIEW FORM ==========
  Widget _buildCreateReviewForm(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Write a Review:",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.04,
          ),
        ),
        SizedBox(height: screenHeight * 0.0125),
        _buildRatingStars(
          rating,
          (newRating) => setState(() => rating = newRating),
          widget.currentUserId != null,
          screenWidth,
          screenHeight,
        ),
        SizedBox(height: screenHeight * 0.0125),
        TextField(
          controller: reviewController,
          decoration: InputDecoration(
            hintText: widget.currentUserId == null 
                ? "Please login to write a review"
                : "Share your experience...",
            hintStyle: TextStyle(fontSize: screenWidth * 0.035),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenHeight * 0.015,
            ),
          ),
          maxLines: 3,
          enabled: widget.currentUserId != null && !widget.isReviewLoading,
          style: TextStyle(fontSize: screenWidth * 0.035),
        ),
        SizedBox(height: screenHeight * 0.015),
        Center(
          child: ElevatedButton.icon(
            onPressed: widget.currentUserId == null 
                ? widget.onNavigateToLogin 
                : (widget.isReviewLoading ? null : _handleCreateReview),
            icon: Icon(
              widget.currentUserId == null ? Icons.login : Icons.send, 
              color: Colors.white,
              size: screenWidth * 0.05,
            ),
            label: Text(
              widget.currentUserId == null 
                  ? "Login to Review" 
                  : (widget.isReviewLoading ? "Submitting..." : "Submit Review"),
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.04,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.currentUserId == null ? Colors.orange : Colors.green,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.015,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========== EDIT REVIEW FORM ==========
  Widget _buildEditReviewForm(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Edit Your Review:",
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: screenWidth * 0.04, 
            color: Colors.green,
          ),
        ),
        SizedBox(height: screenHeight * 0.0125),
        _buildRatingStars(
          editingRating,
          (newRating) => setState(() => editingRating = newRating),
          true,
          screenWidth,
          screenHeight,
        ),
        SizedBox(height: screenHeight * 0.0125),
        TextField(
          controller: editingReviewController,
          decoration: InputDecoration(
            hintText: "Edit your review...",
            hintStyle: TextStyle(fontSize: screenWidth * 0.035),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenHeight * 0.015,
            ),
          ),
          maxLines: 3,
          enabled: !widget.isReviewLoading,
          style: TextStyle(fontSize: screenWidth * 0.035),
        ),
        SizedBox(height: screenHeight * 0.015),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: widget.isReviewLoading ? null : _handleUpdateReview,
              icon: Icon(
                Icons.save,
                color: Colors.white,
                size: screenWidth * 0.05,
              ),
              label: Text(
                widget.isReviewLoading ? "Updating..." : "Update Review",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.04,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.015,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            TextButton.icon(
              onPressed: widget.isReviewLoading ? null : _cancelEdit,
              icon: Icon(
                Icons.cancel,
                size: screenWidth * 0.05,
              ),
              label: Text(
                "Cancel",
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.015,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========== RATING STARS WIDGET ==========
  Widget _buildRatingStars(
    double currentRating,
    Function(double) onRatingChanged,
    bool isEnabled,
    double screenWidth,
    double screenHeight,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < currentRating ? Icons.star : Icons.star_border,
            color: isEnabled ? Colors.amber : Colors.grey,
            size: screenWidth * 0.075,
          ),
          onPressed: isEnabled 
              ? () => onRatingChanged(index + 1.0)
              : widget.onNavigateToLogin,
        );
      }),
    );
  }
}