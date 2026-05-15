import 'dart:developer';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:shared_preferences/shared_preferences.dart';

     class ApiService {
         late final Dio _dio;   

  // ✅ Add constructor
  ApiService() {
    _dio = Dio(BaseOptions(baseUrl: "https://zorrowtek.in"));
      _dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        print("✅ Token added to request");
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        print("🔄 401 detected - refreshing token...");
        try {
          final prefs = await SharedPreferences.getInstance();
          final refreshToken = prefs.getString('refreshToken');
          if (refreshToken == null) throw Exception("No refresh token");

          // Call refresh API
          final response = await refreshUserToken({'refreshToken': refreshToken});
          if (response.statusCode == 200 && response.data['success'] == true) {
            final newToken = response.data['accessToken']; // adjust key
            await prefs.setString('authToken', newToken);
            
            // Retry original request with new token
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await _dio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          } else {
            throw Exception("Refresh failed");
          }
        } catch (e) {
          // Refresh failed -> logout
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('authToken');
          await prefs.remove('refreshToken');
          await prefs.remove('userId');
          print("❌ Refresh failed. Please login again.");
          return handler.next(error);
        }
      }
      handler.next(error);
    },
  ));
    
    // ✅ Add retry interceptor
    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
      ],
      retryableExtraStatuses: {429},
    ));
  }
//  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://zorrowtek.in',
//  connectTimeout: const Duration(seconds: 30),
//     receiveTimeout: const Duration(seconds: 30),));
 
// http://10.0.2.2:3000
// https://www.zorrowtek.in

 // GET all carousel

// Refresh Token - 
Future<Response> refreshUserToken(Map<String, dynamic> data) async {
  return await _dio.post('/api/users/refreshToken', data: data);
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
  Future<Response> getAllHospitals() async {
    return await _dio.get(
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
  Future<Response> getAllDonors() async {
    return await _dio.get('/api/donors');
  }

  // GET single donor
  Future<Response> getADonor(String id) async {
    return await _dio.get('/api/donors/$id');
  }

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
    return await _dio.delete(
      //'/api/donors/$id'
      "/api/ambulance/$id"
      );
  }

  // LOGIN
  Future<Response> loginUser(Map<String, dynamic> data) async {
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

 Future<Response> getAllSpecility() async {
    return await _dio.get('/api/speciality');
  }

  // GET Ambulances
  Future<Response> getAllAmbulances() async {
    return await _dio.get('/api/ambulance');
    
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

  // GET bookings
  Future<Response> getAllBookings(String id) async {
    return await _dio.get('/api/booking/$id');
  }

  // UPDATE booking
  Future<Response> createBooking(String id, Map<String, dynamic> data) async {
    return await _dio.post('/api/bookings/$id', data: data);
  }


  // UPDATE booking
  Future<Response> updateBooking(String bookingId, String hospitalId, Map<String, dynamic> data) async {
    return await _dio.put('/api/bookings/$bookingId/hospital/$hospitalId', data: data);
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
   // String? id,
}) async {
  final queryParams = <String, dynamic>{};
  if (hospitalId != null) queryParams['hospitalId'] = hospitalId;
  if (speciality != null) queryParams['speciality'] = speciality;
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
  Future<Response> getFilter(String filter) async {
    return await _dio.get('/api/hospital/filter/$filter');
  }

    Future<Response> sendEmail( Map<String, dynamic> data) async {
    return await _dio.post('/api/email', data: data);
  }


  Future<Response> sendResetPasswrord( Map<String, dynamic> data) async {
    return await _dio.post('/api/users/password', data: data);
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


}

  






