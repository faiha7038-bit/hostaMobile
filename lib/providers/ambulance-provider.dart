import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

// Provider for ApiService
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Provider for ambulance list
final ambulanceListProvider = StateNotifierProvider<AmbulanceNotifier, List<dynamic>>((ref) {
  return AmbulanceNotifier(ref.read(apiServiceProvider));
});

// StateNotifier to manage ambulance data
class AmbulanceNotifier extends StateNotifier<List<dynamic>> {
  final ApiService apiService;
  
  AmbulanceNotifier(this.apiService) : super([]);

Future<void> fetchAmbulances() async {
  try {
    final response = await apiService.getAllAmbulances();

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data is List
          ? response.data
          : response.data['data'] ?? [];

      // ✅ SAVE TO LOCAL
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_ambulances', jsonEncode(data));

      state = data;
    }
  } catch (e) {
    print("❌ API failed → loading from cache");

    // ✅ LOAD FROM LOCAL
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('cached_ambulances');

    if (cached != null) {
      final decoded = jsonDecode(cached);

state = List<Map<String, dynamic>>.from(decoded);
    } else {
      state = [];
    }
  }
}
}

// Provider for loading state
final isLoadingProvider = StateProvider<bool>((ref) => true);

// Provider for search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider for ambulance ID
final ambulanceIdProvider = StateProvider<String?>((ref) => null);

// Provider for filter variables
final selectedCountryProvider = StateProvider<String>((ref) => '');
final selectedStateProvider = StateProvider<String>((ref) => '');
final selectedDistrictProvider = StateProvider<String>((ref) => '');
final selectedPlaceProvider = StateProvider<String>((ref) => '');

// Computed provider for filtered ambulance list
final filteredAmbulanceListProvider = Provider<List<dynamic>>((ref) {
  final ambulanceList = ref.watch(ambulanceListProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final selectedCountry = ref.watch(selectedCountryProvider);
  final selectedState = ref.watch(selectedStateProvider);
  final selectedDistrict = ref.watch(selectedDistrictProvider);
  final selectedPlace = ref.watch(selectedPlaceProvider);
  
  return ambulanceList.where((ambulance) {
    final address = ambulance['address'] ?? {};
    
    final name = (ambulance['serviceName'] ?? '').toString().toLowerCase();
    final country = (address['country'] ?? '').toString();
    final state = (address['state'] ?? '').toString();
    final district = (address['district'] ?? '').toString();
    final place = (address['place'] ?? '').toString();

    final matchesSearch = name.contains(searchQuery.toLowerCase());
    final matchesCountry = selectedCountry.isEmpty || country == selectedCountry;
    final matchesState = selectedState.isEmpty || state == selectedState;
    final matchesDistrict = selectedDistrict.isEmpty || district == selectedDistrict;
    final matchesPlace = selectedPlace.isEmpty || place == selectedPlace;

    return matchesSearch &&
        matchesCountry &&
        matchesState &&
        matchesDistrict &&
        matchesPlace;
  }).toList();
});