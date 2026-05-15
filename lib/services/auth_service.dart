import 'package:hosta/services/api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  Future<String?> refreshAccessToken(String refreshToken) async {
    try {
      // ApiService- refreshUserToken function call 
      final response = await _apiService.refreshUserToken({
        'refreshToken': refreshToken,
      });
         
      if (response.statusCode == 200) {
        // Backend-
        String newAccessToken = response.data['accessToken'];
        
        // Secure storage- save  (shared_preferences / flutter_secure_storage)
        await saveAccessToken(newAccessToken);
        
        return newAccessToken;
      } else {
        print('Refresh failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error refreshing token: $e');
      return null;
    }
  }

  // Save access token
  Future<void> saveAccessToken(String token) async {
    
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('access_token', token);
  }
}