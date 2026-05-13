// import 'dart:developer';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:hosta/common/top_snackbar.dart';
// import 'package:hosta/firebase_msg.dart';
// import 'package:hosta/presentation/widgets/bottomnav.dart';
// import 'package:hosta/services/api_service.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class OtpVerification extends StatefulWidget {
//   final String phone;
//   final String? backendOtp;
//   final VoidCallback onResendOtp;
//   final ApiService apiService;

//   const OtpVerification({
//     super.key,
//     required this.phone,
//     this.backendOtp,
//     required this.onResendOtp,
//     required this.apiService,
//   });

//   @override
//   State<OtpVerification> createState() => _OtpVerificationState();
// }

// class _OtpVerificationState extends State<OtpVerification> {
//   final TextEditingController otpController = TextEditingController();
//   int resendAfter = 30;
//   bool isVerifying = false;
//   bool isOtpFilled = false;
//   String? otpError;

//   @override
//   void initState() {
//     super.initState();
//     if (widget.backendOtp != null) {
//       Future.delayed(const Duration(milliseconds: 1500), () {
//         if (mounted && otpController.text.isEmpty) {
//           otpController.text = widget.backendOtp!;
//           Future.delayed(const Duration(milliseconds: 500), () {
//             if (mounted && otpController.text.length == 6) {
//               // Will be handled by the UI
//             }
//           });
//         }
//       });
//     }
//   }

//   void _startResendTimer() {
//     if (resendAfter > 0) {
//       Future.delayed(const Duration(seconds: 1), () {
//         if (mounted && resendAfter > 0) {
//           setState(() => resendAfter--);
//           _startResendTimer();
//         }
//       });
//     }
//   }

//   Future<void> _verifyOtp() async {
//     String otp = otpController.text;
    
//     if (otp.length != 6) {
//       setState(() {
//         otpError = "Please enter a valid 6-digit OTP";
//       });
//       return;
//     }

//     setState(() {
//       isVerifying = true;
//       otpError = null;
//     });

//     try {
//       String? token = await FirebaseMsg().token;

//       final response = await widget.apiService.otpUser({
//         "phone": widget.phone,
//         "otp": otp,
//         "FcmToken": token,
//       });

//       if (response.statusCode == 200 && response.data["status"] == 200) {
//         final userId = response.data["userDetails"]["_id"];
//         final userPhone = response.data["userDetails"]["phone"];
//         final donorId = response.data["userDetails"]["donorId"];

//         final prefs = await SharedPreferences.getInstance();
//         await prefs.setString('userId', userId);
//         await prefs.setString('userPhone', userPhone);

//         if (donorId != null && donorId.toString().isNotEmpty) {
//           await prefs.setString('bloodId', donorId.toString());
//         }

//         if (mounted) {
//           showTopSnackBar(context, "Login successful!");
//           Navigator.pushAndRemoveUntil(
//             context,
//             MaterialPageRoute(builder: (context) => const Bottomnav()),
//             (route) => false,
//           );
//         }
//       } else {
//         setState(() {
//           otpError = response.data["message"] ?? "Invalid OTP. Please try again.";
//           isVerifying = false;
//         });
//       }
//     } on DioException catch (dioError) {
//       String errorMessage = "Something went wrong";
//       if (dioError.response != null) {
//         try {
//           errorMessage = dioError.response?.data['message'] ?? errorMessage;
//         } catch (_) {}
//       }
//       setState(() {
//         otpError = errorMessage;
//         isVerifying = false;
//       });
//     } catch (e) {
//       setState(() {
//         otpError = "Invalid OTP. Please try again.";
//         isVerifying = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     _startResendTimer();
    
//     double screenWidth = MediaQuery.of(context).size.width;
    
//     return Dialog(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(24),
//       ),
//       child: Container(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 60,
//               height: 60,
//               decoration: BoxDecoration(
//                 color: Colors.green.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.smartphone_rounded,
//                 color: Colors.green,
//                 size: 30,
//               ),
//             ),
//             const SizedBox(height: 16),

//             const Text(
//               "Enter Verification Code",
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),

//             Text(
//               "Code sent to ${widget.phone}",
//               style: TextStyle(color: Colors.grey[600], fontSize: 14),
//             ),
//             const SizedBox(height: 24),

