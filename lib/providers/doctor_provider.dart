// // lib/providers/doctor_providers.dart
// import 'package:flutter/material.dart';
// import 'package:riverpod/riverpod.dart';
// import 'package:dio/dio.dart';
// import '../data/models/doctor_model.dart';
// import '../services/api_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// // Provider for ApiService
// final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// // Provider for SharedPreferences
// final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
//   return await SharedPreferences.getInstance();
// });

// // State class for doctors screen
// class DoctorsState {
//   final List<Hospital> hospitals;
//   final bool isLoading;
//   final String? errorMessage;
//   final String searchQuery;

//   DoctorsState({
//     this.hospitals = const [],
//     this.isLoading = true,
//     this.errorMessage,
//     this.searchQuery = '',
//   });

//   DoctorsState copyWith({
//     List<Hospital>? hospitals,
//     bool? isLoading,
//     String? errorMessage,
//     String? searchQuery,
//   }) {
//     return DoctorsState(
//       hospitals: hospitals ?? this.hospitals,
//       isLoading: isLoading ?? this.isLoading,
//       errorMessage: errorMessage ?? this.errorMessage,
//       searchQuery: searchQuery ?? this.searchQuery,
//     );
//   }

//   List<Doctor> get allDoctors {
//     List<Doctor> doctors = [];
//     for (var hospital in hospitals) {
//       doctors.addAll(hospital.doctors.map((doctor) => doctor.copyWith(
//         hospitalName: hospital.name,
//         hospitalAddress: hospital.address,
//         hospitalPhone: hospital.phone,
//         hospitalId: hospital.id,
//       )));
//     }
//     return doctors;
//   }

//   List<Doctor> get filteredDoctors {
//     if (searchQuery.isEmpty) return allDoctors;
    
//     return allDoctors.where((doctor) {
//       final name = doctor.name.toLowerCase();
//       final specialty = doctor.specialty.toLowerCase();
//       final hospitalName = doctor.hospitalName?.toLowerCase() ?? '';
      
//       return name.contains(searchQuery.toLowerCase()) ||
//           specialty.contains(searchQuery.toLowerCase()) ||
//           hospitalName.contains(searchQuery.toLowerCase());
//     }).toList();
//   }
// }

// // Notifier for doctors screen
// class DoctorsNotifier extends StateNotifier<DoctorsState> {
//   final ApiService _apiService;
//   final String hospitalId;
//   final String specialty;

//   DoctorsNotifier(this._apiService, this.hospitalId, this.specialty)
//       : super(DoctorsState());

//   Future<void> fetchDoctors() async {
//     try {
//       state = state.copyWith(isLoading: true, errorMessage: null);
      
//       final response = await _apiService.getDoctors(
//         id: hospitalId,
//         specialty: specialty,
//       );

//       if (response.data['success'] == true) {
//         final hospitals = (response.data['hospitals'] as List)
//             .map((hospitalJson) => Hospital.fromJson(hospitalJson))
//             .toList();
            
//         state = state.copyWith(
//           hospitals: hospitals,
//           isLoading: false,
//         );
//       } else {
//         state = state.copyWith(
//           errorMessage: response.data['message'] ?? 'Failed to load doctors',
//           isLoading: false,
//         );
//       }
//     } catch (e) {
//       state = state.copyWith(
//         errorMessage: 'Error loading doctors: $e',
//         isLoading: false,
//       );
//     }
//   }

//   void updateSearchQuery(String query) {
//     state = state.copyWith(searchQuery: query);
//   }
// }

// // Provider for doctors screen (parameterized)
// final doctorsProvider = StateNotifierProvider.family<DoctorsNotifier, DoctorsState, ({String hospitalId, String specialty})>((ref, params) {
//   final apiService = ref.read(apiServiceProvider);
//   return DoctorsNotifier(apiService, params.hospitalId, params.specialty);
// });

// // Booking state
// class BookingState {
//   final bool isSubmitting;
//   final String? errorMessage;
//   final bool isSuccess;

//   BookingState({
//     this.isSubmitting = false,
//     this.errorMessage,
//     this.isSuccess = false,
//   });

//   BookingState copyWith({
//     bool? isSubmitting,
//     String? errorMessage,
//     bool? isSuccess,
//   }) {
//     return BookingState(
//       isSubmitting: isSubmitting ?? this.isSubmitting,
//       errorMessage: errorMessage ?? this.errorMessage,
//       isSuccess: isSuccess ?? this.isSuccess,
//     );
//   }
// }

// // Notifier for booking
// class BookingNotifier extends StateNotifier<BookingState> {
//   final ApiService _apiService;
//   final SharedPreferences _prefs;

//   BookingNotifier(this._apiService, this._prefs) : super(BookingState());

//   Future<bool> handleBooking({
//     required BuildContext context,
//     required Doctor doctor,
//     required String patientName,
//     required String patientPhone,
//     required String patientPlace,
//     required DateTime? patientDob,
//     required DateTime? appointmentDate,
//     required VoidCallback onSuccess,
//     required Function(String, bool) showSnackBar,
//   }) async {
//     if (state.isSubmitting) return false;

//     state = state.copyWith(isSubmitting: true, errorMessage: null);

//     final storedUserId = _prefs.getString('userId');

//     if (storedUserId == null) {
//       state = state.copyWith(isSubmitting: false);
//       return false;
//     }

