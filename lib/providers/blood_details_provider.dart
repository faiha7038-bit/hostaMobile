import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

final bloodProvider = StateNotifierProvider<BloodNotifier, Map<String, dynamic>?>(
  (ref) => BloodNotifier(),
);

class BloodNotifier extends StateNotifier<Map<String, dynamic>?> {
  BloodNotifier() : super(null);

  final ApiService apiService = ApiService();

  /// FETCH DONOR
Future<void> fetchDonor(String userId) async {
  try {
    print("Fetching donor for user => $userId");

    final response = await apiService.getAllDonors(
      userId: userId,
    );

    print("FETCH STATUS => ${response.statusCode}");
    print("FETCH DATA => ${response.data}");

    if (response.statusCode == 200) {

      final data = response.data["data"];

      // because backend returns LIST
      if (data is List && data.isNotEmpty) {

        // take first donor
        state = Map<String, dynamic>.from(data.first);

      } else {

        state = null;

      }

    } else {

      state = null;

    }

  } on DioException catch (e) {

    print("FETCH ERROR => ${e.response?.data}");
    print("FETCH STATUS => ${e.response?.statusCode}");

    state = null;

  } catch (e) {

    print("GENERAL FETCH ERROR => $e");

    state = null;

  }
}

  /// DELETE DONOR
Future<void> deleteDonor() async {
  final donorId = state?['id']?.toString();
  if (donorId == null) return;

  try {
    final res = await apiService.deleteDonor(donorId);

    if (res.statusCode == 200 && res.data['success'] == true) {
      print("DELETE SUCCESS");

      // ✅ REMOVE LOCAL bloodId
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bloodId');

      // ✅ clear state
      state = null;

    } else {
      print("DELETE FAILED => ${res.data}");
    }
  } catch (e) {
    print("DELETE ERROR => $e");
  }
}

  /// UPDATE DONOR (returns bool)
  Future<bool> updateDonor(String donorId, Map<String, dynamic> payload) async {
    try {
      print("Updating donor ID => $donorId");
      print("Payload => $payload");

      final response = await apiService.updateDonor(donorId, payload);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final updatedDonor = response.data['data'];
        state = updatedDonor ?? payload;
        print("UPDATE SUCCESS => $state");
        return true;
      } else {
        print("UPDATE FAILED: ${response.data}");
        return false;
      }
    } catch (e) {
      print("UPDATE ERROR => $e");
      return false;
    }
  }
}