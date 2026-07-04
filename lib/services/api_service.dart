import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:hosta/data/models/document_model.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'token_manager.dart';
import '../data/models/prescription_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal();

  late final Dio dio;
  late final Dio refreshDio;
  late final PersistCookieJar cookieJar;

  bool _initialized = false;
  Future<String?>? _refreshFuture;

  final String baseUrl = "https://zorrowtek.in";

  // ---------------- INIT ----------------
  Future<void> init() async {
    if (_initialized) return;

    final dir = await getApplicationDocumentsDirectory();

    cookieJar = PersistCookieJar(
      storage: FileStorage("${dir.path}/.cookies/"),
    );

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {"Content-Type": "application/json"},
    ));

    refreshDio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {"Content-Type": "application/json"},
    ));

    dio.interceptors.add(CookieManager(cookieJar));
    refreshDio.interceptors.add(CookieManager(cookieJar));

    // 🔥 TOKEN INTERCEPTOR
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenManager.getAccessToken();

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }

          final request = error.requestOptions;

          // prevent loop
          if (request.path.contains("/api/users/refresh")) {
            return handler.next(error);
          }

          final refreshToken = await _getRefreshTokenFromCookies();

          if (refreshToken == null) {
            await TokenManager.clear();
            return handler.next(error);
          }

          try {
            _refreshFuture ??= _refresh(refreshToken);
            final newToken = await _refreshFuture;
            _refreshFuture = null;

            if (newToken == null) {
              await TokenManager.clear();
              return handler.next(error);
            }

            request.headers['Authorization'] = 'Bearer $newToken';
            final response = await dio.fetch(request);

            return handler.resolve(response);
          } catch (e) {
            _refreshFuture = null;
            await TokenManager.clear();
            return handler.next(error);
          }
        },
      ),
    );

    _initialized = true;
  }

  Future<String?> _getRefreshTokenFromCookies() async {
    final cookies = await cookieJar.loadForRequest(
      Uri.parse(
         
          "https://zorrowtek.in"),
    );

    for (final cookie in cookies) {
      if (cookie.name == "refreshToken") {
        return cookie.value;
      }
    }

    return null;
  }

  // ---------------- REFRESH TOKEN ----------------
  Future<String?> _refresh(String refreshToken) async {
    final res = await refreshDio.post(
      '/api/users/refresh',
      data: {
        'refreshToken': refreshToken,
      },
    );

    final newToken = res.data['token'];

    if (newToken != null) {
      await TokenManager.saveAccessToken(newToken);
    }

    return newToken;
  }


  Future<PrescriptionResponse> getPrescriptions({
    String? userId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await dio.get(
        '/api/prescription',
        queryParameters: {
          if (userId != null) "userId": userId,
          "page": page,
          "limit": limit,
        },
      );

      if (response.statusCode == 200) {
        return PrescriptionResponse.fromJson(response.data);
      } else {
        throw Exception('Failed to load prescriptions: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Prescription> getPrescriptionById(int id) async {
    try {
      final response = await dio.get('/api/prescription/$id');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return Prescription.fromJson(data['data'] ?? {});
      } else {
        throw Exception('Failed to load prescription: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  Future<Response> getDoctorDetails(int doctorId) async {
    try {
      final response = await dio.get('/api/doctor/$doctorId');

      return response;
    } catch (e) {
      rethrow;
    }
  }

//----------------------------PatientDetails----------------
  Future<Response> getPatientDetails(String patientId) async {
    try {
      final response = await dio.get('/api/patients/$patientId');
      return response;
    } catch (e) {
      throw Exception('Failed to load patient details: $e');
    }
  }
// ---------------- LAB REPORT ----------------

  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      return null;
    }
  }

  Future<String?> getToken() async {
    return await _getToken();
  }

  Future<dynamic> getLabReports({
    String? patientId,
    String? date,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (patientId != null && patientId.isNotEmpty) {
        queryParams['patientId'] = patientId;
      }
      if (date != null && date.isNotEmpty) {
        queryParams['date'] = date;
      }

      final response = await dio.get(
        '/api/lab-results',
        queryParameters: queryParams,
      );

      return response;
    } on DioException catch (e) {
      rethrow;
    }
  }

  // ==================== NOTIFICATIONS ====================

// ✅ GET NOTIFICATIONS BY ROLE (USER)
  Future<Response> getNotificationsByRole(
    String role,
    String userId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await dio.get(
        '/api/notification/$role/$userId', // ← ADDED /api
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

// ✅ MARK SINGLE NOTIFICATION AS READ
  Future<Response> markNotificationAsRead(
    String role,
    String userId,
    String notificationId,
  ) async {
    try {
      final response = await dio.put(
        '/api/notification/read/$role/$userId',
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

// ✅ MARK ALL NOTIFICATIONS AS READ
  Future<Response> markAllAsRead(String role, String userId) async {
    try {
      final response = await dio.patch(
        '/api/notification/read-all/$role/$userId',
        data: {
          'userId': userId,
        },
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

// ✅ GET UNREAD COUNT
  Future<Response> getUnreadCount(
    String role,
    String userId,
  ) async {
    try {
      final response = await dio.get(
        '/api/notification/unread/$role/$userId',
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

// ✅ GET UNREAD NOTIFICATIONS
  Future<Response> getUnreadNotifications(
    String role,
    String userId,
  ) async {
    try {
      final response = await dio.get(
        '/api/notification/unread/$role/$userId', // ← ADDED /api
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  //----------------------------------------------------------------------------------------------------------
  //Medicine Reminder CREATE
  Future<Response> createMedicineReminder(Map<String, dynamic> data) async {
    return await dio.post('/api/medicinereminders', data: data);
  }

  // ✅ Medicine Reminder GET (User- reminders)
  Future<Response> getUserMedicineReminders(String userId) async {
    return await dio.get('/api/medicinereminders/user/$userId');
  }

  Future<Response> getAllCarousel({double? latitude, double? longitude}) async {
    final Map<String, dynamic> queryParams = {};

    
    if (latitude != null && longitude != null) {
      queryParams['lat'] = latitude.toString();
      queryParams['lng'] = longitude.toString();
    }

    return await dio.get(
      '/api/ads',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  // GET all hospitals
  Future<Response> getAllHospitals(
    String query, {
    int page = 1,
    int limit = 10,
  }) async {
    return await dio.get(
      '/api/hospital',
      queryParameters: {"search_query": query, "page": page, "limit": limit},
    );
  }

  // GET a hospitals
  Future<Response> getAHospitals(String id) async {
    return await dio.get(
      '/api/hospital/$id',
      // "/hospital/$id"
    );
  }

//review
// Get all reviews
  Future<Response> getReviews({
    String? hospitalId,
    String? doctorId,
    int page = 1,
    int limit = 5,
  }) async {
    return await dio.get(
      '/api/review',
      queryParameters: {
        if (hospitalId != null) 'hospitalId': hospitalId,
        if (doctorId != null) 'doctorId': doctorId,
        'page': page,
        'limit': limit,
      },
    );
  }

// Create review
  Future<Response> createReview(
    Map<String, dynamic> reviewData,
  ) async {
    return await dio.post('/api/review', data: reviewData);
  }

// Update review
  Future<Response> updateReview(
    String reviewId,
    Map<String, dynamic> reviewData,
  ) async {
    return await dio.put('/api/review/$reviewId', data: reviewData);
  }

// Delete review
  Future<Response> deleteReview(String reviewId) async {
    return await dio.delete('/api/review/$reviewId');
  }

//Rating
  Future getRating({
    required String hospitalId,
    required String doctorId,
  }) async {
    final response = await dio.get(
      '/api/review/rating',
      queryParameters: {
        'hospitalId': hospitalId,
        'doctorId': doctorId,
      },
    );

    return response.data;
  }

  // GET all donors
  Future<Response> getAllDonors({
    String? userId,
    String? bloodGroup,
    String? pincode,
    String? place,
    String? country,
    String? state,
    String? district,
    String? searchQuery,
  }) async {
    final Map<String, dynamic> queryParams = {};

    if (userId != null) queryParams['userId'] = userId;
    if (bloodGroup != null) queryParams['bloodGroup'] = bloodGroup;
    if (pincode != null) queryParams['pincode'] = pincode;
    if (place != null) queryParams['place'] = place;
    if (country != null) queryParams['country'] = country;
    if (state != null) queryParams['state'] = state;
    if (district != null) queryParams['district'] = district;

    // ✅ backend expects search_query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['search_query'] = searchQuery;
    }

    return await dio.get('/api/donors', queryParameters: queryParams);
  }

  // CREATE donor
  Future<Response> createADonor(Map<String, dynamic> data) async {
    return await dio.post('/api/donors', data: data);
  }

  // UPDATE donor
  Future<Response> updateDonor(String id, Map<String, dynamic> data) async {
    return await dio.put('/api/donors/$id', data: data);
  }

  // DELETE donor
  Future<Response> deleteDonor(String id) async {
    return await dio.delete('/api/donors/$id');
  }

  Future<Response> loginUser(Map<String, dynamic> data) async {
    final response = await dio.post(
      '/api/users/login/phone',
      data: data,
    );

    final cookies = await cookieJar.loadForRequest(
      Uri.parse(
          //"http://35.174.10.32"
          "https://zorrowtek.in"),
    );

    for (final c in cookies) {}

    return response;
  }

  Future<Response> otpUser(Map<String, dynamic> data) async {
    return await dio.post('/api/users/otp', data: data);
  }

  // SIGNUP
  Future<Response> signupUser(Map<String, dynamic> data) async {
    return await dio.post('/api/users', data: data);
  }

  Future<Response> getAUser(String id) async {
    return await dio.get('/api/users/$id');
  }

  Future<Response> deleteAUser(String id) async {
    return await dio.delete('/api/users/$id');
  }

  // Update user
  Future<Response> updateUser(String id, Map<String, dynamic> data) async {
    return await dio.put('/api/users/$id', data: data);
  }

  Future<Response> updateUserWithImage(
    String id,
    Map<String, dynamic> data,
    File? imageFile,
  ) async {
    try {
      if (imageFile != null) {
        // Use FormData for file upload
        String fileName =
            'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

        FormData formData = FormData.fromMap({
          'name': data['name'],
          'email': data['email'],
          'phone': data['phone'],
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: fileName,
          ),
        });

        return await dio.put(
          '/api/users/$id',
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
            headers: {'Content-Type': 'multipart/form-data'},
          ),
        );
      } else {
        // Regular update without image
        return await dio.put('/api/users/$id', data: data);
      }
    } catch (e) {
      rethrow;
    }
  }

  // In api_service.dart
  Future<Response> getAllSpecility({String? searchQuery}) async {
    String url = '/api/speciality';
    if (searchQuery != null && searchQuery.isNotEmpty) {
      url += '?search_query=$searchQuery';
    }

    return await dio.get(url);
  }

  // GET Ambulances
  Future<Response> getAllAmbulances({
    String? userId,
    String? serviceName,
    String? place,
    String? country,
    String? state,
    String? district,
    String? pincode,
    String? searchQuery,
  }) async {
    final Map<String, dynamic> queryParams = {};
    if (userId != null) queryParams['userId'] = userId;
    if (serviceName != null) queryParams['name'] = serviceName;
    if (place != null) queryParams['place'] = place;
    if (country != null) queryParams['country'] = country;
    if (state != null) queryParams['state'] = state;
    if (district != null) queryParams['district'] = district;
    if (pincode != null) queryParams['pincode'] = pincode;
    if (searchQuery != null && searchQuery.isNotEmpty) // 👈 add search_query
      queryParams['search_query'] = searchQuery;

    return await dio.get('/api/ambulance', queryParameters: queryParams);
  }

  // DELETE ambulance
  Future<Response> deleteAmbulance(String id) async {
    return await dio.delete('/api/ambulance/$id');
  }

  // EDIT ambulance
  Future<Response> editAmbulance(
    String id,
    Map<String, dynamic> updatedData,
  ) async {
    return await dio.put('/api/ambulance/$id', data: updatedData);
  }

  //create Ambulance
  Future<Response> createAmbulance(Map<String, dynamic> data) async {
    return await dio.post('/api/ambulance', data: data);
  }

  Future<Response> createBooking(Map<String, dynamic> bookingData) async {
    return await dio.post('/api/booking', data: bookingData);
  }

//Booking
  Future<Response> getAllBookings({
    String? userId,
    String? status,
    String? doctorName,
    String? searchQuery,
    int? page,
    int? limit,
    String? date,
  }) async {
    final Map<String, dynamic> queryParams = {};

    if (userId != null) queryParams['userId'] = userId;
    if (status != null) queryParams['status'] = status;
    if (searchQuery != null) queryParams['search_query'] = searchQuery;

    if (page != null) queryParams['page'] = page;
    if (limit != null) queryParams['limit'] = limit;
    if (date != null) {
      queryParams["date"] = date;
    }

    return await dio.get('/api/booking', queryParameters: queryParams);
  }

  Future<Response> updateBooking(
    String bookingId,
    Map<String, dynamic> data,
  ) async {
    return await dio.put('/api/booking/$bookingId', data: data);
  }

  Future<Response> getDoctors({
    String? hospitalId,
    String? speciality,
    String? searchQuery,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, dynamic>{};

    if (hospitalId != null) queryParams['hospitalId'] = hospitalId;
    if (speciality != null) queryParams['speciality'] = speciality;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['search_query'] = searchQuery;
    }

    // ✅ pagination params
    queryParams['page'] = page;
    queryParams['limit'] = limit;

    return await dio.get('/api/doctor', queryParameters: queryParams);
  }

  Future<Response> getDoctorById(String doctorId) async {
    return await dio.get('/api/doctor/$doctorId');
  }

//-------------------------------------------------
  Future<Response> sendEmail(Map<String, dynamic> emailData) async {
    try {
      final response = await dio.post(
        '/api/email-enquiry', // Your endpoint
        data: emailData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      // Log the error

      rethrow;
    }
  }

  //forgot password
  // SEND RESET PASSWORD OTP
  Future<Response> sendResetPasswordOtp(Map<String, dynamic> data) async {
    return await dio.post('/api/users/auth/send-otp', data: data);
  }

  // VERIFY RESET PASSWORD OTP
  Future<Response> verifyResetPasswordOtp(Map<String, dynamic> data) async {
    return await dio.post('/api/users/auth/verify-otp', data: data);
  }

  // RESET PASSWORD
  Future<Response> resetForgotPassword(Map<String, dynamic> data) async {
    return await dio.post('/api/users/auth/reset-password', data: data);
  }

  // ✅ CHANGE PASSWORD (new method)
  Future<Response> changePassword(Map<String, dynamic> data) async {
    return await dio.put('/api/users/auth/change-password', data: data);
  }
  //   // ================= PHARMACY =================

  //s3 imge
  Future<Map<String, dynamic>> uploadProfileImage(
    File file,
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    final fileName = file.path.split('/').last;
    final fileSize = await file.length();

    try {
      // =========================
      // 1. GET PRESIGNED URL
      // =========================
      final res = await dio.post(
        '/api/presignurl',
        data: {
          "filename": fileName,
          "contentType": "image/jpeg",
          "size": fileSize,
          "role": "user",
          "id": int.parse(userId),
        },
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      final presignedUrl =
          res.data["presignedUrl"] ?? res.data["data"]?["presignedUrl"];
      final key = res.data["key"] ?? res.data["data"]?["key"];

      if (presignedUrl == null || key == null) {
        throw Exception("Presign failed");
      }

      // =========================
      // 2. UPLOAD TO S3 (FIXED)
      // =========================
      final bytes = await file.readAsBytes();

      final uploadRes = await http.put(
        Uri.parse(presignedUrl),
        headers: {"Content-Type": "image/jpeg"},
        body: bytes,
      );

      if (uploadRes.statusCode != 200 && uploadRes.statusCode != 201) {
        throw Exception("S3 Upload Failed: ${uploadRes.body}");
      }

      // =========================
      // 3. RETURN RESULT
      // =========================
      return {
        "key": key,
        "imageUrl": "https://hostahealthcare.s3.eu-north-1.amazonaws.com/$key",
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadFileToS3({
    required File file,
    required String id,
    required String role,
  }) async {
    final fileName = file.path.split('/').last;
    final fileSize = await file.length();

    String contentType = "application/octet-stream";

    if (fileName.endsWith(".pdf")) {
      contentType = "application/pdf";
    } else if (fileName.endsWith(".png")) {
      contentType = "image/png";
    } else if (fileName.endsWith(".jpg") || fileName.endsWith(".jpeg")) {
      contentType = "image/jpeg";
    }

    // 1. GET PRESIGNED URL
    final res = await dio.post(
      '/api/presignurl',
      data: {
        "filename": fileName,
        "contentType": contentType,
        "size": fileSize,
        "role": role,
        "id": int.parse(id),
      },
    );

    final presignedUrl =
        res.data["presignedUrl"] ?? res.data["data"]["presignedUrl"];

    final key = res.data["key"] ?? res.data["data"]["key"];

    // 2. UPLOAD TO S3
    final bytes = await file.readAsBytes();

    final uploadRes = await http.put(
      Uri.parse(presignedUrl),
      headers: {"Content-Type": contentType},
      body: bytes,
    );

    if (uploadRes.statusCode != 200 && uploadRes.statusCode != 201) {
      throw Exception("S3 Upload Failed");
    }

    // 3. RETURN
    return {
      "key": key,
      "url": "https://hostahealthcare.s3.eu-north-1.amazonaws.com/$key",
    };
  }

  Future<bool> deleteProfileImage(String key, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    try {
      final res = await dio.delete(
        '/api/presignurl',
        data: {"key": key, "role": "user", "id": int.parse(userId)},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("S3 Delete Failed");
      }

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> getPatients({
    required int userId,
    int? hospitalId,
  }) async {
    return await dio.get(
      '/api/patients',
      queryParameters: {
        'userId': userId,
        if (hospitalId != null) 'hospitalId': hospitalId,
      },
    );
  }

//..........Documents...................
  Future<List<Document>> getDocuments({required int patientId}) async {
    final response = await dio.get(
      '/api/documents',
      queryParameters: {
        'patientId': patientId,
      },
    );

    final data = response.data['data'];

    if (data is! List) return [];

    return data.map((e) => Document.fromJson(e)).toList();
  }

  Future<Response> createDocument(Map<String, dynamic> data) async {
    return await dio.post('/api/documents', data: data);
  }

  Future<Response> updateDocument(String id, Map<String, dynamic> data) {
    return dio.put('/api/documents/$id', data: data);
  }

  Future deleteDocument(int id, Map data) async {
    return dio.delete('/api/documents/$id', data: data);
  }

  Future<Response> getCategories({
    String? searchQuery,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, dynamic>{};

    if (searchQuery != null && searchQuery.isNotEmpty) {
      // ✅ Search mode: only search_query, NO page/limit, keep /api/category
      queryParams['search_query'] = searchQuery;
    } else {
      // ✅ Normal list mode: page and limit
      queryParams['page'] = page;
      queryParams['limit'] = limit;
    }

    return await dio.get('/api/category', queryParameters: queryParams);
  }

//logout
  Future<Response> logout() async {
    return await dio.post('/api/users/logout');
  }
}
