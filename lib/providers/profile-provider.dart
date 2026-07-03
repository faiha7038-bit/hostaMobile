import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';


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
  bool clearImage = false,
}) {
  return UserDataState(
    userData: userData ?? this.userData,
    donorData: donorData ?? this.donorData,
    userId: userId ?? this.userId,
    isLoading: isLoading ?? this.isLoading,
    isEditing: isEditing ?? this.isEditing,
    isSaving: isSaving ?? this.isSaving,

    imageFile: clearImage
        ? null
        : imageFile ?? this.imageFile,

    originalName: originalName ?? this.originalName,
    originalEmail: originalEmail ?? this.originalEmail,
    originalPhone: originalPhone ?? this.originalPhone,
  );
}

}

class UserDataNotifier extends StateNotifier<UserDataState> {
Future<File> _compressImage(File file) async {
  try {
    final originalSize = await file.length();

    // ചെറിയ image ആണെങ്കിൽ compress വേണ്ട
    if (originalSize < 150 * 1024) {
      return file;
    }

    final dir = await getTemporaryDirectory();

    final targetPath =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 70,
      minWidth: 800,
      minHeight: 800,
      format: CompressFormat.jpeg,
    );

    if (compressed == null) {
      return file;
    }

    final compressedFile = File(compressed.path);

    
    if (await compressedFile.length() >= originalSize) {
      return file;
    }

    return compressedFile;
  } catch (e) {
   
    return file;
  }
}
Future<void> deleteProfileImage() async {
  try {
    final imageUrl = state.userData?['imageUrl'];

    if (imageUrl == null || imageUrl.toString().isEmpty) {
      return;
    }

    final key =
        imageUrl.toString().split('.amazonaws.com/').last;

  

    await ApiService().deleteProfileImage(
      key,
      state.userId!,
    );

    final updatedUserData =
        Map<String, dynamic>.from(state.userData ?? {});

    updatedUserData['imageUrl'] = null;

   
state = state.copyWith(
  clearImage: true,
  userData: updatedUserData,
);
    await loadProfile();

  
  } catch (e) {
   
  }
}
  final ApiService _apiService = ApiService();

  UserDataNotifier() : super(UserDataState());
  

  Future<void> loadUserIdAndProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');

      state = state.copyWith(userId: storedUserId);

     

      if (storedUserId != null && storedUserId.isNotEmpty) {
        await loadProfile();
      } else {
        state = state.copyWith(isLoading: false);
       
      }
    } catch (e) {
     
      state = state.copyWith(isLoading: false);
    }
  }
Future<void> loadProfile({int retryCount = 0}) async {
  if (state.userId == null || state.userId!.isEmpty) {
    state = state.copyWith(isLoading: false);
    return;
  }

  state = state.copyWith(isLoading: true);
  try {
    final userRes = await _apiService.getAUser(state.userId!);
    final innerData = userRes.data?['data'] ?? userRes.data;
    if (innerData == null) throw Exception("No user data");

    state = state.copyWith(
      userData: innerData,
      isLoading: false,
      originalName: innerData['name']?.toString() ?? '',
      originalEmail: innerData['email']?.toString() ?? '',
      originalPhone: innerData['phone']?.toString() ?? '',
    );
  } catch (e) {
    // Retry on 503 (server temporary error)
    if (e is DioException && e.response?.statusCode == 503 && retryCount < 3) {
    
      await Future.delayed(Duration(seconds: 2));
      return loadProfile(retryCount: retryCount + 1);
    }
   
    state = state.copyWith(isLoading: false);
    // Optionally show a user message
  }
}

  void enableEditing() {
    state = state.copyWith(isEditing: true);
  }

  void cancelEditing() {
    state = state.copyWith(
  isEditing: false,
  clearImage: true,
);
   
  }

Future<void> saveProfile({
  required String name,
  required String email,
  required String phone,
  required BuildContext context,
}) async {
  try {
    state = state.copyWith(isSaving: true);

   String? imageUrl;

// 1. upload image if selected
if (state.imageFile != null) {
  final res = await _apiService.uploadProfileImage(
    state.imageFile!,
    state.userId!,
  );

  final key = res["key"];

  // 🔥 FIX: build proper URL
imageUrl = res["imageUrl"];
}

    // 2. update user
   final payload = {
  "name": name.trim(),
  "email": email.trim(),
  "phone": phone.trim(),
  if (imageUrl != null) "imageUrl": imageUrl,
};

    await _apiService.updateUser(state.userId!, payload);

    // 3. update state
    state = state.copyWith(
      isSaving: false,
      isEditing: false,
      imageFile: null,
      originalName: name,
      originalEmail: email,
      originalPhone: phone,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated")),
    );

    await loadProfile();
  } catch (e) {
    state = state.copyWith(isSaving: false);
   
  }
}

Future<void> pickImage() async {
  try {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile == null) return;

    // Crop
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.green,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (croppedFile == null) return;

    final compressedFile = await _compressImage(File(croppedFile.path));
    state = state.copyWith(imageFile: compressedFile);
  } catch (e) {

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