//     if (patientName.isEmpty || patientPhone.isEmpty || patientPlace.isEmpty || 
//         patientDob == null || appointmentDate == null) {
//       state = state.copyWith(isSubmitting: false);
//       showSnackBar('Please fill all required fields', true);
//       return false;
//     }

//     final now = DateTime.now();
//     final selectedDate = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);
//     final currentDate = DateTime(now.year, now.month, now.day);
    
//     if (selectedDate.isBefore(currentDate)) {
//       state = state.copyWith(isSubmitting: false);
//       showSnackBar('Please select a future date for appointment', true);
//       return false;
//     }

//     final selectedDay = _getDayName(appointmentDate.weekday);
//     final isDayAvailable = doctor.consulting.any((day) => 
//         day.day.toLowerCase() == selectedDay.toLowerCase() && day.sessions.isNotEmpty);

//     if (!isDayAvailable) {
//       state = state.copyWith(isSubmitting: false);
//       showSnackBar('Dr. ${doctor.name} is not available on $selectedDay. Please select an available day.', true);
//       return false;
//     }

//     final bookingData = {
//       'userId': storedUserId,
//       'specialty': doctor.specialty,
//       'doctor_name': doctor.name,
//       'booking_date': appointmentDate.toIso8601String(),
//       'patient_name': patientName,
//       'patient_phone': patientPhone,
//       'patient_place': patientPlace,
//       'patient_dob': patientDob.toIso8601String(),
//     };

//     try {
//       final response = await _apiService.createBooking(
//         doctor.hospitalId!,
//         bookingData,
//       );

//       if (response.statusCode == 201 || response.data['status'] == 201) {
//         state = state.copyWith(isSubmitting: false, isSuccess: true);
//         showSnackBar('Appointment booked successfully with Dr. ${doctor.name}!', false);
//         onSuccess();
//         return true;
//       } else {
//         state = state.copyWith(isSubmitting: false);
//         showSnackBar(response.data['message'] ?? 'Booking failed', true);
//         return false;
//       }

//     } on DioException catch (dioError) {
//       String errorMessage = "Something went wrong";
//       if (dioError.response != null) {
//         try {
//           errorMessage = dioError.response?.data['message'] ?? errorMessage;
//         } catch (_) {}
//       }
//       state = state.copyWith(isSubmitting: false);
//       showSnackBar(errorMessage, true);
//       return false;
//     } catch (e) {
//       state = state.copyWith(isSubmitting: false);
//       showSnackBar('Error: $e', true);
//       return false;
//     }
//   }

//   void reset() {
//     state = BookingState();
//   }

//   String _getDayName(int weekday) {
//     switch (weekday) {
//       case 1: return 'Monday';
//       case 2: return 'Tuesday';
//       case 3: return 'Wednesday';
//       case 4: return 'Thursday';
//       case 5: return 'Friday';
//       case 6: return 'Saturday';
//       case 7: return 'Sunday';
//       default: return 'Unknown';
//     }
//   }
// }

// // Provider for booking
// final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
//   final apiService = ref.read(apiServiceProvider);
//   final prefsAsync = ref.read(sharedPreferencesProvider);
  
//   // Return a temporary notifier, will be updated when prefs loads
//   throw UnimplementedError('Use bookingProviderWithPrefs instead');
// });

// // Fixed provider that properly handles async initialization
// final bookingProviderWithPrefs = FutureProvider<BookingNotifier>((ref) async {
//   final apiService = ref.read(apiServiceProvider);
//   final prefs = await ref.read(sharedPreferencesProvider.future);
//   return BookingNotifier(apiService, prefs);
// });






// lib/providers/doctor_providers.dart
import 'package:flutter/material.dart';
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
      return doctor.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
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
      
      print("🟡 Fetching doctors for hospital: $hospitalId, specialty: $specialty");
      
      final response = await _apiService.getDoctors(
        hospitalId: hospitalId,
       speciality: specialty,
      );
      
      print("🟢 Response status: ${response.statusCode}");
      print("🟢 Response data: ${response.data}");
      
      // Check if response is successful
      if (response.statusCode == 200 && response.data['success'] == true) {
        final doctorsData = response.data['data'];
        
        if (doctorsData is List) {
          // Convert each JSON to Doctor object
          final doctors = doctorsData.map((json) {
            return Doctor.fromJson(json);
          }).toList();
          
          print("✅ Successfully loaded ${doctors.length} doctors");
          
          state = state.copyWith(
            doctors: doctors,
            isLoading: false,
          );
        } else {
          print("❌ doctorsData is not a List");
          state = state.copyWith(
            errorMessage: "Invalid data format",
            isLoading: false,
          );
        }
      } else {
        print("❌ API returned error");
        state = state.copyWith(
          errorMessage: response.data['message'] ?? "Failed to load doctors",
          isLoading: false,
        );
      }
    } catch (e, stackTrace) {
      print("❌ Error fetching doctors: $e");
      print("❌ Stack trace: $stackTrace");
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
final doctorsProvider = StateNotifierProvider.family<DoctorsNotifier, DoctorsState, ({String hospitalId, String specialty})>(
  (ref, params) {
    final apiService = ref.read(apiServiceProvider);
    return DoctorsNotifier(apiService, params.hospitalId, params.specialty);
  }
);

// ApiService provider
final apiServiceProvider = Provider((ref) => ApiService());
