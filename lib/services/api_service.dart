import 'dart:developer';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

     class ApiService {
      String? _accessToken;
String? _refreshToken;
bool _isRefreshing = false;
         late final Dio _dio;  
         late final Dio _refreshDio; 
final cookieJar = CookieJar();
  // ✅ Add constructor
  ApiService() {
    // _dio = Dio(BaseOptions(baseUrl: "https://zorrowtek.in",
    //  connectTimeout: const Duration(seconds: 30),
    //   receiveTimeout: const Duration(seconds: 30),
    //     headers: {
    //     'Content-Type': 'application/json',
    //   },
    //   ));
      _dio = Dio(
  BaseOptions(
    baseUrl: "https://zorrowtek.in",
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
       receiveDataWhenStatusError: true,
  ),
);

_refreshDio = Dio(
  BaseOptions(
    baseUrl: "https://zorrowtek.in",
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
       receiveDataWhenStatusError: true,
  ),
);
  _dio.interceptors.add(CookieManager(cookieJar));
  _refreshDio.interceptors.add(CookieManager(cookieJar));
 
  _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
  if (_accessToken != null && _accessToken!.isNotEmpty) {
    options.headers['Authorization'] = 'Bearer $_accessToken';
  }

  handler.next(options);
},
        // onRequest: (options, handler) async {
        //   final prefs =
        //       await SharedPreferences.getInstance();

        //   final token =
        //       prefs.getString('authToken');

        //   if (token != null &&
        //       token.isNotEmpty) {
        //     options.headers['Authorization'] =
        //         'Bearer $token';

        //     print("🔐 TOKEN ADDED");
        //   }

        //   print(
        //       "📡 ${options.method} ${options.path}");

        //   handler.next(options);
        // },

        // ================= 401 HANDLER =================

     onError: (error, handler) async {
  if (error.response?.statusCode != 401) {
  return handler.next(error);
}

if (_isRefreshing) {
  return handler.next(error);
}

_isRefreshing = true;

try {
  final refreshToken = _refreshToken;

  if (refreshToken == null || refreshToken.isEmpty) {
    _isRefreshing = false;
    await SharedPreferences.getInstance()
      ..clear();
    return handler.next(error);
  }

  final refreshResponse = await _refreshDio.post(
    '/api/users/refresh',
    data: {"refreshToken": refreshToken},
  );

  final newAccessToken = refreshResponse.data['accessToken'];

  _accessToken = newAccessToken;

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('authToken', newAccessToken);

  final options = error.requestOptions;
  options.headers['Authorization'] = 'Bearer $newAccessToken';

  _isRefreshing = false;

  final response = await _dio.fetch(options);
  return handler.resolve(response);

} catch (e) {
  _isRefreshing = false;

  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  return handler.next(error);
}
}
      ),
  );
    // ================= RETRY =================

    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 3),
        ],
      ),
    );
  }


Future<void> init() async {
  final prefs = await SharedPreferences.getInstance();

  _accessToken = prefs.getString('authToken');
  _refreshToken = prefs.getString('refreshToken');
}

// Refresh Token - 
Future<Response> refreshUserToken(Map<String, dynamic> data) async {
  return await _dio.post('/api/users/refresh', data: data);
}
  //Medicine Reminder CREATE
 Future<Response> createMedicineReminder(Map<String, dynamic> data) async {
    return await _dio.post('/api/medicinereminders', data: data);
  }

  // ✅ Medicine Reminder GET (User- reminders)
  Future<Response> getUserMedicineReminders(String userId) async {
    return await _dio.get('/api/medicinereminders/user/$userId');
  }


Future<Response> getAllCarousel({
  double? latitude,
  double? longitude,
}) async {
  final Map<String, dynamic> queryParams = {};
  
  // Only add location parameters if they are provided
  if (latitude != null && longitude != null) {
    queryParams['lat'] = latitude.toString();
    queryParams['lng'] = longitude.toString();
  }

  return await _dio.get(
    '/api/ads/nearby',
    queryParameters: queryParams.isNotEmpty ? queryParams : null,
  );
}

