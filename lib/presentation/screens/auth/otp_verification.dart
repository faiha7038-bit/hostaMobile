import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:hosta/firebase_msg.dart';
import 'package:hosta/presentation/widgets/bottomnav.dart';
import 'package:hosta/services/api_service.dart';
import 'package:hosta/services/socket-service.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpVerification extends ConsumerStatefulWidget {
  final String phone;
  final String? backendOtp;
  final VoidCallback onResendOtp;
  final ApiService apiService;

  const OtpVerification({
    super.key,
    required this.phone,
    this.backendOtp,
    required this.onResendOtp,
    required this.apiService,
  });

  @override
  ConsumerState<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends ConsumerState<OtpVerification> {
  final TextEditingController otpController = TextEditingController();

  int resendAfter = 30;
  bool isVerifying = false;
  bool isOtpFilled = false;
  String? otpError;

  // Helper to clamp responsive values between safe limits
  double _clamp(double value, double min, double max) =>
      value.clamp(min, max) as double;

  @override
  void initState() {
    super.initState();

    _startResendTimer();

    if (widget.backendOtp != null &&
        widget.backendOtp!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && otpController.text.isEmpty) {
          otpController.text = widget.backendOtp!;

          // Future.delayed(const Duration(milliseconds: 800), () {
          //   if (mounted && !isVerifying) {
          //     _verifyOtp();
          //   }
          // });
        }
      });
    }
  }

  void _startResendTimer() {
    if (resendAfter > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && resendAfter > 0) {
          setState(() => resendAfter--);
          _startResendTimer();
        }
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (isVerifying) return;

    String otp = otpController.text.trim();
    String phone = widget.phone;

    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length == 12 && cleanPhone.startsWith('91')) {
      cleanPhone = cleanPhone.substring(2);
    } else if (cleanPhone.length > 10) {
      cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
    }

    if (otp.length != 6) {
      setState(() {
        otpError = "Please enter a valid 6-digit OTP";
        isVerifying = false;
      });
      return;
    }
    if (cleanPhone.length != 10) {
      setState(() {
        otpError = "Invalid phone number";
        isVerifying = false;
      });
      return;
    }

    setState(() {
      isVerifying = true;
      otpError = null;
    });

    try {
      String? token = await FirebaseMsg().token;

      final response = await widget.apiService.otpUser({
        "phone": cleanPhone,
        "otp": otp,
        "fcmToken": token,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data["success"] == true && response.data["userDetails"] != null) {
          final userDetails = response.data["userDetails"];
          final userId = userDetails["id"]?.toString();          // "115"
          final userPhone = userDetails["phone"]?.toString();
          final donorId = userDetails["donorId"]?.toString();
          final authToken = response.data["token"];

          final prefs = await SharedPreferences.getInstance();

          if (userId != null && userId.isNotEmpty) {
            await prefs.setString('userId', userId);
          }

          if (userPhone != null && userPhone.isNotEmpty) {
            await prefs.setString('userPhone', userPhone);
          }

          if (donorId != null && donorId.isNotEmpty) {
            await prefs.setString('bloodId', donorId);
          }

          if (authToken != null &&
              authToken is String &&
              authToken.isNotEmpty) {
            await prefs.setString('authToken', authToken);

            final socketService = SocketService();
            socketService.connect(authToken);
            if (userId != null && userId.isNotEmpty) {
              socketService.joinUserRoom(userId);
            }
          } else {
            // commented out
          }

          final refreshToken = response.data["refreshToken"];   // Get from backend
          if (refreshToken != null && refreshToken.isNotEmpty) {
            await prefs.setString('refreshToken', refreshToken);
          }

          final savedToken = prefs.getString('authToken');

          if (mounted) {
            setState(() {
              isVerifying = false;
            });
            showTopSnackBar(context, "Login successful!");

            // Navigate to main screen (your bottom navigation)
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const Bottomnav()),
              (route) => false,
            );
            final prefs = await SharedPreferences.getInstance();
            final ambulanceId = prefs.getString('ambulanceId') ?? '';
          }
        } else {
          setState(() {
            otpError = response.data["message"] ?? "Invalid OTP. Please try again.";
            isVerifying = false;
          });
        }
      } else {
        setState(() {
          otpError = response.data["message"] ?? "Verification failed";
          isVerifying = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        otpError =
            e.response?.data["message"] ??
            "Verification failed";
        isVerifying = false;
      });
    }
    // } catch (e) {
    //   log("Error: $e");
    //   setState(() {
    //     otpError = "Something went wrong. Please try again.";
    //     isVerifying = false;
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Clamped responsive values for all UI dimensions
    final double dialogRadius = _clamp(screenWidth * 0.06, 16, 32);
    final double dialogPadding = _clamp(screenWidth * 0.05, 16, 32);
    final double iconContainerSize = _clamp(screenWidth * 0.13, 40, 70);
    final double iconSize = _clamp(screenWidth * 0.07, 22, 36);
    final double titleFontSize = _clamp(screenWidth * 0.048, 16, 24);
    final double subtitleFontSize = _clamp(screenWidth * 0.032, 10, 16);
    final double errorFontSize = _clamp(screenWidth * 0.03, 10, 14);
    final double resendFontSize = _clamp(screenWidth * 0.032, 10, 16);
    final double otpFieldHeight = _clamp(screenHeight * 0.055, 40, 60);
    final double otpFieldRadius = _clamp(screenWidth * 0.025, 6, 14);
    final double pinFieldRadius = _clamp(screenWidth * 0.02, 4, 12);
    final double pinFieldHeight = _clamp(screenHeight * 0.045, 30, 50);
    final double otpFontSize = _clamp(screenWidth * 0.055, 18, 28);
    final double buttonHeight = _clamp(screenHeight * 0.06, 40, 56);
    final double buttonRadius = _clamp(screenWidth * 0.025, 8, 16);
    final double buttonFontSize = _clamp(screenWidth * 0.038, 13, 20);
    final double circularSize = _clamp(screenWidth * 0.055, 18, 30);
    final double errorIconSize = _clamp(screenWidth * 0.035, 12, 18);
    final double verticalSpacingSmall = screenHeight * 0.015;
    final double verticalSpacingMedium = screenHeight * 0.025;
    final double verticalSpacingLarge = screenHeight * 0.035;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dialogRadius),
      ),
      child: SingleChildScrollView(
        child: Container(
          width: screenWidth * 0.9,
          padding: EdgeInsets.all(dialogPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.smartphone_rounded,
                  color: Colors.green,
                  size: iconSize,
                ),
              ),

              SizedBox(height: verticalSpacingSmall),

              // Title
              Text(
                "Enter Verification Code",
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: verticalSpacingSmall * 0.5),

              // Subtitle
              Text(
                "Code sent to ${widget.phone}",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: subtitleFontSize,
                ),
              ),

              SizedBox(height: verticalSpacingMedium),

              // OTP FIELD
              SizedBox(
                height: otpFieldHeight + 16, // to accommodate border & padding
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: otpError != null
                          ? Colors.red
                          : Colors.grey[300]!,
                      width: 1.5,
                    ),
                    borderRadius:
                        BorderRadius.circular(otpFieldRadius),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: LayoutBuilder(
                      builder:
                          (context, constraints) {
                        return PinCodeTextField(
                          appContext: context,
                          length: 6,
                          controller: otpController,
                          keyboardType:
                              TextInputType.number,
                          autoDismissKeyboard: true,
                          enablePinAutofill: true,
                          autoFocus: true,
                          textStyle: TextStyle(
                            fontSize: otpFontSize,
                            fontWeight:
                                FontWeight.bold,
                          ),
                          mainAxisAlignment: MainAxisAlignment.spaceAround,

                          pinTheme: PinTheme(
                            shape:
                                PinCodeFieldShape.box,
                            borderRadius:
                                BorderRadius.circular(
                                    pinFieldRadius),
                            fieldHeight: pinFieldHeight,
                            fieldWidth: (constraints.maxWidth / 6.8).clamp(30, 60),

                            activeFillColor:
                                Colors.white,
                            selectedFillColor:
                                Colors.white,
                            inactiveFillColor:
                                Colors.grey[50],

                            activeColor:
                                otpError != null
                                    ? Colors.red
                                    : Colors.green,

                            selectedColor:
                                otpError != null
                                    ? Colors.red
                                    : Colors.blue,

                            inactiveColor:
                                otpError != null
                                    ? Colors.red
                                    : Colors
                                        .grey[300]!,

                            borderWidth: 1,
                          ),

                          // FIXED: Removed onCompleted
                          // to avoid duplicate API calls

                          onChanged: (value) {
                            if (otpError != null) {
                              setState(() {
                                otpError = null;
                              });
                            }

                            // FIXED: Reset flag
                            if (value.length < 6 &&
                                isOtpFilled) {
                              setState(() {
                                isOtpFilled = false;
                              });
                            }

                            if (value.length == 6 &&
                                !isVerifying &&
                                !isOtpFilled) {
                              setState(() {
                                isOtpFilled = true;
                              });
                              FocusScope.of(context).unfocus();
                              Future.delayed(
                                const Duration(
                                    milliseconds: 500),
                                () {
                                  if (mounted &&
                                      !isVerifying) {
                                    _verifyOtp();
                                  }
                                },
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ERROR
              if (otpError != null)
                Padding(
                  padding:
                      EdgeInsets.only(top: verticalSpacingSmall * 0.5),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: errorIconSize,
                      ),

                      SizedBox(width: 4),

                      Expanded(
                        child: Text(
                          otpError!,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: errorFontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: verticalSpacingMedium),

              // VERIFY BUTTON
              SizedBox(
                width: double.infinity,
                height: buttonHeight,
                child: ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : _verifyOtp,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.green,
                    foregroundColor:
                        Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              buttonRadius),
                    ),
                  ),
                  child: isVerifying
                      ? SizedBox(
                          width: circularSize,
                          height: circularSize,
                          child:
                              const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Verify & Login",
                          style: TextStyle(
                            fontSize: buttonFontSize,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                ),
              ),

              SizedBox(height: verticalSpacingSmall),

              // RESEND
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive code? ",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: resendFontSize,
                    ),
                  ),

                  if (resendAfter > 0)
                    Text(
                      "Resend in ${resendAfter}s",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight:
                            FontWeight.w500,
                        fontSize: resendFontSize,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: isVerifying
                          ? null
                          : () {
                              widget.onResendOtp();
                            },
                      child: Text(
                        "Resend OTP",
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight:
                              FontWeight.w600,
                          fontSize: resendFontSize,
                        ),
                      ),
                    ),
                ],
              ),

              SizedBox(height: verticalSpacingSmall * 0.5),
            ],
          ),
        ),
      ),
    );
  }
}