//             TweenAnimationBuilder(
//               tween: Tween<double>(begin: 0, end: 1),
//               duration: const Duration(milliseconds: 500),
//               curve: Curves.easeOut,
//               builder: (context, double opacity, child) {
//                 return Opacity(opacity: opacity, child: child);
//               },
//               child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   double fieldWidth = (constraints.maxWidth - 40) / 6;

//                   return PinCodeTextField(
//                     appContext: context,
//                     length: 6,
//                     controller: otpController,
//                     keyboardType: TextInputType.number,
//                     animationType: AnimationType.fade,
//                     animationDuration: const Duration(
//                       milliseconds: 300,
//                     ),
//                     autoDismissKeyboard: true,
//                     enablePinAutofill: true,
//                     autoFocus: true,
//                     textStyle: const TextStyle(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     pinTheme: PinTheme(
//                       shape: PinCodeFieldShape.box,
//                       borderRadius: BorderRadius.circular(12),
//                       fieldHeight: 55,
//                       fieldWidth: fieldWidth.clamp(35, 50),
//                       activeFillColor: Colors.white,
//                       selectedFillColor: Colors.white,
//                       inactiveFillColor: Colors.grey[50],
//                       activeColor: otpError != null ? Colors.red : Colors.green,
//                       selectedColor: otpError != null ? Colors.red : Colors.blue,
//                       inactiveColor: otpError != null ? Colors.red : Colors.grey[300]!,
//                       borderWidth: 2,
//                     ),
//                     onCompleted: (value) {
//                       if (!isVerifying) {
//                         _verifyOtp();
//                       }
//                     },
//                     onChanged: (value) {
//                       if (otpError != null) {
//                         setState(() {
//                           otpError = null;
//                         });
//                       }
//                       if (value.length == 6 && !isVerifying && !isOtpFilled) {
//                         setState(() => isOtpFilled = true);
//                         Future.delayed(const Duration(milliseconds: 800), () {
//                           if (mounted && !isVerifying) {
//                             _verifyOtp();
//                           }
//                         });
//                       }
//                     },
//                   );
//                 },
//               ),
//             ),

//             if (otpError != null)
//               Padding(
//                 padding: const EdgeInsets.only(top: 8),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.error_outline,
//                       color: Colors.red,
//                       size: 14,
//                     ),
//                     const SizedBox(width: 4),
//                     Expanded(
//                       child: Text(
//                         otpError!,
//                         style: const TextStyle(
//                           color: Colors.red,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//             const SizedBox(height: 24),

//             AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 onPressed: isVerifying ? null : _verifyOtp,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 0,
//                 ),
//                 child: isVerifying
//                     ? const SizedBox(
//                         width: 24,
//                         height: 24,
//                         child: CircularProgressIndicator(
//                           color: Colors.white,
//                           strokeWidth: 2,
//                         ),
//                       )
//                     : const Text(
//                         "Verify & Login",
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//               ),
//             ),

//             const SizedBox(height: 16),

