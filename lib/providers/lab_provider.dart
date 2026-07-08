import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

// ---------- STATE ----------
class LabState {
  final List<dynamic> labReports;
  final List<dynamic> filteredReports;
  final bool isLoading;
  final String? error;
  final String? userId;
  final DateTime? selectedDate;
  final dynamic selectedReport;
  final int? currentReportIndex;
  final String searchQuery;
  final String? selectedPatientName;
  final bool showFilters;

  LabState({
    this.labReports = const [],
    this.filteredReports = const [],
    this.isLoading = false,
    this.error,
    this.userId,
    this.selectedDate,
    this.selectedReport,
    this.currentReportIndex,
    this.searchQuery = '',
    this.selectedPatientName,
    this.showFilters = false,
  });

  LabState copyWith({
    List<dynamic>? labReports,
    List<dynamic>? filteredReports,
    bool? isLoading,
    String? error,
    String? userId,
    DateTime? selectedDate,
    dynamic selectedReport,
    int? currentReportIndex,
    String? searchQuery,
    String? selectedPatientName,
    bool? showFilters,
  }) {
    return LabState(
      labReports: labReports ?? this.labReports,
      filteredReports: filteredReports ?? this.filteredReports,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userId: userId ?? this.userId,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedReport: selectedReport ?? this.selectedReport,
      currentReportIndex: currentReportIndex ?? this.currentReportIndex,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedPatientName: selectedPatientName ?? this.selectedPatientName,
      showFilters: showFilters ?? this.showFilters,
    );
  }
}

// ---------- PROVIDER ----------
final labProvider = StateNotifierProvider<LabNotifier, LabState>(
  (ref) => LabNotifier(),
);

// ---------- NOTIFIER ----------
class LabNotifier extends StateNotifier<LabState> {
  final ApiService _api = ApiService();

  static const String S3_BASE_URL = 
      "https://hostahealthcare.s3.eu-north-1.amazonaws.com";

  LabNotifier() : super(LabState());

  String? _getS3ImageUrl(String? key) {
    if (key == null || key.isEmpty) return null;
    if (key.startsWith('http://') || key.startsWith('https://')) {
      return key;
    }
    String cleanKey = key.startsWith('/') ? key.substring(1) : key;
    return '$S3_BASE_URL/$cleanKey';
  }

  // ---------- INIT ----------
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString('userId');
    
    if (uid == null || uid.isEmpty) {
      uid = prefs.getString('id');
    }
    
    state = state.copyWith(userId: uid);
    if (uid != null && uid.isNotEmpty) {
      await fetchLabReports();
    }
  }

