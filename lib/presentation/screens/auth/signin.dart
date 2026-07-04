import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:hosta/presentation/screens/auth/otp_verification.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../../services/api_service.dart';
import 'signup.dart';

class Signin extends StatefulWidget {
  const Signin({super.key});

  @override
  State<Signin> createState() => _SigninState();
}

class _SigninState extends State<Signin> {
  final TextEditingController phoneController = TextEditingController();
  final ApiService _apiService = ApiService();

  // Helper to clamp responsive values between safe limits
  double _clamp(double value, double min, double max) =>
      value.clamp(min, max) as double;

  @override
  void initState() {
    super.initState();
    _apiService.init();
  }

  bool isSendingOtp = false;
  String? phoneError;

  // Clean phone number to 10 digits only
  String _cleanPhoneNumber(String phone) {
    // Remove all non-digit characters
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Remove +91 or 91 prefix if present
    if (cleaned.startsWith('91') && cleaned.length > 10) {
      cleaned = cleaned.substring(2);
    }

    // Ensure we only have the last 10 digits
    if (cleaned.length > 10) {
      cleaned = cleaned.substring(cleaned.length - 10);
    }

    return cleaned;
  }

  bool _validatePhoneNumber(String phone) {
    String cleaned = _cleanPhoneNumber(phone);

    if (cleaned.isEmpty) {
      setState(() {
        phoneError = 'Please enter a phone number';
      });
      return false;
    }

    if (cleaned.length != 10) {
      setState(() {
        phoneError = 'Please enter a valid 10-digit mobile number';
      });
      return false;
    }

    setState(() {
      phoneError = null;
    });
    return true;
  }

  Future<void> _sendOtp() async {
    String rawPhone = phoneController.text.trim();
    String cleanPhone = _cleanPhoneNumber(rawPhone);

    // Validate phone number
    if (!_validatePhoneNumber(cleanPhone)) {
      return;
    }

    setState(() {
      isSendingOtp = true;
      phoneError = null;
    });

    try {
      final requestData = {
        "phone": cleanPhone,
      };

      final response = await _apiService.loginUser(requestData);

      setState(() {
        isSendingOtp = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data["success"] == true) {
          final backendOtp = response.data["otp"]?.toString();

          // ✅ OPEN OTP SCREEN WITH OTP
          _showOtpPopup(
            cleanPhone,
            backendOtp,
          );
        } else {
          // _showErrorDialog(
          //   response.data["message"] ??
          //       "Login failed",
          // );
        }
      } else {
        _showErrorDialog(
          response.data["message"] ?? "Failed to send OTP",
        );
      }
    } on DioException catch (dioError) {
      setState(() {
        isSendingOtp = false;
      });

      String errorMessage = "Something went wrong";

      if (dioError.response != null) {
        try {
          errorMessage = dioError.response?.data['message'] ??
              dioError.response?.data['error'] ??
              errorMessage;
        } catch (_) {}
      } else if (dioError.type == DioExceptionType.connectionTimeout) {
        errorMessage = "Connection timeout. Please check your internet.";
      } else if (dioError.type == DioExceptionType.receiveTimeout) {
        // handled
      } else if (dioError.type == DioExceptionType.connectionError) {
        errorMessage = "No internet connection. Please check your network.";
      } else if (dioError.type == DioExceptionType.cancel) {
        errorMessage = "Request cancelled.";
      }

      _showErrorDialog(errorMessage);
    } catch (e) {
      setState(() {
        isSendingOtp = false;
      });

      _showErrorDialog(
        "Failed to send OTP: $e",
      );
    }
  }

  void _showErrorDialog(String message) {
    if (message.toLowerCase().contains("too many")) {
      showTopSnackBar(
        context,
        "Too many login attempts. Please try again after 15 minutes.",
        isError: true,
      );
      return;
    }

    if (message.toLowerCase().contains('phone') ||
        message.toLowerCase().contains('number') ||
        message.toLowerCase().contains('invalid')) {
      setState(() {
        phoneError = message;
      });
    }
  }

