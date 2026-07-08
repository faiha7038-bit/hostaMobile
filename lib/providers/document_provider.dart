import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../data/models/document_model.dart';

// ---------- STATE ----------
class DocumentState {
  final List<Document> documents;
  final bool isLoading;
  final bool isSubmitting;
  final File? selectedFile;
  final String? error;
  final String? userId;
  final int? currentPatientId;
  final List<dynamic> patients;

  final int? filterPatientId;
  final String? filterSearchQuery;
  final String? filterDate;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int limit;
  DocumentState({
    this.documents = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.selectedFile,
    this.error,
    this.userId,
    this.currentPatientId,
    this.patients = const [],
    this.filterPatientId,
    this.filterSearchQuery,
    this.filterDate,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.limit = 10,
  });

  DocumentState copyWith({
    List<Document>? documents,
    bool? isLoading,
    bool? isSubmitting,
    File? selectedFile,
    String? error,
    String? userId,
    int? currentPatientId,
    bool clearFile = false,
    List<dynamic>? patients,
    int? filterPatientId,
    String? filterSearchQuery,
    String? filterDate,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    int? limit,
  }) {
    return DocumentState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      selectedFile: clearFile ? null : selectedFile ?? this.selectedFile,
      error: error,
      userId: userId ?? this.userId,
      currentPatientId: currentPatientId ?? this.currentPatientId,
      patients: patients ?? this.patients,
      filterPatientId: filterPatientId ?? this.filterPatientId,
      filterSearchQuery: filterSearchQuery ?? this.filterSearchQuery,
      filterDate: filterDate ?? this.filterDate,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      limit: limit ?? this.limit,
    );
  }
}

// ---------- PROVIDER ----------
final documentProvider = StateNotifierProvider<DocumentNotifier, DocumentState>(
  (ref) => DocumentNotifier(),
);

// ---------- NOTIFIER ----------
class DocumentNotifier extends StateNotifier<DocumentState> {
  final ApiService _api = ApiService();

  DocumentNotifier() : super(DocumentState());

  // ---------- INIT ----------
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString("userId");
    state = state.copyWith(userId: uid);
    if (uid != null && uid.isNotEmpty) {
      await fetchDocuments();
    }
  }
Future<void> loadMore() async {
  if (state.isLoading) return;
  if (state.currentPage >= state.totalPages) return;

  final nextPage = state.currentPage + 1;

  print("Loading page: $nextPage");

final response = await _api.getDocuments(
  userId: int.parse(state.userId!),
  patientId: state.filterPatientId,
  searchQuery: state.filterSearchQuery,
  date: state.filterDate,
  page: nextPage,
  limit: state.limit,
);
print("loadmoreres${response.data}");
  final documentResponse = DocumentResponse.fromJson(response.data);

  state = state.copyWith(
    documents: [
      ...state.documents,
      ...documentResponse.documents,
    ],
    currentPage: documentResponse.currentPage,
    totalPages: documentResponse.totalPages,
    totalItems: documentResponse.totalItems,
    limit: documentResponse.limit,
  );

  print("Documents: ${state.documents.length}");
  print("State Current Page Before: ${state.currentPage}");
print("Response Current Page: ${documentResponse.currentPage}");
print(response.data['pagination']);
}

  Future<void> fetchDocuments({
    int? patientId,
    String? searchQuery,
    String? date,
    int page = 1,
    int limit = 10,
  }) async {
    // Save current filters
    state = state.copyWith(
      filterPatientId: patientId,
      filterSearchQuery: searchQuery,
      filterDate: date,
    );

    if (state.userId == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      
      final patientResponse = await _api.getPatients(
        userId: int.parse(state.userId!),
      );
       print("patientresponse$patientResponse");
      final List patients = patientResponse.data['data'];

      state = state.copyWith(
        patients: patients,
        currentPatientId: state.currentPatientId ??
            (patients.isNotEmpty ? patients.first['id'] : null),
      );

      // Fetch documents
    final response = await _api.getDocuments(
  userId: int.parse(state.userId!),
  patientId: patientId,
  date: date,
  searchQuery: searchQuery,
  page: page,
  limit: limit,
);
print(response.data);
      final documentResponse = DocumentResponse.fromJson(response.data);

   state = state.copyWith(
  documents: documentResponse.documents,
  currentPage: documentResponse.currentPage,
  totalPages: documentResponse.totalPages,
  totalItems: documentResponse.totalItems,
  limit: documentResponse.limit,
  isLoading: false,
);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // ---------- PICK FILE ----------
  void setFile(File file) {
    state = state.copyWith(selectedFile: file);
  }

  void clearFile() {
    state = state.copyWith(clearFile: true);
  }

  // ---------- CREATE DOCUMENT ----------
  Future<int?> createDocument({
    required String name,
    required String date,
    required int patientId,
  }) async {
    state = state.copyWith(isSubmitting: true);

    try {
      final userId = int.parse(state.userId!);
      final body = {
        "userId": userId,
        "patientId": patientId,
        "name": name,
        "date": date,
      };
      final response = await _api.createDocument(
        userId: userId,
        data: body,
      );
      final docId = response.data['data']?['id'] ?? response.data['id'];
      await fetchDocuments();
      return docId is int ? docId : int.tryParse(docId.toString());
    } on DioException catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<void> uploadFileForDocument({
    required int docId,
    required File file,
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final s3Result = await _api.uploadFileToS3(
        file: file,
        id: docId.toString(),
        role: "documents",
      );
      await _api.updateDocument(
        docId.toString(),
        {"imageUrl": s3Result["key"]},
      );
      await fetchDocuments();
    } catch (e) {
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  // ---------- UPDATE DOCUMENT ----------
  Future<void> updateDocument({
    required String docId,
    required String name,
    required String date,
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _api.updateDocument(docId, {
        "name": name,
        "date": date,
      });
      await fetchDocuments();
    } catch (e) {
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  // ---------- DELETE DOCUMENT (FIXED) ----------
  Future<void> deleteDocument({required int id}) async {
    final previousDocs = List<Document>.from(state.documents);
    final idStr = id.toString();
    final updatedDocs = state.documents.where((d) => d.id != idStr).toList();
    state = state.copyWith(documents: updatedDocs);

    try {
      await _api.deleteDocument(id, {});
      await fetchDocuments();
    } catch (e) {
      state = state.copyWith(documents: previousDocs);
      rethrow;
    }
  }

  // ---------- REFRESH ----------
  Future<void> refresh({
    String? searchQuery,
    String? date,
  }) async {
    await fetchDocuments(
      patientId: state.filterPatientId,
      searchQuery: searchQuery ?? state.filterSearchQuery,
      date: date ?? state.filterDate,
    );
  }
}