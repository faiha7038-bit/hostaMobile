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

    widget.onCreateReview();
    _clearReviewForm();
  }

  void _handleUpdateReview() {
    if (editingRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a rating")),
      );
      return;
    }

    if (editingReviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write a review")),
      );
      return;
    }

    widget.onUpdateReview(editingReviewId!);
    _cancelEdit();
  }

  void _handleDeleteReview(String reviewId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Review"),
        content: const Text("Are you sure you want to delete this review?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDeleteReview(reviewId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Authentication Status
          if (widget.currentUserId == null)
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
            child: widget.isReviewLoading
                ? const Center(child: CircularProgressIndicator())
                : widget.reviews.isEmpty
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
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
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
                            margin: const EdgeInsets.only(bottom: 10),
                            color: isTemp
                                ? Colors.grey[100]
                                : (isUpdating
                                    ? Colors.blue[50]
                                    : (isSubmitting
                                        ? Colors.yellow[50]
                                        : null)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.green[100],
                                        child: Text(
                                          userInitial,
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (isSubmitting)
                                              const Text(
                                                "Submitting...",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              )
                                            else if (isUpdating)
                                              const Text(
                                                "Updating...",
                                                style: TextStyle(
                                                  fontSize: 12,
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
                                            size: 18,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  if (comment.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(comment),
                                  ],
                                  if (reviewDate.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(reviewDate),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                  if (isOwnReview && !isTemp && !isSubmitting && !isUpdating) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _startEditReview(review),
                                          icon: const Icon(Icons.edit, size: 16),
                                          label: const Text("Edit"),
                                          style: TextButton.styleFrom(
                                            minimumSize: Size.zero,
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          onPressed: () => _handleDeleteReview(review["_id"]),
                                          icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                          label: const Text("Delete", style: TextStyle(color: Colors.red)),
                                          style: TextButton.styleFrom(
                                            minimumSize: Size.zero,
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
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

  // ========== CREATE REVIEW FORM ==========
  Widget _buildCreateReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Write a Review:",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        _buildRatingStars(
          rating,
          (newRating) => setState(() => rating = newRating),
          widget.currentUserId != null,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: reviewController,
          decoration: InputDecoration(
            hintText: widget.currentUserId == null 
                ? "Please login to write a review"
                : "Share your experience...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          maxLines: 3,
          enabled: widget.currentUserId != null && !widget.isReviewLoading,
        ),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton.icon(
            onPressed: widget.currentUserId == null 
                ? widget.onNavigateToLogin 
                : (widget.isReviewLoading ? null : _handleCreateReview),
            icon: Icon(
              widget.currentUserId == null ? Icons.login : Icons.send, 
              color: Colors.white
            ),
            label: Text(
              widget.currentUserId == null 
                  ? "Login to Review" 
                  : (widget.isReviewLoading ? "Submitting..." : "Submit Review"),
              style: const TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.currentUserId == null ? Colors.orange : Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========== EDIT REVIEW FORM ==========
  Widget _buildEditReviewForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Edit Your Review:",
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16, 
            color: Colors.green
          ),
        ),
        const SizedBox(height: 10),
        _buildRatingStars(
          editingRating,
          (newRating) => setState(() => editingRating = newRating),
          true,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: editingReviewController,
          decoration: InputDecoration(
            hintText: "Edit your review...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          maxLines: 3,
          enabled: !widget.isReviewLoading,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: widget.isReviewLoading ? null : _handleUpdateReview,
              icon: const Icon(Icons.save, color: Colors.white),
              label: Text(
                widget.isReviewLoading ? "Updating..." : "Update Review",
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: widget.isReviewLoading ? null : _cancelEdit,
              icon: const Icon(Icons.cancel),
              label: const Text("Cancel"),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========== RATING STARS WIDGET ==========
  Widget _buildRatingStars(double currentRating, Function(double) onRatingChanged, bool isEnabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < currentRating ? Icons.star : Icons.star_border,
            color: isEnabled ? Colors.amber : Colors.grey,
            size: 30,
          ),
          onPressed: isEnabled 
              ? () => onRatingChanged(index + 1.0)
              : widget.onNavigateToLogin,
        );
      }),
    );
  }
}