  void _showUserNotFoundDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Account Not Found"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Signup()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text("Sign Up"),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingAndThenOtp(String phone, String backendOtp) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive values for the loading dialog
    final double dialogPadding = _clamp(screenWidth * 0.05, 16, 32);
    final double progressSize = _clamp(screenWidth * 0.12, 60, 100);
    final double iconSize = _clamp(screenWidth * 0.08, 30, 50);
    final double titleSize = _clamp(screenWidth * 0.045, 16, 24);
    final double subtitleSize = _clamp(screenWidth * 0.035, 12, 18);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: EdgeInsets.all(dialogPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(_clamp(screenWidth * 0.05, 12, 24)),
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
                          width: progressSize,
                          height: progressSize,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: _clamp(screenWidth * 0.008, 2, 4),
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.mark_email_read_rounded,
                          size: iconSize,
                          color: Colors.green,
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: _clamp(screenHeight * 0.025, 16, 32)),
                Text(
                  "Sending OTP",
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: _clamp(screenHeight * 0.01, 6, 12)),
                Text(
                  "We're sending a 6-digit code to\n+91$phone",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: subtitleSize,
                  ),
                ),
                SizedBox(height: _clamp(screenHeight * 0.025, 16, 32)),
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

    // Responsive inset padding for the dialog
    final double horizontalInset = _clamp(screenWidth * 0.05, 16, 48);
    final double verticalInset = _clamp(screenHeight * 0.05, 20, 64);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: horizontalInset,
            vertical: verticalInset,
          ),
          child: OtpVerification(
            phone: "+91$phone", // Keep +91 for display only
            backendOtp: backendOtp,
            apiService: _apiService,
            onResendOtp: () {
              Navigator.pop(dialogContext);
              _sendOtp();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive clamped values
    final double horizontalPadding = _clamp(screenWidth * 0.06, 16, 48);
    final double verticalPadding = _clamp(screenHeight * 0.04, 16, 48);
    final double maxContentWidth =
        screenWidth > 600 ? _clamp(screenWidth * 0.6, 400, 600) : screenWidth;
    final double iconContainerSize = _clamp(screenWidth * 0.18, 60, 120);
    final double iconSize = _clamp(screenWidth * 0.09, 30, 56);
    final double welcomeFontSize = _clamp(screenWidth * 0.07, 22, 40);
    final double subtitleFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double labelFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double buttonFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double buttonHeight = _clamp(screenHeight * 0.06, 48, 64);
    final double spacing1 = _clamp(screenHeight * 0.02, 12, 28);
    final double spacing2 = _clamp(screenHeight * 0.035, 20, 48);
    final double fieldPaddingH = _clamp(screenWidth * 0.04, 12, 24);
    final double fieldPaddingV = _clamp(screenHeight * 0.015, 10, 18);
    final double radius = _clamp(screenWidth * 0.04, 12, 24);
    final double errorFontSize = _clamp(screenWidth * 0.03, 10, 14);
    final double linkFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double circularSize = _clamp(screenWidth * 0.06, 20, 30);

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
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxContentWidth,
              ),
              child: Column(
                children: [
                  SizedBox(height: _clamp(screenHeight * 0.02, 10, 30)),
                  Container(
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_android_rounded,
                      color: Colors.green,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(height: spacing1),
                  Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: welcomeFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: _clamp(screenHeight * 0.01, 4, 12)),
                  Text(
                    "Login with your phone number",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: subtitleFontSize,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: spacing2),
                  IntlPhoneField(
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(
                        color:
                            phoneError != null ? Colors.red : Colors.grey[600],
                        fontSize: labelFontSize,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(radius),
                        borderSide: BorderSide(
                          color: phoneError != null
                              ? Colors.red
                              : Colors.grey[300]!,
                          width: phoneError != null ? 1.5 : 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(radius),
                        borderSide: BorderSide(
                          color: phoneError != null
                              ? Colors.red
                              : Colors.grey[300]!,
                          width: phoneError != null ? 1.5 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(radius),
                        borderSide: BorderSide(
                          color: phoneError != null ? Colors.red : Colors.green,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(radius),
                        borderSide: const BorderSide(
                          color: Colors.red,
                          width: 1.5,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(radius),
                        borderSide:
                            const BorderSide(color: Colors.red, width: 2),
                      ),
                      errorText: phoneError,
                      errorStyle: TextStyle(
                        color: Colors.red,
                        fontSize: errorFontSize,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: fieldPaddingH,
                        vertical: fieldPaddingV,
                      ),
                    ),
                    initialCountryCode: 'IN',
                    onChanged: (phone) {
                      phoneController.text = phone.completeNumber;
                      if (phoneError != null) {
                        setState(() {
                          phoneError = null;
                        });
                      }
                    },
                  ),
                  SizedBox(height: spacing2),
                  Container(
                    width: double.infinity,
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: const LinearGradient(
                        colors: [Colors.green, Color(0xFF43A047)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: _clamp(screenWidth * 0.025, 8, 16),
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
                          borderRadius: BorderRadius.circular(radius),
                        ),
                      ),
                      child: isSendingOtp
                          ? SizedBox(
                              width: circularSize,
                              height: circularSize,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Send OTP",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: _clamp(screenHeight * 0.025, 16, 32)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: linkFontSize,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Signup()),
                          );
                        },
                        child: Text(
                          "Register here",
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            fontSize: linkFontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
