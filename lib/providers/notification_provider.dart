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
     
    } catch (e) {
    
    }
  }
  
  void resetCount() {
    _count = 0;
    notifyListeners();
  
  }
}