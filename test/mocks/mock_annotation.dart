// test/mocks/mock_annotations.dart
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Add ALL classes you want to mock here
@GenerateMocks([
  http.Client,           // This generates MockHttpClient
  SharedPreferences,     // This generates MockSharedPreferences  
  IO.Socket,            // This generates MockSocket
  FlutterLocalNotificationsPlugin, // This generates MockFlutterLocalNotificationsPlugin
])
void main() {}