// Future<Response> getAllCarousel({
//   double? latitude,
//   double? longitude,
// }) async {
//   final Map<String, dynamic> queryParams = {};

//   // Use provided coordinates or fallback defaults
//   queryParams['lat'] = (latitude ?? 10.995653).toString();
//   queryParams['lng'] = (longitude ?? 75.991806).toString();

//   return await _dio.get(
//     '/api/ads/nearby',
//     queryParameters: queryParams,
//   );
// }



  // GET all hospitals
  Future<Response> getAllHospitals(String query) async {
    return await _dio.get(
        queryParameters: {
      "search_query": query,
    },
    '/api/hospital'
      // "/hospital"
      );

  }

   // GET a hospitals
  Future<Response> getAHospitals(String id) async {
    return await _dio.get(
      '/api/hospital/$id'
      // "/hospital/$id"
      );
  }


  //   Future<Response> getAllHospitalsSpeciality(String search) async {
  //   return await _dio.get('/api/hospital/filter/$search');
  // }



  Future<Response> getAHospitalsReview(String id) async {
    return await _dio.get('/api/reviews/hospital/$id');
  }


  // Create a reviewf
  Future<Response> createAHospitalReview(Map<String, dynamic> reviewData) async {
    return await _dio.post(
      '/api/reviews',
      data: reviewData,
    );
  }

  // Update a review
  Future<Response> updateAHospitalReview(String id, Map<String, dynamic> reviewData) async {
    return await _dio.put(
      '/api/reviews/$id',
      data: reviewData,
    );
  }

      Future<Response> deleteAHospitalReview(String id) async {
    return await _dio.delete('/api/reviews/$id');
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

  return await _dio.get(
    '/api/donors',
    queryParameters: queryParams,
  );
}

  // GET single donor
  // Future<Response> getADonor(String id) async {
  //   return await _dio.get('/api/donors/$id');
  // }

  // CREATE donor
  Future<Response> createADonor(Map<String, dynamic> data) async {
    return await _dio.post('/api/donors', data: data);
  }
// UPDATE donor
Future<Response> updateDonor(String id, Map<String, dynamic> data) async {
  return await _dio.put('/api/donors/$id', data: data);
}
  // DELETE donor
 Future<Response> deleteDonor(String id) async {
  print("DELETE DONOR ID => $id");

  return await _dio.delete('/api/donors/$id');
}

  // LOGIN
  Future<Response> loginUser(Map<String, dynamic> data) async {
    log("response$data");
    return await _dio.post(
      '/api/users/login/phone'

      , data: data);
  }

  Future<Response> otpUser(Map<String, dynamic> data) async {
    return await _dio.post(
      '/api/users/otp'
   
      , data: data);
  }

  // SIGNUP
  Future<Response> signupUser(Map<String, dynamic> data) async {
    return await _dio.post(
      '/api/users'

      , data: data);
  }

    Future<Response> getAUser(String id) async {
    return await _dio.get(
      '/api/users/$id'
  
      );
  }

    Future<Response> deleteAUser(String id) async {
    return await _dio.delete(
      '/api/users/$id'
      
      );
  }

  // Update user
  Future<Response> updateUser(String id, Map<String, dynamic> data) async {
    return await _dio.put('/api/users/$id', data: data);
  }

   Future<Response> updateUserWithImage(String id, Map<String, dynamic> data, File? imageFile) async {
    try {
      if (imageFile != null) {
        // Use FormData for file upload
        String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        FormData formData = FormData.fromMap({
          'name': data['name'],
          'email': data['email'],
          'phone': data['phone'],
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: fileName,
          ),
        });
        
        return await _dio.put(
          '/api/users/$id',
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
            headers: {
              'Content-Type': 'multipart/form-data',
            },
          ),
        );
      } else {
        // Regular update without image
        return await _dio.put('/api/users/$id', data: data);
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
  return await _dio.get(url);
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
  if (searchQuery != null && searchQuery.isNotEmpty)   // 👈 add search_query
    queryParams['search_query'] = searchQuery;

  log("📤 QUERY PARAMS: $queryParams");
  return await _dio.get('/api/ambulance', queryParameters: queryParams);
}
  //  GET MY AMBULANCE 
