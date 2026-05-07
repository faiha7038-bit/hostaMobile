import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

// User data provider
final userDataProvider = StateNotifierProvider<UserDataNotifier, UserDataState>((ref) {
  return UserDataNotifier();
});

class UserDataState {
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? donorData;
  final String? userId;
  final bool isLoading;
  final bool isEditing;
  final bool isSaving;
  final File? imageFile;
  final String? originalName;
  final String? originalEmail;
  final String? originalPhone;

  UserDataState({
    this.userData,
    this.donorData,
    this.userId,
    this.isLoading = true,
    this.isEditing = false,
    this.isSaving = false,
    this.imageFile,
    this.originalName,
    this.originalEmail,
    this.originalPhone,
  });

  UserDataState copyWith({
    Map<String, dynamic>? userData,
    Map<String, dynamic>? donorData,
    String? userId,
    bool? isLoading,
    bool? isEditing,
    bool? isSaving,
    File? imageFile,
    String? originalName,
    String? originalEmail,
    String? originalPhone,
  }) {
    return UserDataState(
      userData: userData ?? this.userData,
      donorData: donorData ?? this.donorData,
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
      imageFile: imageFile ?? this.imageFile,
      originalName: originalName ?? this.originalName,
      originalEmail: originalEmail ?? this.originalEmail,
      originalPhone: originalPhone ?? this.originalPhone,
    );
  }
}

class UserDataNotifier extends StateNotifier<UserDataState> {
  final ApiService _apiService = ApiService();

  UserDataNotifier() : super(UserDataState());

  Future<void> loadUserIdAndProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');

      state = state.copyWith(userId: storedUserId);

      print("📱 Loaded user ID for profile: $storedUserId");

      if (storedUserId != null && storedUserId.isNotEmpty) {
        await loadProfile();
      } else {
        state = state.copyWith(isLoading: false);
        print("❌ No user ID found for profile");
      }
    } catch (e) {
      print("❌ Error loading user ID: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadProfile() async {
    if (state.userId == null || state.userId!.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      // Always load user data
      final userRes = await _apiService.getAUser(state.userId!);

      // Try to load donor data, but handle 404 gracefully
      dynamic donorRes;
      try {
        donorRes = await _apiService.getADonor(state.userId!);
        print("✅ Donor data found for user");
      } catch (e) {
        // Check if it's a 404 error (donor not found) - this is normal for non-donors
        if (e.toString().contains('404') ||
            e.toString().contains('Client error')) {
          print("ℹ️ No donor record found for user (this is normal for non-donors)");
          donorRes = null;
        } else {
          // Re-throw if it's a different error
          print("❌ Error loading donor data: $e");
          donorRes = null;
        }
      }

      final userData = userRes.data?['data'] ?? userRes.data ?? {};
      
      // Handle donor data based on the response
      Map<String, dynamic>? donorData;
      if (donorRes == null) {
        donorData = null; // No donor record exists
      } else if (donorRes.data is List) {
        donorData = donorRes.data.isNotEmpty ? donorRes.data[0] : {};
      } else {
        donorData = donorRes.data ?? {};
      }

      // Set original values
      final originalName = (userData['name'] ?? '').toString();
      final originalEmail = (userData['email'] ?? '').toString();
      final originalPhone = (userData['phone'] ?? '').toString();

      state = state.copyWith(
        userData: userData,
        donorData: donorData,
        isLoading: false,
        originalName: originalName,
        originalEmail: originalEmail,
        originalPhone: originalPhone,
      );
    } catch (e) {
      print("❌ Error loading profile: $e");
      state = state.copyWith(isLoading: false);
      throw e;
    }
  }

  void enableEditing() {
    state = state.copyWith(isEditing: true);
  }

  void cancelEditing() {
    state = state.copyWith(
      isEditing: false,
      imageFile: null,
    );
  }

  Future<void> saveProfile({
    required String name,
    required String email,
    required String phone,
    required BuildContext context,
  }) async {
    if (state.userId == null || state.userId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User ID not found")),
      );
      return;
    }

    if (name.trim().isEmpty || email.trim().isEmpty || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      state = state.copyWith(isSaving: true);

      final payload = {
        "name": name.trim(),
        "email": email.trim(),
        "phone": phone.trim(),
      };

      // Use the new method that handles image upload
      await _apiService.updateUserWithImage(state.userId!, payload, state.imageFile);

      // Update original values
      state = state.copyWith(
        isEditing: false,
        isSaving: false,
        imageFile: null,
        originalName: name,
        originalEmail: email,
        originalPhone: phone,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully"),
          backgroundColor: Colors.green,
        ),
      );

      // Reload to get updated data
      await loadProfile();
    } on DioException catch (dioError) {
      state = state.copyWith(isSaving: false);
      String errorMessage = "Something went wrong";

      if (dioError.response != null) {
        try {
          errorMessage = dioError.response?.data['message'] ?? errorMessage;
        } catch (_) {}
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      state = state.copyWith(isSaving: false);
      print("❌ Error saving profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving profile: $e")),
      );
    }
  }

  Future<void> pickImage() async {
    if (!state.isEditing) return;

    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        state = state.copyWith(imageFile: File(pickedFile.path));
        print("📸 Image selected: ${pickedFile.path}");
      }
    } catch (e) {
      print("❌ Error picking image: $e");
    }
  }

  Future<void> deleteDonor(BuildContext context) async {
    try {
      final donorId = state.donorData?['_id']?.toString();
      if (donorId == null) {
        throw Exception("Donor ID not found");
      }

      await _apiService.deleteDonor(donorId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Donor record deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );

      state = state.copyWith(donorData: null);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bloodId');
    } on DioException catch (dioError) {
      String errorMessage = "Something went wrong";

      if (dioError.response != null) {
        try {
          errorMessage = dioError.response?.data['message'] ?? errorMessage;
        } catch (_) {}
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      print("❌ Error deleting donor: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting donor: $e")),
      );
    }
  }
}

// Text controllers provider
final nameControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final emailControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final phoneControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

// Sync controllers with user data
final syncControllersProvider = Provider((ref) {
  final userDataState = ref.watch(userDataProvider);
  final nameController = ref.read(nameControllerProvider);
  final emailController = ref.read(emailControllerProvider);
  final phoneController = ref.read(phoneControllerProvider);
  
  if (userDataState.originalName != null && nameController.text.isEmpty) {
    nameController.text = userDataState.originalName!;
  }
  if (userDataState.originalEmail != null && emailController.text.isEmpty) {
    emailController.text = userDataState.originalEmail!;
  }
  if (userDataState.originalPhone != null && phoneController.text.isEmpty) {
    phoneController.text = userDataState.originalPhone!;
  }
  
  return null;
});