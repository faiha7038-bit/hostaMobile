import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

// User state provider
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier();
});

class UserState {
  final String? userId;
  final String? userName;
  final String? userEmail;
  final bool isLoading;

  UserState({
    this.userId,
    this.userName,
    this.userEmail,
    this.isLoading = true,
  });

  UserState copyWith({
    String? userId,
    String? userName,
    String? userEmail,
    bool? isLoading,
  }) {
    return UserState(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(UserState());

  Future<void> initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      userId: prefs.getString('userId'),
      userName: prefs.getString('userName'),
      userEmail: prefs.getString('userEmail'),
      isLoading: false,
    );
  }

  Future<void> refreshUser() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      userId: prefs.getString('userId'),
      userName: prefs.getString('userName'),
      userEmail: prefs.getString('userEmail'),
    );
  }
}

// Hospital details provider
final hospitalDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, hospitalId) async {
  final apiService = ApiService();
  final response = await apiService.getAHospitals(hospitalId);
  return response.data;
});

// Hospital reviews provider
final hospitalReviewsProvider = FutureProvider.family<List<dynamic>, String>((ref, hospitalId) async {
  final apiService = ApiService();
  final response = await apiService.getAHospitalsReview(hospitalId);
  
  if (response.data != null) {
    if (response.data is Map && response.data.containsKey("data")) {
      return response.data["data"] ?? [];
    } else if (response.data is List) {
      return response.data;
    }
  }
  return [];
});

// Review loading state provider
final reviewLoadingProvider = StateProvider<bool>((ref) => false);

// Review operations provider
final reviewOperationsProvider = Provider((ref) {
  return ReviewOperations(ref);
});

class ReviewOperations {
  final Ref ref;

  ReviewOperations(this.ref);

  Future<void> createReview({
    required String hospitalId,
    required double rating,
    required String comment,
    required String userId,
    required String userName,
    required String userEmail,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    ref.read(reviewLoadingProvider.notifier).state = true;

    try {
      final Map<String, dynamic> reviewData = {
        "userId": userId,
        "rating": rating,
        "comment": comment,
        "hospitalId": hospitalId,
      };

      await ApiService().createAHospitalReview(reviewData);
      
      // Refresh reviews
      ref.invalidate(hospitalReviewsProvider(hospitalId));
      onSuccess();
    } catch (e) {
      onError("Error submitting review: $e");
    } finally {
      ref.read(reviewLoadingProvider.notifier).state = false;
    }
  }

  Future<void> updateReview({
    required String reviewId,
    required String hospitalId,
    required double rating,
    required String comment,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    ref.read(reviewLoadingProvider.notifier).state = true;

    try {
      final Map<String, dynamic> reviewData = {
        "rating": rating,
        "comment": comment,
      };

      await ApiService().updateAHospitalReview(reviewId, reviewData);
      
      // Refresh reviews
      ref.invalidate(hospitalReviewsProvider(hospitalId));
      onSuccess();
    } catch (e) {
      onError("Error updating review: $e");
    } finally {
      ref.read(reviewLoadingProvider.notifier).state = false;
    }
  }

  Future<void> deleteReview({
    required String reviewId,
    required String hospitalId,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    ref.read(reviewLoadingProvider.notifier).state = true;

    try {
      await ApiService().deleteAHospitalReview(reviewId);
      
      // Refresh reviews
      ref.invalidate(hospitalReviewsProvider(hospitalId));
      onSuccess();
    } catch (e) {
      onError("Error deleting review: $e");
    } finally {
      ref.read(reviewLoadingProvider.notifier).state = false;
    }
  }
}