Future<Response> getMyAmbulance(String id) async {
  return await _dio.get('/api/ambulance/$id');
}
// DELETE ambulance
Future<Response> deleteAmbulance(String id) async {
  return await _dio.delete('/api/ambulance/$id');
}
// EDIT ambulance
Future<Response> editAmbulance(String id, Map<String, dynamic> updatedData) async {
  return await _dio.put('/api/ambulance/$id', data: updatedData);
}
//create Ambulance
 Future<Response> createAmbulance(Map<String, dynamic> data) async {
    return await _dio.post('/api/ambulance', data: data);
  }

  // GET Notifications
  Future<Response> getAllNotificationRead(String id) async {
    return await _dio.get('/api/notifications/user/read/$id');
  }

  Future<Response> getAllNotificationUnRead(String id) async {
    return await _dio.get('/api/notifications/user/no-read/$id');
  }

  // PATCH read all notifications
  Future<Response> allReadNotifications(String id) async {
    return await _dio.patch('/api/notifications/user/read-all/$id');
  }

  // PATCH single notification
  Future<Response> aReadNotification(String id) async {
    return await _dio.patch('/api/notifications/user/$id');
  }


  //create booking
  // Future<Response> createBooking(Map<String, dynamic> userId, Map<String, dynamic> data) async {
  //   print('📡 Creating booking for user: $userId');
  //   return await _dio.post('/api/booking', data: data);
  // }
