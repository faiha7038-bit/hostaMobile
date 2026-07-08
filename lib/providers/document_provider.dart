// import 'dart:io';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../services/api_service.dart';
// import '../data/models/document_model.dart';

// // ---------- STATE ----------
// class DocumentState {
//   final List<Document> documents;
//   final bool isLoading;
//   final bool isSubmitting;
//   final File? selectedFile;
//   final String? error;
//   final String? userId;
//   final int? currentPatientId;
//   DocumentState({
//     this.documents = const [],
//     this.isLoading = false,
//     this.isSubmitting = false,
//     this.selectedFile,
//     this.error,
//     this.userId,
//     this.currentPatientId,
//   });

//   DocumentState copyWith({
//     List<Document>? documents,
//     bool? isLoading,
//     bool? isSubmitting,
//     File? selectedFile,
//     String? error,
//     String? userId,
//     int? currentPatientId,
//     bool clearFile = false,
//   }) {
//     return DocumentState(
//       documents: documents ?? this.documents,
//       isLoading: isLoading ?? this.isLoading,
//       isSubmitting: isSubmitting ?? this.isSubmitting,
//       selectedFile: clearFile ? null : selectedFile ?? this.selectedFile,
//       error: error,
//       userId: userId ?? this.userId,
//       currentPatientId: currentPatientId ?? this.currentPatientId,
//     );
//   }
// }

// // ---------- PROVIDER ----------
// final documentProvider = StateNotifierProvider<DocumentNotifier, DocumentState>(
//   (ref) => DocumentNotifier(),
// );

// // ---------- NOTIFIER ----------
// class DocumentNotifier extends StateNotifier<DocumentState> {
//   final ApiService _api = ApiService();

//   DocumentNotifier() : super(DocumentState());

//   // ---------- INIT ----------
//   Future<void> init() async {
//     final prefs = await SharedPreferences.getInstance();
//     final uid = prefs.getString("userId");
//     state = state.copyWith(userId: uid);
//     if (uid != null && uid.isNotEmpty) {
//       await fetchDocuments();
//     }
//   }

//   // ---------- FETCH DOCUMENTS ----------
//   Future<void> fetchDocuments() async {
//     if (state.userId == null) return;

//     state = state.copyWith(isLoading: true, error: null);

//     try {
//       // 1. Get all patients for this user
//       final patientResponse = await _api.getPatients(
//         userId: int.parse(state.userId!),
//       );

//       final List patients = patientResponse.data['data'];

//       // 2. Save the first patient ID (for creating new documents)
//       int? firstPatientId =
//           patients.isNotEmpty ? patients[0]['id'] as int : null;
//       state = state.copyWith(currentPatientId: firstPatientId);

//       // 3. Fetch documents for all patients
//       List<Document> documents = [];
//       for (final patient in patients) {
//         final pid = patient['id'];
//         final patientDocs = await _api.getDocuments(patientId: pid);
//         documents.addAll(patientDocs);
//       }

//       state = state.copyWith(
//         documents: documents,
//         isLoading: false,
//       );
//     } catch (e) {
//       state = state.copyWith(
//         error: e.toString(),
//         isLoading: false,
//       );
//     }
//   }

//   // ---------- PICK FILE ----------
//   void setFile(File file) {
//     state = state.copyWith(selectedFile: file);
//   }

//   void clearFile() {
//     state = state.copyWith(clearFile: true);
//   }

//   // ---------- CREATE DOCUMENT (ONLY METADATA, NO FILE) ----------
//   Future<int?> createDocument({
//     required String name,
//     required String date,
//     required int patientId,
//   }) async {
//     state = state.copyWith(isSubmitting: true);

//     try {
//       // 1. Create document in backend (without file)
//       final response = await _api.createDocument({
//         "patientId": patientId,
//         "name": name,
//         "date": date,
//       });

//       final docId = response.data['data']?['id'] ?? response.data['id'];

//       await fetchDocuments();

//       return docId is int ? docId : int.tryParse(docId.toString());
//     } catch (e) {
//       return null;
//     } finally {
//       state = state.copyWith(isSubmitting: false);
//     }
//   }

//   // ---------- UPLOAD FILE FOR EXISTING DOCUMENT (S3 + UPDATE) ----------
//   Future<void> uploadFileForDocument({
//     required int docId,
//     required File file,
//   }) async {
//     state = state.copyWith(isSubmitting: true);

