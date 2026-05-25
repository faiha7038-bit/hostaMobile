import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hosta/firebase_msg.dart';
import 'package:hosta/services/api_service.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordManagerPage extends StatefulWidget {
  const PasswordManagerPage({super.key});

  @override
  State<PasswordManagerPage> createState() => _PasswordManagerPageState();
}

class _PasswordManagerPageState extends State<PasswordManagerPage> {
  bool _showCurrentPassword = true;
  bool _showNewPassword = true;
  bool _showConfirmPassword = true;
  bool _isLoading = false;
  
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final ApiService _apiService = ApiService();

  // Forgot Password controllers
  final TextEditingController _phoneController = TextEditingController();
  String? _phoneError;
  String? _receivedOtp;
  bool _isSendingOtp = false;
  
  // Store the complete phone number without duplication
  String _completePhoneNumber = '';

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Get userId from SharedPreferences
  // Future<String?> _getUserId() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.getString('userId');
  // }
  Future<int?> _getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('userId');
}

  // Validate passwords
  bool _validatePasswords() {
    if (_currentPasswordController.text.isEmpty) {
      _showErrorSnackBar("Please enter current password");
      return false;
    }
    
    if (_newPasswordController.text.isEmpty) {
      _showErrorSnackBar("Please enter new password");
      return false;
    }
    
    if (_newPasswordController.text.length < 6) {
      _showErrorSnackBar("Password must be at least 6 characters");
      return false;
    }
    
    if (_confirmPasswordController.text.isEmpty) {
      _showErrorSnackBar("Please confirm your new password");
      return false;
    }
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar("New passwords do not match");
      return false;
    }
    
    return true;
  }

  void _showErrorSnackBar(String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
        ),
      ),
    );
  }

  // Update password API call
