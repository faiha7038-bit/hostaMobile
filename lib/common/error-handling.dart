import 'dart:convert';

String getErrorMessage(dynamic response) {
  try {
    if (response is String) {
      final errorData = json.decode(response);
      return errorData['message'] ?? 'Unknown error';
    } else if (response.body != null) {
      final errorData = json.decode(response.body);
      return errorData['message'] ?? 'Unknown error';
    }
    return 'Unknown error occurred';
  } catch (e) {
    return 'Error parsing response: $e';
  }
}