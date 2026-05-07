import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';

final bloodProvider =
    StateNotifierProvider<BloodNotifier, Map<String, dynamic>?>(
  (ref) => BloodNotifier(),
);

class BloodNotifier extends StateNotifier<Map<String, dynamic>?> {
  BloodNotifier() : super(null);

  final ApiService apiService = ApiService();

  /// 🔹 FETCH DONOR
  Future<void> fetchDonor(String userId) async {
    try {
      final response = await apiService.getADonor(userId);

      if (response.statusCode == 200) {
        state = response.data;
      } else {
        state = null;
      }
    } catch (e) {
      state = null;
    }
  }

  /// 🔹 DELETE DONOR
  Future<void> deleteDonor() async {
    final donorId = state?['_id'];

    if (donorId == null) return;

    await apiService.deleteDonor(donorId);

    state = null;
  }
}