import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../services/api_service.dart';

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Location Data Provider (cached)
final locationDataProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final String response = await rootBundle.loadString(
    'assets/countries+states+cities.json',
  );
  final data = await json.decode(response);
  return data.map<Map<String, dynamic>>((c) => {
    'id': c['iso3'],
    'name': c['name'],
    'states': c['states'],
  }).toList();
});

// Donor Form State
final donorFormProvider = StateNotifierProvider<DonorFormNotifier, DonorFormState>((ref) {
  return DonorFormNotifier();
});

class DonorFormState {
  final String? dateOfBirth;
  final String? bloodGroup;
  final Map<String, dynamic>? selectedCountry;
  final Map<String, dynamic>? selectedState;
  final Map<String, dynamic>? selectedDistrict;
  final List<Map<String, dynamic>> states;
  final List<Map<String, dynamic>> districts;
  final bool isLoading;
  final String? error;

  const DonorFormState({
    this.dateOfBirth,
    this.bloodGroup,
    this.selectedCountry,
    this.selectedState,
    this.selectedDistrict,
    this.states = const [],
    this.districts = const [],
    this.isLoading = false,
    this.error,
  });

  DonorFormState copyWith({
    String? dateOfBirth,
    String? bloodGroup,
    Map<String, dynamic>? selectedCountry,
    Map<String, dynamic>? selectedState,
    Map<String, dynamic>? selectedDistrict,
    List<Map<String, dynamic>>? states,
    List<Map<String, dynamic>>? districts,
    bool? isLoading,
    String? error,
  }) {
    return DonorFormState(
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      selectedState: selectedState ?? this.selectedState,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      states: states ?? this.states,
      districts: districts ?? this.districts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DonorFormNotifier extends StateNotifier<DonorFormState> {
  DonorFormNotifier() : super(const DonorFormState());

  void updateDateOfBirth(String dob) {
    state = state.copyWith(dateOfBirth: dob);
  }

  void updateBloodGroup(String group) {
    state = state.copyWith(bloodGroup: group);
  }

  void updateSelectedCountry(Map<String, dynamic> country) {
    final states = (country['states'] as List)
        .map((s) => {
              'id': s['state_code'],
              'name': s['name'],
              'cities': s['cities'],
            })
        .toList();
    
    state = state.copyWith(
      selectedCountry: country,
      selectedState: null,
      selectedDistrict: null,
      states: states,
      districts: [],
    );
  }

  void updateSelectedState(Map<String, dynamic> stateData) {
    final districts = (stateData['cities'] as List)
        .map((d) => {'id': d['id'].toString(), 'name': d['name']})
        .toList();
    
    state = state.copyWith(
      selectedState: stateData,
      selectedDistrict: null,
      districts: districts,
    );
  }

  void updateSelectedDistrict(Map<String, dynamic> district) {
    state = state.copyWith(selectedDistrict: district);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void resetForm() {
    state = const DonorFormState();
  }
}

// Donor Creation Provider
final donorCreationProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, payload) async {
  final apiService = ref.read(apiServiceProvider);
  
  try {
    final response = await apiService.createADonor(payload);
    
    if (response.statusCode == 201) {
      final bloodId = response.data["donor"]["_id"];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bloodId', bloodId);
      return true;
    } else {
      throw Exception(response.data['message'] ?? 'Donate failed');
    }
  } on DioException catch (dioError) {
    String errorMessage = "Something went wrong";
    if (dioError.response != null) {
      try {
        errorMessage = dioError.response?.data['message'] ?? errorMessage;
      } catch (_) {}
    }
    throw Exception(errorMessage);
  } catch (e) {
    throw Exception("Error: $e");
  }
});

// User Phone Provider
final userPhoneProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userPhone');
});

// User ID Provider
final userIdProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('userId');
});