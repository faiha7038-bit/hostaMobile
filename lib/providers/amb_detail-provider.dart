import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class AmbulanceListState {
  final List<Map<String, dynamic>> ambulances;
  final bool isLoading;
  final String? errorMessage;

  AmbulanceListState({
    this.ambulances = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  AmbulanceListState copyWith({
    List<Map<String, dynamic>>? ambulances,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AmbulanceListState(
      ambulances: ambulances ?? this.ambulances,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AmbulanceListNotifier extends StateNotifier<AmbulanceListState> {
  final ApiService apiService;
  //String? _currentUserId;  // Store userId for refresh

  AmbulanceListNotifier(this.apiService) : super(AmbulanceListState());

  Future<void> fetchAmbulances({required String userId}) async {
    //_currentUserId = userId;
    state = state.copyWith(isLoading: true);
    try {
      final response = await apiService.getAllAmbulances(userId: userId);
      log("FETCH RESPONSE => ${response.data}");
      final data = response.data['data'] as List? ?? [];
      final List<Map<String, dynamic>> ambulances = data.map((e) => e as Map<String, dynamic>).toList();
      state = state.copyWith(ambulances: ambulances, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createAmbulance(Map<String, dynamic> payload) async {
    try {
      final response = await apiService.createAmbulance(payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
         // if (_currentUserId != null) await fetchAmbulances(userId: _currentUserId!);
          return true;
        }
      }
      return false;
    } on DioException catch (e) {
      log("CREATE ERROR => $e");
      return false;
    }
  }

  Future<bool> editAmbulance(String ambulanceId, Map<String, dynamic> updatedData) async {
    try {
      final response = await apiService.editAmbulance(ambulanceId, updatedData);
      log("EDIT response status: ${response.statusCode}");
      if (response.statusCode == 200) {
        //if (_currentUserId != null) await fetchAmbulances(userId: _currentUserId!);
        return true;
      }
      return false;
    } catch (e) {
      log("EDIT ERROR: $e");
      return false;
    }
  }

Future<bool> deleteAmbulance(String ambulanceId) async {
  try {
    final response = await apiService.deleteAmbulance(ambulanceId);

    log("DELETE response status: ${response.statusCode}");

    if (response.statusCode == 200) {
      // Update local state by removing the deleted ambulance
      final updatedList = state.ambulances
          .where((item) => (item['_id'] ?? item['id']).toString() != ambulanceId)
          .toList();

      state = state.copyWith(ambulances: updatedList);

      // ✅ If the user has no ambulances left, clear the registration flag
      if (updatedList.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('ambulanceRegistered');
        await prefs.remove('ambulanceId');
        log("🔄 Cleared ambulance flag – user has no ambulances left");
      }

      return true;
    }

    return false;
  } catch (e) {
    log("DELETE ERROR: $e");
    return false;
  }
}

}

final ambulanceListProvider = StateNotifierProvider<AmbulanceListNotifier, AmbulanceListState>(
  (ref) => AmbulanceListNotifier(ref.read(apiServiceProvider)),
);