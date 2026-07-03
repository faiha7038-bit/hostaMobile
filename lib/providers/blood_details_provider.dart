import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final bloodProvider =
    StateNotifierProvider<BloodNotifier, Map<String, dynamic>?>(
  (ref) => BloodNotifier(),
);

class BloodNotifier extends StateNotifier<Map<String, dynamic>?> {
  BloodNotifier() : super(null);

  final ApiService apiService = ApiService();

  Future<void> fetchDonor(String userId) async {
    try {
      final response = await apiService.getAllDonors(
        userId: userId,
      );

      if (response.statusCode == 200) {
        final data = response.data["data"];

        if (data is List && data.isNotEmpty) {
          state = Map<String, dynamic>.from(data.first);
        } else {
          state = null;
        }
      } else {
        state = null;
      }
    } on DioException catch (e) {
      state = null;
    } catch (e) {
      state = null;
    }
  }

  Future<void> deleteDonor() async {
    final donorId = state?['id']?.toString();

    if (donorId == null) return;

    try {
      final res = await apiService.deleteDonor(donorId);

      if (res.statusCode == 200 && res.data['success'] == true) {
        state = null;

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('bloodId');

        state = null;
      } else {}
    } catch (e) {}
  }

  Future<bool> updateDonor(String donorId, Map<String, dynamic> payload) async {
    try {
      final response = await apiService.updateDonor(donorId, payload);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final updatedDonor = response.data['data'];
        state = updatedDonor ?? payload;

        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
