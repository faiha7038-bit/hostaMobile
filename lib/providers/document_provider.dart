import 'dart:developer';
import 'dart:io';
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
  DocumentState({
    this.documents = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.selectedFile,
    this.error,
    this.userId,
    this.currentPatientId,
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
  }) {
    return DocumentState(
      documents: documents ?? this.documents,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      selectedFile: clearFile ? null : selectedFile ?? this.selectedFile,
      error: error,
      userId: userId ?? this.userId,
      currentPatientId: currentPatientId ?? this.currentPatientId,
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
    log("📌 Document Provider UserID => $uid");
    state = state.copyWith(userId: uid);
    if (uid != null && uid.isNotEmpty) {
      await fetchDocuments();
    }
  }

  // ---------- FETCH DOCUMENTS ----------
  Future<void> fetchDocuments() async {
    if (state.userId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Get all patients for this user
      final patientResponse = await _api.getPatients(
        userId: int.parse(state.userId!),
      );

      final List patients = patientResponse.data['data'];

      // 2. Save the first patient ID (for creating new documents)
      int? firstPatientId = patients.isNotEmpty ? patients[0]['id'] as int : null;
      state = state.copyWith(currentPatientId: firstPatientId);

      // 3. Fetch documents for all patients
      List<Document> documents = [];
      for (final patient in patients) {
        final pid = patient['id'];
        final patientDocs = await _api.getDocuments(patientId: pid);
        documents.addAll(patientDocs);
      }

      state = state.copyWith(
        documents: documents,
        isLoading: false,
      );

      log("✅ FINAL DOCUMENT LIST SIZE => ${documents.length}");
      
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
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

  // ---------- CREATE DOCUMENT (ONLY METADATA, NO FILE) ----------
  Future<int?> createDocument({
    required String name,
    required String date,
    required int patientId,
  }) async {
    state = state.copyWith(isSubmitting: true);

    try {
      // 1. Create document in backend (without file)
      final response = await _api.createDocument({
        "patientId": patientId,
        "name": name,
        "date": date,
      });

      // 2. Extract the new document ID from response
      final docId = response.data['data']?['id'] ?? response.data['id'];
      log("✅ Document created with ID: $docId");

      // 3. Refresh the list
      await fetchDocuments();

      return docId is int ? docId : int.tryParse(docId.toString());
    } catch (e) {
      log("❌ createDocument error => $e");
      return null;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  // ---------- UPLOAD FILE FOR EXISTING DOCUMENT (S3 + UPDATE) ----------
  Future<void> uploadFileForDocument({
    required int docId,
    required File file,
  }) async {
    state = state.copyWith(isSubmitting: true);

    try {
      // 1. Upload to S3 using the DOCUMENT ID (not patient ID)
      final s3Result = await _api.uploadFileToS3(
        file: file,
        id: docId.toString(), // 👈 IMPORTANT: document ID
        role: "documents",
      );

      log("✅ S3 Upload Success: ${s3Result['key']}");

      // 2. Update the document with the file details
      await _api.updateDocument(
        docId.toString(),
        {
          "imageUrl": s3Result["key"], // S3 key (backend will construct full URL)
          // Optionally also send: "fileKey": s3Result["key"],
        },
      );

      log("✅ Document updated with file reference");

      // 3. Refresh list
      await fetchDocuments();
    } catch (e) {
      log("❌ uploadFileForDocument error => $e");
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  // ---------- UPDATE DOCUMENT (METADATA ONLY) ----------
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
      log("❌ updateDocument error => $e");
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

 

// ---------- DELETE DOCUMENT ----------
Future<void> deleteDocument({
  required int id,
  required String role,
  required String key,
}) async {
  // 1️⃣ Optimistic removal
  final previousDocs = List<Document>.from(state.documents);
  final updatedDocs = state.documents.where((d) => d.id != id).toList();
  state = state.copyWith(documents: updatedDocs);
  log("🗑️ Optimistic delete: ${state.documents.length} docs remain");

  try {
    // 2️⃣ Delete from S3 and DB
    if (key.isEmpty) {
      await _api.deleteDocument(id, {});
    } else {
      final fileKey = key.contains('amazonaws.com/')
          ? key.split('.amazonaws.com/').last
          : key;
          log("ID   : $id");
log("ROLE : $role");
log("KEY  : $key");
      await _api.deleteDocument(
        id,
        {
          "role": role,
          "key": fileKey,
        },
      );
    }
    log("✅ Server delete successful for doc $id");

    // 3️⃣ Re-apply the removal (in case state was altered during the async call)
    final currentDocs = state.documents.where((d) => d.id != id).toList();
    state = state.copyWith(documents: currentDocs);
    log("🔄 Re-applied deletion, docs: ${state.documents.length}");

  } catch (e) {
    // 4️⃣ Rollback on error
    state = state.copyWith(documents: previousDocs);
    log("❌ Delete failed, rolled back: $e");
    rethrow;
  }
}

  // ---------- REFRESH ----------
  Future<void> refresh() async {
    await fetchDocuments();
  }
}