// ---------- FETCH LAB REPORTS ----------
Future<void> fetchLabReports() async {
  if (state.userId == null || state.userId!.isEmpty) {
    state = state.copyWith(
      error: "Please login to view your lab reports",
      isLoading: false,
    );
    return;
  }

  state = state.copyWith(isLoading: true, error: null);

  try {
    final patientResponse = await _api.getPatients(
      userId: int.parse(state.userId!),
    );

    final List patients = patientResponse.data['data'] ?? [];

    if (patients.isEmpty) {
      state = state.copyWith(
        labReports: [],
        filteredReports: [],
        selectedReport: null,
        currentReportIndex: null,
        isLoading: false,
        error: "No patients found",
      );
      return;
    }

    List<dynamic> allReports = [];

    for (final patient in patients) {
      final patientId = patient['id']?.toString();
      final patientName = patient['name'] ?? '';
      final patientEmail = patient['email'] ?? '';

      if (patientId != null && patientId.isNotEmpty) {
        try {
          final reportResponse = await _api.getLabReports(
            patientId: patientId,
            date: null, 
            page: 1,
            limit: 100,
          );

          if (reportResponse.data['success'] == true) {
            final data = reportResponse.data['data'];
            List<dynamic> reports = [];

            if (data is List) {
              reports = data;
            } else if (data is Map) {
              if (data.containsKey('results') && data['results'] is List) {
                reports = data['results'] as List;
              } else if (data.containsKey('data') && data['data'] is List) {
                reports = data['data'] as List;
              }
            }

            final reportsWithPatient = reports.map((report) {
              report['patientName'] = patientName;
              report['patientEmail'] = patientEmail;
              report['patientId'] = patientId;
              report['patientIdNumber'] = patientId;

              if (report['imageUrl'] != null && 
                  report['imageUrl'].toString().isNotEmpty) {
                final originalUrl = report['imageUrl'].toString();
                final processedUrl = _getS3ImageUrl(originalUrl);
                report['imageUrl'] = processedUrl;
              }
              
              report['hospitalName'] = report['hospitalName'] ?? '';
              report['labName'] = report['labName'] ?? '';
              report['department'] = report['department'] ?? '';
              report['testName'] = report['testName'] ?? '';
              report['createdAt'] = report['createdAt'] ?? '';
              
              return report;
            }).toList();

            allReports.addAll(reportsWithPatient);
          }
        } catch (e) {
          // Error fetching reports for patient
        }
      }
    }

    List<dynamic> dateFilteredReports = allReports;
    
    if (state.selectedDate != null) {
      final selectedDateStr = 
          "${state.selectedDate!.year}-${state.selectedDate!.month.toString().padLeft(2, '0')}-${state.selectedDate!.day.toString().padLeft(2, '0')}";
      
      dateFilteredReports = allReports.where((report) {
        final createdAt = report['createdAt']?.toString() ?? '';
        if (createdAt.isEmpty) return false;
        
        final reportDate = createdAt.split('T')[0];
       
        return reportDate == selectedDateStr;
      }).toList();
    }

    if (dateFilteredReports.isEmpty) {
      String errorMsg = state.selectedDate != null 
          ? "No lab reports found for ${state.selectedDate!.day}/${state.selectedDate!.month}/${state.selectedDate!.year}"
          : "No lab reports found for your patients";
      
      state = state.copyWith(
        labReports: allReports,
        filteredReports: [],
        selectedReport: null,
        currentReportIndex: null,
        isLoading: false,
        error: errorMsg,
      );
      return;
    }

    final filtered = _applyFilters(dateFilteredReports);
    
    state = state.copyWith(
      labReports: allReports,  
      filteredReports: filtered,
      selectedReport: filtered.isNotEmpty ? filtered[0] : null,
      currentReportIndex: filtered.isNotEmpty ? 0 : null,
      isLoading: false,
      error: null,
    );

  } catch (e) {
    state = state.copyWith(
      error: "Error: ${e.toString()}",
      isLoading: false,
    );
  }
}

  // ---------- SEARCH & FILTER LOGIC ----------
  List<dynamic> _applyFilters(List<dynamic> reports) {
    return reports.where((report) {
      bool matchesSearch = true;
      if (state.searchQuery.isNotEmpty) {
        final query = state.searchQuery.toLowerCase().trim();
        matchesSearch = 
            report['hospitalName']?.toString().toLowerCase().contains(query) == true ||
            report['labName']?.toString().toLowerCase().contains(query) == true ||
            report['patientName']?.toString().toLowerCase().contains(query) == true ||
            report['department']?.toString().toLowerCase().contains(query) == true ||
            report['testName']?.toString().toLowerCase().contains(query) == true;
      }

      bool matchesPatient = true;
      if (state.selectedPatientName != null && state.selectedPatientName!.isNotEmpty) {
        matchesPatient = report['patientName']?.toString() == state.selectedPatientName;
      }

      return matchesSearch && matchesPatient;
    }).toList();
  }

  // ---------- SEARCH METHODS ----------
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _updateFilteredReports();
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
    _updateFilteredReports();
  }

  // ---------- FILTER METHODS ----------
  void toggleFilters() {
    state = state.copyWith(showFilters: !state.showFilters);
  }

  void setPatientNameFilter(String? patientName) {
    state = state.copyWith(
      selectedPatientName: patientName,
    );
    _updateFilteredReports();
  }

  void clearAllFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedPatientName: null,
      selectedDate: null,
      showFilters: false,
    );
    _updateFilteredReports();
  }

void _updateFilteredReports() {
  final baseReports = state.selectedDate != null 
      ? state.labReports.where((report) {
          final createdAt = report['createdAt']?.toString() ?? '';
          if (createdAt.isEmpty) return false;
          final reportDate = createdAt.split('T')[0];
          final selectedDateStr = 
              "${state.selectedDate!.year}-${state.selectedDate!.month.toString().padLeft(2, '0')}-${state.selectedDate!.day.toString().padLeft(2, '0')}";
          return reportDate == selectedDateStr;
        }).toList()
      : state.labReports;
  
  final filtered = _applyFilters(baseReports);
  state = state.copyWith(
    filteredReports: filtered,
    selectedReport: filtered.isNotEmpty ? filtered[0] : null,
    currentReportIndex: filtered.isNotEmpty ? 0 : null,
  );
}

  // ---------- DATE FILTER ----------
  void setDateFilter(DateTime? date) async {
    state = state.copyWith(selectedDate: date);
    await fetchLabReports();
  }

  void clearDateFilter() async {
    state = state.copyWith(selectedDate: null);
    await fetchLabReports();
  }

  // ---------- SELECT REPORT ----------
  void selectReport(int index) {
    if (index >= 0 && index < state.filteredReports.length) {
      state = state.copyWith(
        selectedReport: state.filteredReports[index],
        currentReportIndex: index,
      );
    }
  }

  // ---------- NEXT/PREVIOUS REPORT ----------
  void nextReport() {
    if (state.currentReportIndex != null && 
        state.currentReportIndex! < state.filteredReports.length - 1) {
      final newIndex = state.currentReportIndex! + 1;
      state = state.copyWith(
        selectedReport: state.filteredReports[newIndex],
        currentReportIndex: newIndex,
      );
    }
  }

  void previousReport() {
    if (state.currentReportIndex != null && state.currentReportIndex! > 0) {
      final newIndex = state.currentReportIndex! - 1;
      state = state.copyWith(
        selectedReport: state.filteredReports[newIndex],
        currentReportIndex: newIndex,
      );
    }
  }

  // ---------- GET PATIENTS LIST FOR FILTER ----------
  List<String> getUniquePatientNames() {
    final Set<String> patientNames = {};
    for (final report in state.labReports) {
      final name = report['patientName']?.toString();
      if (name != null && name.isNotEmpty) {
        patientNames.add(name);
      }
    }
    return patientNames.toList();
  }

  // ---------- REFRESH ----------
  Future<void> refresh() async {
    await fetchLabReports();
  }
}