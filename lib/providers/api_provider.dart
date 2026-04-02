import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Provide one instance of ApiService
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