//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   "Didn't receive code? ",
//                   style: TextStyle(color: Colors.grey[600]),
//                 ),
//                 resendAfter > 0
//                     ? TweenAnimationBuilder(
//                         tween: Tween<double>(
//                           begin: resendAfter.toDouble(),
//                           end: 0,
//                         ),
//                         duration: Duration(seconds: resendAfter),
//                         builder: (context, double value, child) {
//                           return Text(
//                             "Resend in ${value.toInt()}s",
//                             style: TextStyle(
//                               color: Colors.grey[500],
//                               fontWeight: FontWeight.w500,
//                             ),
//                           );
//                         },
//                       )
//                     : GestureDetector(
//                         onTap: isVerifying
//                             ? null
//                             : () {
//                                 Navigator.pop(context);
//                                 widget.onResendOtp();
//                               },
//                         child: const Text(
//                           "Resend OTP",
//                           style: TextStyle(
//                             color: Colors.green,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:hosta/firebase_msg.dart';
import 'package:hosta/presentation/widgets/bottomnav.dart';
import 'package:hosta/services/api_service.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpVerification extends StatefulWidget {
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
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final TextEditingController otpController = TextEditingController();
  int resendAfter = 30;
  bool isVerifying = false;
  bool isOtpFilled = false;
  String? otpError;

  @override
  void initState() {
    super.initState();
    if (widget.backendOtp != null) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && otpController.text.isEmpty) {
          otpController.text = widget.backendOtp!;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && otpController.text.length == 6) {
              // Will be handled by the UI
            }
          });
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

  // Future<void> _verifyOtp() async {
  //   String otp = otpController.text;
  //   String rawPhone = widget.phone;
    
  //    // ✅ Clean phone number again if needed
  // String Phone = rawPhone
  //     .replaceAll('+', '')
  //     .replaceAll(' ', '')
  //     .replaceAll('-', '');
       
  // if (Phone.startsWith('91') && cleanPhone.length == 12) {
  //   Phone = phone.substring(2);
  // }
  
  //   if (otp.length != 6) {
  //     setState(() {
  //       otpError = "Please enter a valid 6-digit OTP";
  //     });
  //     return;
  //   }

  //   setState(() {
  //     isVerifying = true;
  //     otpError = null;
  //   });

  //   try {
  //     String? token = await FirebaseMsg().token;

  //     final response = await widget.apiService.otpUser({
  //      //"phone": widget.phone, 
  //       "phone": cleanPhone,
  //       "otp": otp,
  //       "FcmToken": token,
  //     });

  //     if (response.statusCode == 200 && response.data["status"] == 200) {
  //       final userId = response.data["userDetails"]["_id"];
  //       final userPhone = response.data["userDetails"]["phone"];
  //       final donorId = response.data["userDetails"]["donorId"];

  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString('userId', userId);
  //       await prefs.setString('userPhone', userPhone);

  //       if (donorId != null && donorId.toString().isNotEmpty) {
  //         await prefs.setString('bloodId', donorId.toString());
  //       }

  //       if (mounted) {
  //         showTopSnackBar(context, "Login successful!");
  //         Navigator.pushAndRemoveUntil(
  //           context,
  //           MaterialPageRoute(builder: (context) => const Bottomnav()),
  //           (route) => false,
  //         );
  //       }
  //     } else {
  //       setState(() {
  //         otpError = response.data["message"] ?? "Invalid OTP. Please try again.";
  //         isVerifying = false;
  //       });
  //     }
  //   } on DioException catch (dioError) {
  //     String errorMessage = "Something went wrong";
  //     if (dioError.response != null) {
  //       try {
  //         errorMessage = dioError.response?.data['message'] ?? errorMessage;
  //       } catch (_) {}
  //     }
  //     setState(() {
  //       otpError = errorMessage;
  //       isVerifying = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       otpError = "Invalid OTP. Please try again.";
  //       isVerifying = false;
  //     });
  //   }
  // }

  Future<void> _verifyOtp() async {
  String otp = otpController.text;
  String rawPhone = widget.phone;
  
  // Clean phone number - remove +91, spaces, dashes
  String cleanedPhone = rawPhone
      .replaceAll('+', '')
      .replaceAll(' ', '')
      .replaceAll('-', '');
  
  // Remove 91 if present (91 9876543210 -> 9876543210)
  if (cleanedPhone.startsWith('91') && cleanedPhone.length == 12) {
    cleanedPhone = cleanedPhone.substring(2);
  }
  
  if (otp.length != 6) {
    setState(() {
      otpError = "Please enter a valid 6-digit OTP";
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
      "phone": cleanedPhone,
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
      
      if (mounted) {
        showTopSnackBar(context, "Login successful!");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Bottomnav()),
          (route) => false,
        );
      }
    } else {
      setState(() {
        otpError = response.data["message"] ?? "Invalid OTP. Please try again.";
        isVerifying = false;
      });
    }
  } on DioException catch (dioError) {
    String errorMessage = "Something went wrong";
    if (dioError.response != null) {
      try {
        errorMessage = dioError.response?.data['message'] ?? errorMessage;
      } catch (_) {}
    }
    setState(() {
      otpError = errorMessage;
      isVerifying = false;
    });
  } catch (e) {
    setState(() {
      otpError = "Invalid OTP. Please try again.";
      isVerifying = false;
    });
  }
}
 
  @override
  Widget build(BuildContext context) {
    _startResendTimer();
    
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 600;
    
    // Responsive sizing
    final dialogWidth = isLargeScreen 
        ? screenWidth * 0.4 
        : screenWidth * 0.9;
    
    final iconSize = mediaQuery.size.width * 0.12;
    final titleFontSize = mediaQuery.textScaler.scale(20);
    final subtitleFontSize = mediaQuery.textScaler.scale(14);
    final buttonFontSize = mediaQuery.textScaler.scale(16);
    final pinFontSize = mediaQuery.textScaler.scale(isSmallScreen ? 20 : 24);
    final errorFontSize = mediaQuery.textScaler.scale(12);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.85,
          minWidth: isSmallScreen ? 280 : 320,
        ),
        padding: EdgeInsets.all(mediaQuery.size.width * 0.06),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with responsive size
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smartphone_rounded,
                color: Colors.green,
                size: iconSize * 0.5,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Title text
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "Enter Verification Code",
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),

            // Subtitle text
            Text(
              "Code sent to ${widget.phone}",
              style: TextStyle(
                color: Colors.grey[600], 
                fontSize: subtitleFontSize
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.03),

            // Pin code field - using LayoutBuilder for dynamic field width
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final fieldWidth = isLargeScreen 
                    ? 60.0
                    : (availableWidth - 40) / 6;
                
                return PinCodeTextField(
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
                    fontSize: pinFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: isSmallScreen ? 45 : 55,
                    fieldWidth: fieldWidth.clamp(
                      isSmallScreen ? 35 : 40, 
                      isLargeScreen ? 70 : 50
                    ),
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
                      _verifyOtp();
                    }
                  },
                  onChanged: (value) {
                    if (otpError != null) {
                      setState(() {
                        otpError = null;
                      });
                    }
                    if (value.length == 6 && !isVerifying && !isOtpFilled) {
                      setState(() => isOtpFilled = true);
                      Future.delayed(const Duration(milliseconds: 800), () {
                        if (mounted && !isVerifying) {
                          _verifyOtp();
                        }
                      });
                    }
                  },
                );
              },
            ),

            // Error message with responsive font
            if (otpError != null)
              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.01),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: errorFontSize,
                    ),
                    SizedBox(width: screenWidth * 0.01),
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

            SizedBox(height: screenHeight * 0.03),

            // Verify button with responsive height
          SizedBox(
  width: double.infinity,
  height: mediaQuery.size.height * 0.065,
  child: ElevatedButton(
                onPressed: isVerifying ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isVerifying
                    ? SizedBox(
                        width: mediaQuery.size.width * 0.06,
                        height: mediaQuery.size.width * 0.06,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Verify & Login",
                        style: TextStyle(
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            SizedBox(height: screenHeight * 0.02),

            // Resend OTP row
            ResponsiveResendRow(
              resendAfter: resendAfter,
              isVerifying: isVerifying,
              onResend: () {
                Navigator.pop(context);
                widget.onResendOtp();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Extracted resend row widget for better organization
class ResponsiveResendRow extends StatelessWidget {
  final int resendAfter;
  final bool isVerifying;
  final VoidCallback onResend;

  const ResponsiveResendRow({
    super.key,
    required this.resendAfter,
    required this.isVerifying,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isSmallScreen = mediaQuery.size.width < 360;
    final textScale = mediaQuery.textScaler;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            "Didn't receive code? ",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: textScale.scale(isSmallScreen ? 12 : 14),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: resendAfter > 0
              ? TweenAnimationBuilder(
                  tween: Tween<double>(
                    begin: resendAfter.toDouble(),
                    end: 0,
                  ),
                  duration: Duration(seconds: resendAfter),
                  builder: (context, double value, child) {
                    return Text(
                      "Resend in ${value.toInt()}s",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                        fontSize: textScale.scale(isSmallScreen ? 12 : 14),
                      ),
                    );
                  },
                )
              : GestureDetector(
                  onTap: isVerifying ? null : onResend,
                  child: Text(
                    "Resend OTP",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: textScale.scale(isSmallScreen ? 12 : 14),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}