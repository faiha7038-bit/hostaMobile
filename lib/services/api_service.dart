import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'token_manager.dart';

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
log("TOKEN => $token");
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
  log("HEADERS => ${options.headers}");
          log("📡 ${options.method} ${options.path}");
          handler.next(options);
        },

        onError: (error, handler) async {
          log("🔥 ON ERROR CALLED");
  log("STATUS => ${error.response?.statusCode}");
  log("PATH => ${error.requestOptions.path}");
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
    log("✅ ApiService Initialized (Singleton)");
  }
Future<String?> _getRefreshTokenFromCookies() async {
  final cookies = await cookieJar.loadForRequest(
    Uri.parse("https://zorrowtek.in"),
    
  );

  for (final cookie in cookies) {
    log("COOKIE => ${cookie.name} = ${cookie.value}");
log("COOKIE COUNT => ${cookies.length}");
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
  log("refresh token called");
  log("REFRESH RESPONSE => ${res.data}");

  final newToken = res.data['token'];

  if (newToken != null) {
    await TokenManager.saveAccessToken(newToken);
    log("✅ NEW ACCESS TOKEN SAVED");
  }

  return newToken;
}



  // ---------------- PRESCRIPTION ----------------
  Future<Response> getPrescriptions({
    String? userId,
    int page = 1,
    int limit = 10,
  }) async {
    return await dio.get(
      '/api/prescription',
      queryParameters: {
        if (userId != null) "userId": userId,
        "page": page,
        "limit": limit,
      },
    );
  }



  // ---------------- NOTIFICATIONS ----------------
  Future<Response> getNotifications(String userId) async {
    return await dio.get('/api/notifications/user/no-read/$userId');
  }

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

    // Only add location parameters if they are provided
    if (latitude != null && longitude != null) {
      queryParams['lat'] = latitude.toString();
      queryParams['lng'] = longitude.toString();
    }

    return await dio.get(
      '/api/ads/nearby',
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



  Future<Response> getAHospitalsReview(String id) async {
    return await dio.get('/api/reviews/hospital/$id');
  }

  // Create a reviewf
  Future<Response> createAHospitalReview(
    Map<String, dynamic> reviewData,
  ) async {
    return await dio.post('/api/reviews', data: reviewData);
  }

  // Update a review
  Future<Response> updateAHospitalReview(
    String id,
    Map<String, dynamic> reviewData,
  ) async {
    return await dio.put('/api/reviews/$id', data: reviewData);
  }

  Future<Response> deleteAHospitalReview(String id) async {
    return await dio.delete('/api/reviews/$id');
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

    print("📤 QUERY PARAMS: $queryParams");

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
    print("DELETE DONOR ID => $id");

    return await dio.delete('/api/donors/$id');
  }

Future<Response> loginUser(Map<String, dynamic> data) async {
  log("LOGIN ApiService instance => ${hashCode}");
  final response = await dio.post(
    '/api/users/login/phone',
    data: data,
    
  );

final cookies = await cookieJar.loadForRequest(
  Uri.parse("https://zorrowtek.in"),
);

for (final c in cookies) {
  log("COOKIE => ${c.name} = ${c.value}");
}
 

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
      print('Error in updateUserWithImage: $e');
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

    log("📤 QUERY PARAMS: $queryParams");
    return await dio.get('/api/ambulance', queryParameters: queryParams);
  }

  //  GET MY AMBULANCE
  // Future<Response> getMyAmbulance(String id) async {
  //   return await _dio.get('/api/ambulance/$id');
  // }

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

  // GET Notifications
  Future<Response> getAllNotificationRead(String id) async {
    return await dio.get('/api/notifications/user/read/$id');
  }

  Future<Response> getAllNotificationUnRead(String id) async {
    return await dio.get('/api/notifications/user/no-read/$id');
  }

  // PATCH read all notifications
  Future<Response> allReadNotifications(String id) async {
    return await dio.patch('/api/notifications/user/read-all/$id');
  }

  // PATCH single notification
  Future<Response> aReadNotification(String id) async {
    return await dio.patch('/api/notifications/user/$id');
  }



  Future<Response> createBooking(Map<String, dynamic> bookingData) async {
    print('📡 POST /api/booking');
    print('📡 Data: $bookingData');

    //final prefs = await SharedPreferences.getInstance();
    // final token = prefs.getString('authToken');
    return await dio.post('/api/booking', data: bookingData);

    // final response = await _dio.post(
    //   '/api/booking',
    //   data: bookingData,
    //   options: Options(
    //     headers: {
    //       "Authorization": "Bearer $token",
    //       "Content-Type": "application/json",
    //     },
    //   ),
    // );

    // return response; // ✅ THIS WAS MISSING
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
  log("GET BOOKINGS PARAMS:");
log("userId = $userId");
log("status = $status");
log("searchQuery = $searchQuery");
log("page = $page");
log("limit = $limit");
log("date=$date");
    return await dio.get('/api/booking', queryParameters: queryParams);
  }


  Future<Response> updateBooking(
    String bookingId,
    Map<String, dynamic> data,
  ) async {
    print('📡 Updating booking: $bookingId');
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

    log("Calling /api/doctor with params: $queryParams");

    return await dio.get('/api/doctor', queryParameters: queryParams);
  }

  // In api_service.dart

  Future<Response> getDoctorById(String doctorId) async {
    print("🔵 GET Doctor by ID API Call");
    print("🔵 URL: /api/doctor/$doctorId");

    return await dio.get('/api/doctor/$doctorId');
  }
  // UPDATE booking
  // Future<Response> getFilter(String filter) async {
  //   return await _dio.get('/api/hospital/filter/$filter');
  // }

  Future<Response> sendEmail(Map<String, dynamic> data) async {
    return await dio.post('/api/email', data: data);
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

  // Future<Response> sendResetPasswrord( Map<String, dynamic> data) async {
  //   return await _dio.post('/api/users/password', data: data);
  // }
  // ✅ CHANGE PASSWORD (new method)
  Future<Response> changePassword(Map<String, dynamic> data) async {
    return await dio.put('/api/users/auth/change-password', data: data);
  }
  //   // ================= PHARMACY =================

  // // GET all pharmacies
  // Future<Response> getPharmacies() async {
  //   return await _dio.get('/api/pharmacy');
  //   // 🔥 change if your backend route is different
  // }

  // // CREATE pharmacy order
  // Future<Response> createPharmacyOrder(Map<String, dynamic> data) async {
  //   return await _dio.post('/api/pharmacy/order', data: data);
  // }
  // Future<Response> getAmbulance(String userId) async {
  //   return await _dio.get('/api/ambulance/user/$userId');
  // }

  //s3 imge
  Future<Map<String, dynamic>> uploadProfileImage(
    File file,
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    final fileName = file.path.split('/').last;
    final fileSize = await file.length();

    print("=== S3 DEBUG START ===");
    print("filename: $fileName");
    print("size: $fileSize");
    print("id: $userId");

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
      print("key:$key");
      print("PRESIGN OK");

      // =========================
      // 2. UPLOAD TO S3 (FIXED)
      // =========================
      final bytes = await file.readAsBytes();

      final uploadRes = await http.put(
        Uri.parse(presignedUrl),
        headers: {"Content-Type": "image/jpeg"},
        body: bytes,
      );

      print("UPLOAD STATUS => ${uploadRes.statusCode}");

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
      print("❌ S3 ERROR => $e");
      rethrow;
    }
  }

  Future<bool> deleteProfileImage(String key, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    print("=== S3 DELETE START ===");
    print("key: $key");
    print("id: $userId");

    try {
      final res = await dio.delete(
        '/api/presignurl',
        data: {"key": key, "role": "user", "id": int.parse(userId)},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      print("DELETE STATUS => ${res.statusCode}");

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("S3 Delete Failed");
      }

      print("DELETE SUCCESS");

      return true;
    } catch (e) {
      print("❌ S3 DELETE ERROR => $e");
      rethrow;
    }
  }

 
  Future<Response> getPatients({
    required int hospitalId,
    required int userId,
  }) async {
    return await dio.get(
      '/api/patients',
      queryParameters: {'hospitalId': hospitalId, 'userId': userId},
    );
  }
  //prescription
//  Future<Response> getPrescriptions({
//   String? userId,
//   int page = 1,
//   int limit = 10,
//   String? date,
// }) async {

//   final Map<String, dynamic> queryParams = {};

//   if (userId != null && userId.isNotEmpty) {
//     queryParams['userId'] = userId;
//   }

//   queryParams['page'] = page;
//   queryParams['limit'] = limit;

//   if (date != null && date.isNotEmpty) {
//     queryParams['date'] = date;
//   }

//   print("📤 PRESCRIPTION QUERY PARAMS: $queryParams");

//   return await dio.get(
//     '/api/prescription',
//     queryParameters: queryParams,
//   );
// }
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

  log("Calling /api/category with params: $queryParams");
  return await dio.get('/api/category', queryParameters: queryParams);
}
}
