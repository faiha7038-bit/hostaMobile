import 'dart:io';
import 'package:hosta/data/models/document_model.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class DocumentService {
  final String baseUrl = 'https://your-api.com';
  final Dio dio = Dio();

  // ✅ Get all documents
  Future<List<DocumentModel>> getDocuments(String patientId) async {
    try {
      final response = await dio.get(
        '$baseUrl/api/documents/patient/$patientId',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await getToken()}',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((doc) => DocumentModel.fromJson(doc)).toList();
      } else {
        throw Exception('Failed to load documents');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // ✅ Upload document
  Future<DocumentModel> uploadDocument({
    required String patientId,
    required File file,
    required String fileName,
    required String documentType,
    String? description,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'patientId': patientId,
        'documentType': documentType,
        'description': description ?? '',
      });

      final response = await dio.post(
        '$baseUrl/api/documents/upload',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await getToken()}',
          },
        ),
      );

      if (response.statusCode == 200) {
        return DocumentModel.fromJson(response.data['data']);
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      throw Exception('Error uploading: $e');
    }
  }

  // ✅ Delete document
  Future<bool> deleteDocument(String documentId) async {
    try {
      final response = await dio.delete(
        '$baseUrl/api/documents/$documentId',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await getToken()}',
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting: $e');
    }
  }

  // ✅ Download document
  Future<String> downloadDocument(DocumentModel document) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${document.fileName}';

      await dio.download(
        document.fileUrl,
        filePath,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${await getToken()}',
          },
        ),
      );

      return filePath;
    } catch (e) {
      throw Exception('Error downloading: $e');
    }
  }

  // ✅ Get token (SharedPreferences-ൽ നിന്ന്)
  Future<String> getToken() async {
    // നിങ്ങളുടെ token എടുക്കാനുള്ള ലോജിക്
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // return prefs.getString('token') ?? '';
    return 'your_token_here';
  }
}