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
      if (response.data['specialties'] != null) {
        specialtyData = response.data['specialties'];
      } else if (response.data['data'] != null) {
        specialtyData = response.data['data'];
      } else {
        specialtyData = response.data is List ? response.data : [];
      }
    } else if (response.data is List) {
      specialtyData = response.data;
    } else {
      specialtyData = [];
    }
    
    return specialtyData is List ? specialtyData : [];
  }
  
  return [];
});

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered specialties provider
final filteredSpecialtiesProvider = Provider<List<dynamic>>((ref) {
  final specialties = ref.watch(specialtiesProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  
  return specialties.when(
    data: (specialtyList) {
      if (searchQuery.isEmpty) return specialtyList;
      
      return specialtyList.where((specialty) {
        final name = (specialty['name'] ?? '').toString().toLowerCase();
        return name.contains(searchQuery.toLowerCase());
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Hospitals for specialty provider
final hospitalsForSpecialtyProvider = StateProvider<List<dynamic>>((ref) => []);

// Loading state for hospitals
final hospitalsLoadingProvider = StateProvider<bool>((ref) => false);

// Selected specialty name provider
final selectedSpecialtyProvider = StateProvider<String>((ref) => '');

// Hospital operations provider
final hospitalOperationsProvider = Provider((ref) {
  return HospitalOperations(ref);
});

class HospitalOperations {
  final Ref ref;

  HospitalOperations(this.ref);

  Future<void> fetchHospitalsForSpecialty(String specialtyName) async {
    ref.read(hospitalsLoadingProvider.notifier).state = true;
    ref.read(selectedSpecialtyProvider.notifier).state = specialtyName;
    
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.getAllHospitalsSpeciality(specialtyName);
      
      if (response.statusCode == 200 && response.data != null) {
        dynamic hospitalData;
        
        if (response.data is Map) {
          if (response.data['hospitals'] != null) {
            hospitalData = response.data['hospitals'];
          } else if (response.data['data'] != null) {
            hospitalData = response.data['data'];
          } else {
            hospitalData = response.data is List ? response.data : [];
          }
        } else if (response.data is List) {
          hospitalData = response.data;
        } else {
          hospitalData = [];
        }
        
        final hospitalList = hospitalData is List ? hospitalData : [];
        ref.read(hospitalsForSpecialtyProvider.notifier).state = hospitalList;
        print("✅ Loaded ${hospitalList.length} hospitals for $specialtyName");
      } else {
        ref.read(hospitalsForSpecialtyProvider.notifier).state = [];
        print("❌ Failed to load hospitals: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error fetching hospitals: $e");
      ref.read(hospitalsForSpecialtyProvider.notifier).state = [];
      rethrow;
    } finally {
      ref.read(hospitalsLoadingProvider.notifier).state = false;
    }
  }

  List<dynamic> filterHospitalsBySpecialty(List<dynamic> hospitals, String specialtyName) {
    return hospitals.where((hospital) {
      final specialties = hospital['specialties'] as List? ?? [];
      return specialties.any((specialty) => 
        (specialty['name'] as String?)?.toLowerCase().contains(specialtyName.toLowerCase()) ?? false
      );
    }).toList();
  }

  int getDoctorsCountForSpecialty(Map<String, dynamic> hospital, String specialtyName) {
    try {
      final specialties = hospital['specialties'] as List? ?? [];
      for (var specialty in specialties) {
        final specialtyMap = specialty as Map<String, dynamic>;
        if ((specialtyMap['name'] as String?)?.toLowerCase().contains(specialtyName.toLowerCase()) ?? false) {
          final doctors = specialtyMap['doctors'] as List? ?? [];
          return doctors.length;
        }
      }
      return 0;
    } catch (e) {
      print("Error getting doctors count: $e");
      return 0;
    }
  }

  int getTotalDoctorsCount(Map<String, dynamic> hospital) {
    try {
      final specialties = hospital['specialties'] as List? ?? [];
      int totalDoctors = 0;
      for (var specialty in specialties) {
        final specialtyMap = specialty as Map<String, dynamic>;
        final doctors = specialtyMap['doctors'] as List? ?? [];
        totalDoctors += doctors.length;
      }
      return totalDoctors;
    } catch (e) {
      print("Error getting total doctors count: $e");
      return 0;
    }
  }

  void navigateToDoctorsPage(BuildContext context, String hospitalId, String specialtyName, String hospitalName) {
    Navigator.pop(context);
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