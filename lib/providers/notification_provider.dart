import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  int _count = 0;
  String? _userId;
  
  int get count => _count;
  String? get userId => _userId;
  
  void updateCount(int count) {
    if (_count != count) {
      _count = count;
      notifyListeners();
      print('📊 NotificationProvider: Count updated to: $count');
    }
  }
  
  void setUserId(String userId) {
    _userId = userId;
  }
  
  void loadCountFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCount = prefs.getInt('notification_count') ?? 0;
      _count = savedCount;
      notifyListeners();
      print('📊 NotificationProvider: Loaded count: $savedCount');
    } catch (e) {
      print('❌ Error loading count: $e');
    }
  }
  
  void resetCount() {
    _count = 0;
    notifyListeners();
    print('📊 NotificationProvider: Count reset to 0');
  }
}