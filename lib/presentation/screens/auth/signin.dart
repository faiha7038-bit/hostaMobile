import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:hosta/firebase_msg.dart';
import 'package:hosta/presentation/widgets/bottomnav.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'signup.dart';
import '../../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_autofill/sms_autofill.dart';

class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final TextEditingController phoneController = TextEditingController();
  final ApiService _apiService = ApiService();

  bool isSendingOtp = false;
  String? receivedOtp;
  String? phoneError; // For inline error message

  // Validate phone number
  bool _validatePhoneNumber(String phone) {
    // Remove all non-digit characters except +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Check if it starts with + and has 10-15 digits (international format)
    if (!cleaned.startsWith('+')) {
      setState(() {
        phoneError = 'Phone number must include country code (e.g., +91)';
      });
      return false;
    }
    
    // Count digits only (excluding +)
    int digitCount = cleaned.replaceAll('+', '').length;
    
    if (digitCount < 10) {
      setState(() {
        phoneError = 'Phone number must have at least 10 digits';
      });
      return false;
    } else if (digitCount > 15) {
      setState(() {
        phoneError = 'Phone number cannot exceed 15 digits';
      });
      return false;
    }
    
    setState(() {
      phoneError = null; // Clear error if valid
    });
    return true;
  }

  // SEND OTP
  Future<void> _sendOtp() async {
    String phone = phoneController.text.trim();

    // Validate phone number first
    if (!_validatePhoneNumber(phone)) {
      return;
    }

    try {
      setState(() => isSendingOtp = true);

      final response = await _apiService.loginUser({"phone": phone});

      setState(() => isSendingOtp = false);

      if (response.statusCode == 200 && response.data["status"] == 200) {
        final backendOtp = response.data["otp"]?.toString();
        if (backendOtp != null && backendOtp.length == 6) {
          setState(() {
            receivedOtp = backendOtp;
          });
          _showLoadingAndThenOtp(phone, backendOtp);
        } else {
          _showOtpPopup(phone, null);
        }
      } else {
        _showOtpPopup(phone, null);
      }
    } on DioException catch (dioError) {
      setState(() => isSendingOtp = false);

      String errorMessage = "Something went wrong";

      if (dioError.response != null) {
        try {
          errorMessage = dioError.response?.data['message'] ?? errorMessage;
        } catch (_) {}
      }

      // Show error in input field if it's a validation error from server
      if (errorMessage.toLowerCase().contains('phone') || 
          errorMessage.toLowerCase().contains('number')) {
        setState(() {
          phoneError = errorMessage;
        });
      } else {
        showTopSnackBar(context, errorMessage, isError: true);
      }
    } catch (e) {
      setState(() => isSendingOtp = false);
      showTopSnackBar(context, "Failed to send OTP: $e", isError: true);
    }
  }

  void _showLoadingAndThenOtp(String phone, String backendOtp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, double value, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 3,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ),
                        const Icon(
                          Icons.mark_email_read_rounded,
                          size: 35,
                          color: Colors.green,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  "Sending OTP",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We're sending a 6-digit code to\n${phoneController.text}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
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
    final otpController = TextEditingController();
    
    if (backendOtp != null) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && otpController.text.isEmpty) {
          otpController.text = backendOtp;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && otpController.text.length == 6) {
              // Will be handled by dialog's StatefulBuilder
            }
          });
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
                  _verifyOtp(phone, otpController.text, otpController, dialogContext, (error) {
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
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smartphone_rounded,
                        color: Colors.green,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text(
                      "Enter Verification Code",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Text(
                      "Code sent to ${phoneController.text}",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),

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
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          borderRadius: BorderRadius.circular(12),
                          fieldHeight: 55,
                          fieldWidth: 45,
                          activeFillColor: Colors.white,
                          selectedFillColor: Colors.white,
                          inactiveFillColor: Colors.grey[50],
                          activeColor: otpError != null ? Colors.red : Colors.green,
                          selectedColor: otpError != null ? Colors.red : Colors.blue,
                          inactiveColor: otpError != null ? Colors.red : Colors.grey[300]!,
                          borderWidth: 2,
                        ),
                        onCompleted: (value) {
                          if (!isVerifying) {
                            setState(() => isVerifying = true);
                            _verifyOtp(phone, value, otpController, dialogContext, (error) {
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
                    
                    // Show OTP error below the field without increasing height
                    if (otpError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                otpError!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isVerifying ? null : () {
                          if (otpController.text.length == 6) {
                            setState(() => isVerifying = true);
                            _verifyOtp(phone, otpController.text, otpController, dialogContext, (error) {
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
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: isVerifying
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Verify & Login",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive code? ",
                          style: TextStyle(color: Colors.grey[600]),
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
                                    ),
                                  );
                                },
                              )
                            : GestureDetector(
                                onTap: isVerifying ? null : () async {
                                  Navigator.pop(dialogContext);
                                  await _sendOtp();
                                },
                                child: const Text(
                                  "Resend OTP",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
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

  // Updated verify method with error callback
  Future<void> _verifyOtp(
    String phone,
    String otp,
    TextEditingController otpController,
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
        final userId = response.data["userDetails"]["_id"];
        final userPhone = response.data["userDetails"]["phone"];
        final donorId = response.data["userDetails"]["donorId"];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
        await prefs.setString('userPhone', userPhone);

        if (donorId != null && donorId.toString().isNotEmpty) {
          await prefs.setString('bloodId', donorId.toString());
        }

        if (Navigator.canPop(dialogContext)) {
          Navigator.pop(dialogContext);
        }

        if (mounted) {
          showTopSnackBar(context, "Login successful!");
        }

        // if (mounted) {
        //   Navigator.pushAndRemoveUntil(
        //     context,
        //     MaterialPageRoute(builder: (context) => const Bottomnav()),
        //     (route) => false,
        //   );
        // }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFECFDF5),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Login with your phone number",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),

                // Phone field with errorText (doesn't increase height)
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(
                      color: phoneError != null ? Colors.red : Colors.grey[600],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: phoneError != null ? Colors.red : Colors.grey[300]!,
                        width: phoneError != null ? 1.5 : 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: phoneError != null ? Colors.red : Colors.grey[300]!,
                        width: phoneError != null ? 1.5 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: phoneError != null ? Colors.red : Colors.green,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                    errorText: phoneError, // This shows error without increasing height
                    errorStyle: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  initialCountryCode: 'IN',
                  onChanged: (phone) {
                    phoneController.text = phone.completeNumber;
                    // Clear error when user starts typing
                    if (phoneError != null) {
                      setState(() {
                        phoneError = null;
                      });
                    }
                  },
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Colors.green, Color(0xFF43A047)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isSendingOtp ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSendingOtp
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Send OTP",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Signup()),
                        );
                      },
                      child: const Text(
                        "Register here",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}