//     try {
//       // 1. Upload to S3 using the DOCUMENT ID (not patient ID)
//       final s3Result = await _api.uploadFileToS3(
//         file: file,
//         id: docId.toString(), // 👈 IMPORTANT: document ID
//         role: "documents",
//       );

//       await _api.updateDocument(
//         docId.toString(),
//         {
//           "imageUrl": s3Result["key"],
//         },
//       );

//       // 3. Refresh list
//       await fetchDocuments();
//     } catch (e) {
//     } finally {
//       state = state.copyWith(isSubmitting: false);
//     }
//   }

//   // ---------- UPDATE DOCUMENT (METADATA ONLY) ----------
//   Future<void> updateDocument({
//     required String docId,
//     required String name,
//     required String date,
//   }) async {
//     state = state.copyWith(isSubmitting: true);
//     try {
//       await _api.updateDocument(docId, {
//         "name": name,
//         "date": date,
//       });
//       await fetchDocuments();
//     } catch (e) {
//     } finally {
//       state = state.copyWith(isSubmitting: false);
//     }
//   }

//   Future<void> deleteDocument({required int id}) async {
//     final previousDocs = List<Document>.from(state.documents);
//     final updatedDocs = state.documents.where((d) => d.id != id).toList();
//     state = state.copyWith(documents: updatedDocs);

//     try {
//       await _api
//           .deleteDocument(id, {}); // or just await _api.deleteDocument(id);

//       await fetchDocuments(); // optional: refresh from server
//     } catch (e) {
//       state = state.copyWith(documents: previousDocs);

//       rethrow;
//     }
//   }

//   Future<void> refresh() async {
//     await fetchDocuments();
//   }
// }










// import 'dart:io';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../services/api_service.dart';
// import '../data/models/document_model.dart';

// // ---------- STATE ----------
// class DocumentState {
//   final List<Document> documents;
//   final bool isLoading;
//   final bool isSubmitting;
//   final File? selectedFile;
//   final String? error;
//   final String? userId;
//   final int? currentPatientId;
//   DocumentState({
//     this.documents = const [],
//     this.isLoading = false,
//     this.isSubmitting = false,
//     this.selectedFile,
//     this.error,
//     this.userId,
//     this.currentPatientId,
//   });

//   DocumentState copyWith({
//     List<Document>? documents,
//     bool? isLoading,
//     bool? isSubmitting,
//     File? selectedFile,
//     String? error,
//     String? userId,
//     int? currentPatientId,
//     bool clearFile = false,
//   }) {
//     return DocumentState(
//       documents: documents ?? this.documents,
//       isLoading: isLoading ?? this.isLoading,
//       isSubmitting: isSubmitting ?? this.isSubmitting,
//       selectedFile: clearFile ? null : selectedFile ?? this.selectedFile,
//       error: error,
//       userId: userId ?? this.userId,
//       currentPatientId: currentPatientId ?? this.currentPatientId,
//     );
//   }
// }

// // ---------- PROVIDER ----------
// final documentProvider = StateNotifierProvider<DocumentNotifier, DocumentState>(
//   (ref) => DocumentNotifier(),
// );

// // ---------- NOTIFIER ----------
// class DocumentNotifier extends StateNotifier<DocumentState> {
//   final ApiService _api = ApiService();

//   DocumentNotifier() : super(DocumentState());

//   // ---------- INIT ----------
//   Future<void> init() async {
//     final prefs = await SharedPreferences.getInstance();
//     final uid = prefs.getString("userId");
//     state = state.copyWith(userId: uid);
//     if (uid != null && uid.isNotEmpty) {
//       await fetchDocuments();
//     }
//   }

//   // ---------- FETCH DOCUMENTS ----------
//   Future<void> fetchDocuments() async {
//     if (state.userId == null) return;

//     state = state.copyWith(isLoading: true, error: null);

//     try {
//       // 1. Get all patients for this user
//       final patientResponse = await _api.getPatients(
//         userId: int.parse(state.userId!),
//       );

//       final List patients = patientResponse.data['data'];

//       // 2. Save the first patient ID (for creating new documents)
//       int? firstPatientId =
//           patients.isNotEmpty ? patients[0]['id'] as int : null;
//       state = state.copyWith(currentPatientId: firstPatientId);

//       // 3. Fetch documents for all patients
//       List<Document> documents = [];
//       for (final patient in patients) {
//         final pid = patient['id'];
//         final patientDocs = await _api.getDocuments(patientId: pid);
//         documents.addAll(patientDocs);
//       }

