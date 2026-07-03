import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/doctor_model.dart';
import '../services/api_service.dart';

// State class
class DoctorsState {
  final List<Doctor> doctors;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;

  DoctorsState({
    this.doctors = const [],
    this.isLoading = true,
    this.errorMessage,
    this.searchQuery = '',
  });

  DoctorsState copyWith({
    List<Doctor>? doctors,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) {
    return DoctorsState(
      doctors: doctors ?? this.doctors,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Doctor> get filteredDoctors {
    if (searchQuery.isEmpty) return doctors;

    return doctors.where((doctor) {
      return doctor.fullName
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
          doctor.specialty.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
  }
}

// Notifier
class DoctorsNotifier extends StateNotifier<DoctorsState> {
  final ApiService _apiService;
  final String hospitalId;
  final String specialty;

  DoctorsNotifier(this._apiService, this.hospitalId, this.specialty)
      : super(DoctorsState());

  Future<void> fetchDoctors() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _apiService.getDoctors(
        hospitalId: hospitalId,
        speciality: specialty,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final doctorsData = response.data['data'];

        if (doctorsData is List) {
          final doctors = doctorsData.map((json) {
            return Doctor.fromJson(json);
          }).toList();

          state = state.copyWith(
            doctors: doctors,
            isLoading: false,
          );
        } else {
          state = state.copyWith(
            errorMessage: "Invalid data format",
            isLoading: false,
          );
        }
      } else {
        state = state.copyWith(
          errorMessage: response.data['message'] ?? "Failed to load doctors",
          isLoading: false,
        );
      }
    } catch (e, stackTrace) {
      state = state.copyWith(
        errorMessage: "Error: $e",
        isLoading: false,
      );
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

// Provider
final doctorsProvider = StateNotifierProvider.family<DoctorsNotifier,
    DoctorsState, ({String hospitalId, String specialty})>((ref, params) {
  final apiService = ref.read(apiServiceProvider);
  return DoctorsNotifier(apiService, params.hospitalId, params.specialty);
});

// ApiService provider
final apiServiceProvider = Provider((ref) => ApiService());