// Future<Response> createBooking(String hospitalId,Map<String, dynamic> bookingData) async {
//   return await _dio.post(
//     '/booking/$hospitalId',
//     data: bookingData,
//   );
// }

 Future<Response> createBooking(Map<String, dynamic> bookingData) async {
  print('📡 POST /api/booking');
  print('📡 Data: $bookingData');

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');
  return await _dio.post('/api/booking', data: bookingData);

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

Future<Response> getAllBookings({
  String? userId,
  String? status,
  String? doctorName,
  String? searchQuery,
  int? page,
  int? limit,
}) async {
  final Map<String, dynamic> queryParams = {};

  if (userId != null) queryParams['userId'] = userId;
  if (status != null) queryParams['status'] = status;
  if (searchQuery != null) queryParams['search_query'] = searchQuery;

  if (page != null) queryParams['page'] = page;
  if (limit != null) queryParams['limit'] = limit;

  return await _dio.get(
    '/api/booking',
    queryParameters: queryParams,
  );
}
// GET bookings
// Future<Response> getAllBookings({
//   String? userId,
//   String? status,
//   String? doctorName,
// }) async {
//   final Map<String, dynamic> queryParams = {};

//   if (userId != null) queryParams['userId'] = userId;
//   if (status != null) queryParams['status'] = status;
//   if (doctorName != null) queryParams['doctor_name'] = doctorName;
// log("QUERY PARAMS = $queryParams");
//   log('📡 GET /api/booking with queryParams: $queryParams');
//   return await _dio.get('/api/booking', queryParameters: queryParams);
  
// }

  // UPDATE booking
  // Future<Response> updateBooking(String bookingId, String hospitalId, Map<String, dynamic> data) async {
  //   print('📡 Updating booking: $bookingId for hospital: $hospitalId');
  //   return await _dio.put('/api/booking/$bookingId/hospital/$hospitalId', data: data);
  // }

Future<Response> updateBooking(
  String bookingId,
  Map<String, dynamic> data,
) async {
  print('📡 Updating booking: $bookingId');
  return await _dio.put(
    '/api/booking/$bookingId',
    data: data,
  );
}

/// Get doctors with optional filters
// Future<Response> getDoctors({

//   String? hospitalId,
//   String? speciality,  
//   String? id,
// }) async {
//   final queryParams = <String, dynamic>{};
//   if (hospitalId != null) queryParams['id'] = hospitalId;
//   if (speciality != null) queryParams['speciality'] = speciality; 
//    // ✅ key: 'speciality'
//   if (id != null) queryParams['id'] = id;
//   log("$id");
//    log("$hospitalId");
//    log("$queryParams");
//   return await _dio.get('/api/doctor', queryParameters: queryParams);
 
    
// }
Future<Response> getDoctors({
  String? hospitalId,
  String? speciality,
  String? searchQuery,   // new parameter
}) async {
  final queryParams = <String, dynamic>{};
  if (hospitalId != null) queryParams['hospitalId'] = hospitalId;
  if (speciality != null) queryParams['speciality'] = speciality;
  if (searchQuery != null && searchQuery.isNotEmpty) {
    queryParams['search_query'] = searchQuery;
  }
  log("Calling /api/doctor with params: $queryParams");
  return await _dio.get('/api/doctor', queryParameters: queryParams);
}

// In api_service.dart

Future<Response> getDoctorById(String doctorId) async {
  print("🔵 GET Doctor by ID API Call");
  print("🔵 URL: /api/doctor/$doctorId");
  
  return await _dio.get(
    '/api/doctor/$doctorId',
  );
}
  // UPDATE booking
  // Future<Response> getFilter(String filter) async {
  //   return await _dio.get('/api/hospital/filter/$filter');
  // }

    Future<Response> sendEmail( Map<String, dynamic> data) async {
    return await _dio.post('/api/email', data: data);
  }

  //forgot password
// SEND RESET PASSWORD OTP
Future<Response> sendResetPasswordOtp(
    Map<String, dynamic> data) async {
  return await _dio.post(
    '/api/users/auth/send-otp',
    data: data,
  );
}

// VERIFY RESET PASSWORD OTP
Future<Response> verifyResetPasswordOtp(
    Map<String, dynamic> data) async {
  return await _dio.post(
    '/api/users/auth/verify-otp',
    data: data,
  );
}

// RESET PASSWORD
Future<Response> resetForgotPassword(
    Map<String, dynamic> data) async {
  return await _dio.post(
    '/api/users/auth/reset-password',
    data: data,
  );
}
  // Future<Response> sendResetPasswrord( Map<String, dynamic> data) async {
  //   return await _dio.post('/api/users/password', data: data);
  // }
    // ✅ CHANGE PASSWORD (new method)
 Future<Response> changePassword(Map<String, dynamic> data) async {
  return await _dio.put('/api/users/auth/change-password', data: data);
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
Future<Response> getAmbulance(String userId) async {
  return await _dio.get('/api/ambulance/user/$userId');
}
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
      final res = await _dio.post(
        '/api/presignurl',
        data: {
          "filename": fileName,
          "contentType": "image/jpeg",
          "size": fileSize,
          "role": "user",
          "id": int.parse(userId),
        },
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
          },
        ),
      );

      final presignedUrl = res.data["presignedUrl"] ?? res.data["data"]?["presignedUrl"];
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
        headers: {
          "Content-Type": "image/jpeg",
        },
        body: bytes,
      );

      print("UPLOAD STATUS => ${uploadRes.statusCode}");

      if (uploadRes.statusCode != 200 &&
          uploadRes.statusCode != 201) {
        throw Exception("S3 Upload Failed: ${uploadRes.body}");
      }

      // =========================
      // 3. RETURN RESULT
      // =========================
      return {
        "key": key,
        "imageUrl":
            "https://hostahealthcare.s3.eu-north-1.amazonaws.com/$key",
      };
    } catch (e) {
      print("❌ S3 ERROR => $e");
      rethrow;
    }
  }
  Future<bool> deleteProfileImage(
  String key,
  String userId,
) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');

  print("=== S3 DELETE START ===");
  print("key: $key");
  print("id: $userId");

  try {
    final res = await _dio.delete(
      '/api/presignurl',
      data: {
        "key": key,
        "role": "user",
        "id": int.parse(userId),
      },
      options: Options(
        headers: {
          "Authorization": "Bearer $token",
        },
      ),
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
     }