//       state = state.copyWith(
//         documents: documents,
//         isLoading: false,
//       );
//     } catch (e) {
//       state = state.copyWith(
//         error: e.toString(),
//         isLoading: false,
//       );
//     }
//   }

//   // ---------- PICK FILE ----------
//   void setFile(File file) {
//     state = state.copyWith(selectedFile: file);
//   }

//   void clearFile() {
//     state = state.copyWith(clearFile: true);
//   }

//   // ---------- CREATE DOCUMENT (ONLY METADATA, NO FILE) ----------
//   Future<int?> createDocument({
//     required String name,
//     required String date,
//     required int patientId,
//   }) async {
//     state = state.copyWith(isSubmitting: true);

//     try {
//       // 1. Create document in backend (without file)
//       final response = await _api.createDocument({
//         "patientId": patientId,
//         "name": name,
//         "date": date,
//       });

//       final docId = response.data['data']?['id'] ?? response.data['id'];

//       await fetchDocuments();

//       return docId is int ? docId : int.tryParse(docId.toString());
//     } catch (e) {
//       return null;
//     } finally {
//       state = state.copyWith(isSubmitting: false);
//     }
//   }

//   // ---------- UPLOAD FILE FOR EXISTING DOCUMENT (S3 + UPDATE) ----------
//   Future<void> uploadFileForDocument({
//     required int docId,
//     required File file,
//   }) async {
//     state = state.copyWith(isSubmitting: true);

//     try {
//       // 1. Upload to S3 using the DOCUMENT ID (not patient ID)
//       final s3Result = await _api.uploadFileToS3(
//         file: file,
//         id: docId.toString(), // 👈 IMPORTANT: document ID
//         role: "documents",
//       );

//       await _api.updateDocument(
//         docId.toString(),
//         {
//           "imageUrl": s3Result["key"],
//         },
//       );

//       // 3. Refresh list
//       await fetchDocuments();
//     } catch (e) {
//     } finally {
//       state = state.copyWith(isSubmitting: false);
//     }
//   }

//   // ---------- UPDATE DOCUMENT (METADATA ONLY) ----------
//   Future<void> updateDocument({
//     required String docId,
//     required String name,
//     required String date,
//   }) async {
//     state = state.copyWith(isSubmitting: true);
//     try {
//       await _api.updateDocument(docId, {
//         "name": name,
//         "date": date,
//       });
//       await fetchDocuments();
//     } catch (e) {
//     } finally {
//       state = state.copyWith(isSubmitting: false);
//     }
//   }

//   Future<void> deleteDocument({required int id}) async {
//     final previousDocs = List<Document>.from(state.documents);
//     final updatedDocs = state.documents.where((d) => d.id != id).toList();
//     state = state.copyWith(documents: updatedDocs);

//     try {
//       await _api
//           .deleteDocument(id, {}); // or just await _api.deleteDocument(id);

//       await fetchDocuments(); // optional: refresh from server
//     } catch (e) {
//       state = state.copyWith(documents: previousDocs);

//       rethrow;
//     }
//   }

//   Future<void> refresh() async {
//     await fetchDocuments();
//   }
// }



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

  // ---------- FETCH DOCUMENTS (BACKEND-ONLY) ----------
  Future<void> fetchDocuments({
    int? patientId,
    String? searchQuery,
    String? date,
  }) async {


    // Save filters for refresh
    state = state.copyWith(
      filterPatientId: patientId,
      filterSearchQuery: searchQuery,
      filterDate: date,
    );

    if (state.userId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // 1. Get patients list (for dropdown and currentPatientId)
      final patientResponse = await _api.getPatients(
        userId: int.parse(state.userId!),
      );
      final List patients = patientResponse.data['data'];
      state = state.copyWith(
        patients: patients,
        currentPatientId: state.currentPatientId ?? (patients.isNotEmpty ? patients.first['id'] : null),
      );

      // 2. Fetch documents – backend is expected to filter by patientId
      List<Document> documents = [];
      if (patientId != null) {
        // Single patient
        documents = await _api.getDocuments(
          patientId: patientId,
          date: date,
          searchQuery: searchQuery,
        );
      } else {
        // All patients – fetch per patient and combine (backend may return all anyway)
        for (final patient in patients) {
          documents.addAll(
            await _api.getDocuments(
              patientId: patient['id'],
              date: date,
              searchQuery: searchQuery,
            ),
          );
        }
      }



      state = state.copyWith(
        documents: documents,
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