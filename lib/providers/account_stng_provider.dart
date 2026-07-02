import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

// ─────────────────────────────────────────────
//  STATE CLASS
// ─────────────────────────────────────────────

class AccountState {
  final bool isDeleting;
  final String? errorMessage;
  final bool isSuccess;

  AccountState({
    this.isDeleting = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  AccountState copyWith({
    bool? isDeleting,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return AccountState(
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

// ─────────────────────────────────────────────
//  PROVIDER
// ─────────────────────────────────────────────

final accountStateProvider = StateNotifierProvider<AccountNotifier, AccountState>((ref) {
  return AccountNotifier();
});

class AccountNotifier extends StateNotifier<AccountState> {
  final ApiService _apiService = ApiService();

  AccountNotifier() : super(AccountState());

  void setDeleting(bool deleting) {
    state = state.copyWith(isDeleting: deleting);
  }

  void setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }

  void setSuccess(bool success) {
    state = state.copyWith(isSuccess: success);
  }

  void reset() {
    state = AccountState();
  }

  Future<bool> deleteAccount(BuildContext context) async {
    state = state.copyWith(isDeleting: true, errorMessage: null);

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('userId');

      if (storedUserId != null) {
        // Call API to delete user
        await _apiService.deleteAUser(storedUserId);
        
        // Clear all stored data
        await prefs.clear();
        
        state = state.copyWith(isDeleting: false, isSuccess: true);
        return true;
      } else {
        throw Exception("User ID not found");
      }
    } catch (error) {
      state = state.copyWith(
        isDeleting: false,
        errorMessage: error.toString(),
      ); 
      return false;
    }
  }
}









