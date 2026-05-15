import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/presentation/screens/doctor/doctors.dart';
import '../../../services/api_service.dart';

// API Service provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Specialties list provider
final specialtiesProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getAllSpecility();

  if (response.statusCode == 200 && response.data != null) {
    dynamic specialtyData;
    if (response.data is Map) {
      specialtyData = response.data['specialties'] ?? response.data['data'] ?? [];
    } else if (response.data is List) {
      specialtyData = response.data;
    } else {
      specialtyData = [];
    }
    return specialtyData is List ? specialtyData : [];
  }
  return [];
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredSpecialtiesProvider = Provider<List<dynamic>>((ref) {
  final specialties = ref.watch(specialtiesProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  return specialties.when(
    data: (list) => searchQuery.isEmpty
        ? list
        : list.where((s) => (s['name'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase())).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Hospitals for specialty provider (full hospital objects + doctors list)
final hospitalsForSpecialtyProvider = StateProvider<List<Map<String, dynamic>>>((ref) => []);
final hospitalsLoadingProvider = StateProvider<bool>((ref) => false);
final selectedSpecialtyProvider = StateProvider<String>((ref) => '');

final hospitalOperationsProvider = Provider((ref) => HospitalOperations(ref));

class HospitalOperations {
  final Ref ref;
  // Cache to avoid fetching same hospital multiple times
  final Map<int, Map<String, dynamic>> _hospitalCache = {};

  HospitalOperations(this.ref);

  Future<void> fetchHospitalsForSpecialty(String specialtyName) async {
    ref.read(hospitalsLoadingProvider.notifier).state = true;
    ref.read(selectedSpecialtyProvider.notifier).state = specialtyName;

    try {
      final apiService = ref.read(apiServiceProvider);
      // Step 1: Fetch doctors for this specialty
      final response = await apiService.getDoctors(speciality: specialtyName);

      if (response.statusCode != 200 || response.data == null) {
        ref.read(hospitalsForSpecialtyProvider.notifier).state = [];
        print("❌ Failed to load doctors: ${response.statusCode}");
        return;
      }

      List<dynamic> doctorsData = [];
      if (response.data is List) {
        doctorsData = response.data;
      } else if (response.data is Map && response.data['data'] != null) {
        doctorsData = response.data['data'] as List;
      }

      final targetSpecialty = specialtyName.trim().toLowerCase();
      // Group doctors by hospitalId (only those with matching department)
      final Map<int, List<dynamic>> hospitalDoctorsMap = {};
      for (var doctor in doctorsData) {
        final department = (doctor['department'] as String?)?.trim().toLowerCase() ?? '';
        if (department == targetSpecialty) {
          final hospitalId = doctor['hospitalId'] as int?;
          if (hospitalId != null) {
            hospitalDoctorsMap.putIfAbsent(hospitalId, () => []);
            hospitalDoctorsMap[hospitalId]!.add(doctor);
          }
        }
      }

      if (hospitalDoctorsMap.isEmpty) {
        ref.read(hospitalsForSpecialtyProvider.notifier).state = [];
        print("⚠️ No hospitals found for $specialtyName");
        return;
      }

      // Step 2: Fetch full hospital details for each unique hospitalId
      final List<Map<String, dynamic>> hospitalList = [];
      for (var entry in hospitalDoctorsMap.entries) {
        final hospitalId = entry.key;
        final doctors = entry.value;

        Map<String, dynamic> hospitalDetails;
        if (_hospitalCache.containsKey(hospitalId)) {
          hospitalDetails = _hospitalCache[hospitalId]!;
        } else {
          try {
            final hospitalResponse = await apiService.getAHospitals(hospitalId.toString());
            if (hospitalResponse.statusCode == 200 && hospitalResponse.data != null) {
              dynamic data = hospitalResponse.data;
              if (data is Map && data['data'] != null) {
                hospitalDetails = Map<String, dynamic>.from(data['data']);
              } else if (data is Map) {
                hospitalDetails = Map<String, dynamic>.from(data);
              } else {
                hospitalDetails = {'_id': hospitalId.toString(), 'name': 'Hospital $hospitalId'};
              }
              _hospitalCache[hospitalId] = hospitalDetails;
            } else {
              hospitalDetails = {'_id': hospitalId.toString(), 'name': 'Hospital $hospitalId'};
            }
          } catch (e) {
            print("⚠️ Failed to fetch hospital $hospitalId: $e");
            hospitalDetails = {'_id': hospitalId.toString(), 'name': 'Hospital $hospitalId'};
          }
        }

        hospitalList.add({
          ...hospitalDetails,
          'doctorsForSpecialty': doctors,
        });
      }

      ref.read(hospitalsForSpecialtyProvider.notifier).state = hospitalList;
      print("✅ Loaded ${hospitalList.length} hospitals for $specialtyName");
    } catch (e) {
      print("❌ Error in fetchHospitalsForSpecialty: $e");
      ref.read(hospitalsForSpecialtyProvider.notifier).state = [];
    } finally {
      ref.read(hospitalsLoadingProvider.notifier).state = false;
    }
  }

  int getDoctorsCountForSpecialty(Map<String, dynamic> hospital, String specialtyName) {
    final doctors = hospital['doctorsForSpecialty'] as List? ?? [];
    return doctors.length;
  }

  int getTotalDoctorsCount(Map<String, dynamic> hospital) {
    // If hospital has 'specialties' array, sum all doctors; otherwise return specialty doctors count
    final specialties = hospital['specialties'] as List? ?? [];
    if (specialties.isNotEmpty) {
      int total = 0;
      for (var spec in specialties) {
        total += (spec['doctors'] as List? ?? []).length;
      }
      return total;
    }
    // Fallback: just return count of doctors for this specialty
    return (hospital['doctorsForSpecialty'] as List? ?? []).length;
  }

  void navigateToDoctorsPage(BuildContext context, String hospitalId, String specialtyName, String hospitalName) {
    Navigator.pop(context); // Close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Doctors(
          hospitalId: hospitalId,
          specialty: specialtyName,
        ),
      ),
    );
  }
}