Future<void> _updatePassword() async {
  if (!_validatePasswords()) return;

  setState(() => _isLoading = true);

  try {
    final passwordData = {
      "currentPassword": _currentPasswordController.text.trim(),
      "newPassword": _newPasswordController.text.trim(),
    };

    final response = await _apiService.changePassword(passwordData);

    setState(() => _isLoading = false);

    if (response.statusCode == 200 &&
        response.data["success"] == true) {

      _showSuccessSnackBar("Password updated successfully!");

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      Navigator.pop(context);

    } else {
      _showErrorSnackBar(
        response.data["message"] ?? "Failed to update password",
      );
    }
  } on DioException catch (e) {
    setState(() => _isLoading = false);
    _showErrorSnackBar(
      e.response?.data['message'] ?? "Network error",
    );
  }
}

  // FORGOT PASSWORD FLOW - Phone OTP Verification

  bool _validatePhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (!cleaned.startsWith('+')) {
      setState(() {
        _phoneError = 'Phone number must include country code (e.g., +91)';
      });
      return false;
    }
    
    int digitCount = cleaned.replaceAll('+', '').length;
    
    if (digitCount < 10) {
      setState(() {
        _phoneError = 'Phone number must have at least 10 digits';
      });
      return false;
    } else if (digitCount > 15) {
      setState(() {
        _phoneError = 'Phone number cannot exceed 15 digits';
      });
      return false;
    }
    
    setState(() {
      _phoneError = null;
    });
    return true;
  }

  Future<void> _sendForgotOtp() async {
    if (_completePhoneNumber.isEmpty) {
      setState(() {
        _phoneError = 'Please enter a valid phone number';
      });
      return;
    }

    if (!_validatePhoneNumber(_completePhoneNumber)) {
      return;
    }

    setState(() => _isSendingOtp = true);

    try {
      final response = await _apiService.loginUser({"phone": _completePhoneNumber});

      setState(() => _isSendingOtp = false);

      if (response.statusCode == 200 && response.data["status"] == 200) {
        final backendOtp = response.data["otp"]?.toString();
        if (backendOtp != null && backendOtp.length == 6) {
          setState(() {
            _receivedOtp = backendOtp;
          });
          _showLoadingAndThenOtp(_completePhoneNumber, backendOtp);
        } else {
          _showOtpPopup(_completePhoneNumber, null);
        }
      } else {
        _showOtpPopup(_completePhoneNumber, null);
      }
    } on DioException catch (dioError) {
      setState(() => _isSendingOtp = false);

      String errorMessage = "Something went wrong";

      if (dioError.response != null) {
        try {
          errorMessage = dioError.response?.data['message'] ?? errorMessage;
        } catch (_) {}
      }

      if (errorMessage.toLowerCase().contains('phone') || 
          errorMessage.toLowerCase().contains('number')) {
        setState(() {
          _phoneError = errorMessage;
        });
      } else {
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      setState(() => _isSendingOtp = false);
      _showErrorSnackBar("Failed to send OTP: $e");
    }
  }

  void _showLoadingAndThenOtp(String phone, String backendOtp) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: EdgeInsets.all(screenWidth * 0.05),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.05),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: screenHeight * 0.025),
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, double value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: screenWidth * 0.2,
                          height: screenWidth * 0.2,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: screenWidth * 0.0075,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ),
                        Icon(
                          Icons.mark_email_read_rounded,
                          size: screenWidth * 0.0875,
                          color: Colors.green,
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: screenHeight * 0.03),
                Text(
                  "Sending OTP",
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  "We're sending a 6-digit code to\n$phone",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: screenWidth * 0.035,
                  ),
                ),
                SizedBox(height: screenHeight * 0.025),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.pop(context);
        _showOtpPopup(phone, backendOtp);
      }
    });
  }

  void _showOtpPopup(String phone, String? backendOtp) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final otpController = TextEditingController();
    
    if (backendOtp != null) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && otpController.text.isEmpty) {
          otpController.text = backendOtp;
        }
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        int resendAfter = 30;
        bool isVerifying = false;
        bool isOtpFilled = false;
        String? otpError;

        return StatefulBuilder(
          builder: (context, setState) {
            if (resendAfter > 0) {
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted && resendAfter > 0) {
                  setState(() => resendAfter--);
                }
              });
            }

            if (otpController.text.length == 6 && !isVerifying && !isOtpFilled) {
              isOtpFilled = true;
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted && !isVerifying) {
                  setState(() => isVerifying = true);
                  _verifyForgotOtp(phone, otpController.text, dialogContext, (error) {
                    setState(() {
                      otpError = error;
                      isVerifying = false;
                      isOtpFilled = false;
                    });
                  });
                }
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.06),
              ),
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.06),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.smartphone_rounded,
                        color: Colors.green,
                        size: screenWidth * 0.075,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    
                    Text(
                      "Verify Phone",
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    
                    Text(
                      "Code sent to $phone",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, double opacity, child) {
                        return Opacity(
                          opacity: opacity,
                          child: child,
                        );
                      },
                      child: PinCodeTextField(
                        appContext: context,
                        length: 6,
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        animationType: AnimationType.fade,
                        animationDuration: const Duration(milliseconds: 300),
                        autoDismissKeyboard: true,
                        enablePinAutofill: true,
                        autoFocus: true,
                        textStyle: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          fieldHeight: screenWidth * 0.1375,
                          fieldWidth: screenWidth * 0.1125,
                          activeFillColor: Colors.white,
                          selectedFillColor: Colors.white,
                          inactiveFillColor: Colors.grey[50],
                          activeColor: otpError != null ? Colors.red : Colors.green,
                          selectedColor: otpError != null ? Colors.red : Colors.blue,
                          inactiveColor: otpError != null ? Colors.red : Colors.grey[300]!,
                          borderWidth: screenWidth * 0.005,
                        ),
                        onCompleted: (value) {
                          if (!isVerifying) {
                            setState(() => isVerifying = true);
                            _verifyForgotOtp(phone, value, dialogContext, (error) {
                              setState(() {
                                otpError = error;
                                isVerifying = false;
                              });
                            });
                          }
                        },
                        onChanged: (value) {
                          if (otpError != null) {
                            setState(() {
                              otpError = null;
                            });
                          }
                        },
                      ),
                    ),
                    
                    if (otpError != null)
                      Padding(
                        padding: EdgeInsets.only(top: screenHeight * 0.01),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: screenWidth * 0.035,
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Expanded(
                              child: Text(
                                otpError!,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: screenWidth * 0.03,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: screenHeight * 0.03),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: screenHeight * 0.0625,
                      child: ElevatedButton(
                        onPressed: isVerifying ? null : () {
                          if (otpController.text.length == 6) {
                            setState(() => isVerifying = true);
                            _verifyForgotOtp(phone, otpController.text, dialogContext, (error) {
                              setState(() {
                                otpError = error;
                                isVerifying = false;
                              });
                            });
                          } else {
                            setState(() {
                              otpError = "Please enter a 6-digit verification code";
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          ),
                          elevation: 0,
                        ),
                        child: isVerifying
                            ? SizedBox(
                                width: screenWidth * 0.06,
                                height: screenWidth * 0.06,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: screenWidth * 0.005,
                                ),
                              )
                            : Text(
                                "Verify & Continue",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive code? ",
                          style: TextStyle(color: Colors.grey[600], fontSize: screenWidth * 0.035),
                        ),
                        resendAfter > 0
                            ? TweenAnimationBuilder(
                                tween: Tween<double>(begin: resendAfter.toDouble(), end: 0),
                                duration: Duration(seconds: resendAfter),
                                builder: (context, double value, child) {
                                  return Text(
                                    "Resend in ${value.toInt()}s",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                      fontSize: screenWidth * 0.035,
                                    ),
                                  );
                                },
                              )
                            : GestureDetector(
                                onTap: isVerifying ? null : () async {
                                  Navigator.pop(dialogContext);
                                  await _sendForgotOtp();
                                },
                                child: Text(
                                  "Resend OTP",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _verifyForgotOtp(
    String phone,
    String otp,
    BuildContext dialogContext,
    Function(String) onError,
  ) async {
    if (otp.length != 6) {
      onError("Please enter a valid 6-digit OTP");
      return;
    }

    try {
      String? token = await FirebaseMsg().token;

      final response = await _apiService.otpUser({
        "phone": phone,
        "otp": otp,
        "FcmToken": token,
      });

      if (response.statusCode == 200 && response.data["status"] == 200) {
        if (Navigator.canPop(dialogContext)) {
          Navigator.pop(dialogContext); // Close OTP dialog
        }

        if (mounted) {
          _showResetPasswordDialog(phone);
        }
      } else {
        onError(response.data["message"] ?? "Invalid OTP. Please try again.");
      }
    } on DioException catch (dioError) {
      String errorMessage = "Something went wrong";
      if (dioError.response != null) {
        try {
          errorMessage = dioError.response?.data['message'] ?? errorMessage;
        } catch (_) {}
      }
      onError(errorMessage);
    } catch (e) {
      onError("Invalid OTP. Please try again.");
    }
  }

  void _showResetPasswordDialog(String phone) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isResetting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.05),
          ),
          title: Text(
            "Reset Password",
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter your new password",
                style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.grey),
              ),
              SizedBox(height: screenHeight * 0.02),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "New password (min. 6 characters)",
                  hintStyle: TextStyle(fontSize: screenWidth * 0.035),
                  prefixIcon: Icon(Icons.lock_outline, size: screenWidth * 0.05, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.01875),
                ),
              ),
              SizedBox(height: screenHeight * 0.015),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Confirm new password",
                  hintStyle: TextStyle(fontSize: screenWidth * 0.035),
                  prefixIcon: Icon(Icons.lock_outline, size: screenWidth * 0.05, color: Colors.green),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.01875),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isResetting ? null : () => Navigator.pop(dialogContext),
              child: Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.04)),
            ),
            ElevatedButton(
              onPressed: isResetting ? null : () async {
                if (newPasswordController.text.isEmpty) {
                  _showErrorSnackBar("Please enter new password");
                  return;
                }
                if (newPasswordController.text.length < 6) {
                  _showErrorSnackBar("Password must be at least 6 characters");
                  return;
                }
                if (confirmPasswordController.text.isEmpty) {
                  _showErrorSnackBar("Please confirm your password");
                  return;
                }
                if (newPasswordController.text != confirmPasswordController.text) {
                  _showErrorSnackBar("Passwords do not match");
                  return;
                }

                // setState(() => isResetting = true);
                
                // // Call your reset password API here
                // await Future.delayed(const Duration(seconds: 1));
                
                // setState(() => isResetting = false);
                // Navigator.pop(dialogContext); // Close reset dialog
                setState(() => isResetting = true);

try {
  final response = await _apiService.resetForgotPassword({
    "phone": phone,
    "newPassword": newPasswordController.text.trim(),
  });

  setState(() => isResetting = false);

  if (response.statusCode == 200 &&
      response.data["success"] == true) {

    Navigator.pop(dialogContext);

    if (mounted) {
      _showSuccessSnackBar(
        "Password reset successfully! Please login again.",
      );

      Navigator.pop(context);
    }
  } else {
    _showErrorSnackBar(
      response.data["message"] ?? "Failed to reset password",
    );
  }
} on DioException catch (e) {
  setState(() => isResetting = false);

  _showErrorSnackBar(
    e.response?.data["message"] ?? "Something went wrong",
  );
}
                
                if (mounted) {
                  _showSuccessSnackBar("Password reset successfully! Please login with new password.");
                  Navigator.pop(context); // Close forgot password dialog
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
              ),
              child: isResetting
                  ? SizedBox(
                      width: screenWidth * 0.05,
                      height: screenWidth * 0.05,
                      child: CircularProgressIndicator(
                        strokeWidth: screenWidth * 0.005,
                        color: Colors.white,
                      ),
                    )
                  : Text("Reset Password", style: TextStyle(fontSize: screenWidth * 0.04)),
            ),
          ],
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    _phoneController.clear();
    _phoneError = null;
    _completePhoneNumber = '';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.05),
          ),
          title: Text(
            "Forgot Password",
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Enter your phone number to receive OTP",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: screenWidth * 0.035, color: Colors.grey),
              ),
              SizedBox(height: screenHeight * 0.02),
              IntlPhoneField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: TextStyle(
                    color: _phoneError != null ? Colors.red : Colors.grey[600],
                    fontSize: screenWidth * 0.035,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: BorderSide(
                      color: _phoneError != null ? Colors.red : Colors.grey[300]!,
                      width: _phoneError != null ? 1.5 : 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: BorderSide(
                      color: _phoneError != null ? Colors.red : Colors.grey[300]!,
                      width: _phoneError != null ? 1.5 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: BorderSide(
                      color: _phoneError != null ? Colors.red : Colors.green,
                      width: screenWidth * 0.005,
                    ),
                  ),
                  errorText: _phoneError,
                  errorStyle: TextStyle(fontSize: screenWidth * 0.03),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                initialCountryCode: 'IN',
                onChanged: (phone) {
                  // Store the complete number in a separate variable
                  // Don't set it to controller text as that causes duplication
                  _completePhoneNumber = phone.completeNumber;
                  if (_phoneError != null) {
                    setState(() {
                      _phoneError = null;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isSendingOtp ? null : () => Navigator.pop(dialogContext),
              child: Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.04)),
            ),
            ElevatedButton(
              onPressed: _isSendingOtp ? null : () async {
                // Use _completePhoneNumber which doesn't have duplication
                if (_completePhoneNumber.isEmpty) {
                  setState(() {
                    _phoneError = 'Please enter a valid phone number';
                  });
                  return;
                }
                await _sendForgotOtp();
                if (_phoneError == null && mounted) {
                  Navigator.pop(dialogContext); // Close phone dialog
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
              ),
              child: _isSendingOtp
                  ? SizedBox(
                      width: screenWidth * 0.05,
                      height: screenWidth * 0.05,
                      child: CircularProgressIndicator(
                        strokeWidth: screenWidth * 0.005,
                        color: Colors.white,
                      ),
                    )
                  : Text("Send OTP", style: TextStyle(fontSize: screenWidth * 0.04)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: screenWidth * 0.04,
            color: isMet ? Colors.green : Colors.grey,
          ),
          SizedBox(width: screenWidth * 0.02),
          Text(
            text,
            style: TextStyle(
              fontSize: screenWidth * 0.0325,
              color: isMet ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: screenWidth * 0.05,
          ),
        ),
        title: Text(
          "Password Manager",
          style: TextStyle(
            color: Colors.white,
            fontSize: screenWidth * 0.05,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Forgot Password link
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: screenHeight * 0.025),
        
              // Current Password
              Text(
                "Current Password",
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextField(
                controller: _currentPasswordController,
                obscureText: _showCurrentPassword,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: "Enter current password",
                  hintStyle: TextStyle(fontSize: screenWidth * 0.035),
                  prefixIcon: Icon(Icons.lock_outline_rounded, size: screenWidth * 0.05, color: Colors.green),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showCurrentPassword ? Icons.visibility_off : Icons.visibility,
                      size: screenWidth * 0.05,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      setState(() {
                        _showCurrentPassword = !_showCurrentPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.01875),
                ),
              ),
        
              SizedBox(height: screenHeight * 0.025),
        
              // New Password
              Text(
                "New Password",
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextField(
                controller: _newPasswordController,
                obscureText: _showNewPassword,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: "Enter new password (min. 6 characters)",
                  hintStyle: TextStyle(fontSize: screenWidth * 0.035),
                  prefixIcon: Icon(Icons.lock_outline_rounded, size: screenWidth * 0.05, color: Colors.green),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showNewPassword ? Icons.visibility_off : Icons.visibility,
                      size: screenWidth * 0.05,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      setState(() {
                        _showNewPassword = !_showNewPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.01875),
                ),
              ),
        
              SizedBox(height: screenHeight * 0.025),
        
              // Confirm Password
              Text(
                "Confirm Password",
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _showConfirmPassword,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  hintText: "Confirm new password",
                  hintStyle: TextStyle(fontSize: screenWidth * 0.035),
                  prefixIcon: Icon(Icons.lock_outline_rounded, size: screenWidth * 0.05, color: Colors.green),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      size: screenWidth * 0.05,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.01875),
                ),
              ),
        
              SizedBox(height: screenHeight * 0.0375),
        
              // Update Password Button
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.06875,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    elevation: 2,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: screenWidth * 0.06,
                          height: screenWidth * 0.06,
                          child: CircularProgressIndicator(
                            strokeWidth: screenWidth * 0.005,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          "Update Password",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
        
              SizedBox(height: screenHeight * 0.02),
        
              // Password requirements
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  border: Border.all(color: Colors.grey[200]!, width: screenWidth * 0.0025),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Password Requirements:",
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    _buildRequirement(
                      "Minimum 6 characters",
                      _newPasswordController.text.length >= 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}