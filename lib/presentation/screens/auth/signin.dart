// import 'dart:developer';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:hosta/common/top_snackbar.dart';
// import 'package:hosta/presentation/screens/auth/otp_verification.dart';
// import 'package:intl_phone_field/intl_phone_field.dart';
// import '../../../services/api_service.dart';
// import 'signup.dart';

// class Signin extends StatefulWidget {
//   const Signin({super.key});

//   @override
//   State<Signin> createState() => _SigninState();
// }

// class _SigninState extends State<Signin> {
//   final TextEditingController phoneController = TextEditingController();
//   final ApiService _apiService = ApiService();

//   bool isSendingOtp = false;
//   String? receivedOtp;
//   String? phoneError;

//   bool _validatePhoneNumber(String phone) {
//     String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

//     if (!cleaned.startsWith('+')) {
//       setState(() {
//         phoneError = 'Phone number must include country code (e.g., +91)';
//       });
//       return false;
//     }

//     int digitCount = cleaned.replaceAll('+', '').length;

//     if (digitCount < 10) {
//       setState(() {
//         phoneError = 'Phone number must have at least 10 digits';
//       });
//       return false;
//     } else if (digitCount > 15) {
//       setState(() {
//         phoneError = 'Phone number cannot exceed 15 digits';
//       });
//       return false;
//     }

//     setState(() {
//       phoneError = null;
//     });
//     return true;
//   }

//   Future<void> _sendOtp() async {
//     String phone = phoneController.text.trim();

//     if (!_validatePhoneNumber(phone)) {
//       return;
//     }

//     try {
//       setState(() => isSendingOtp = true);

//       final response = await _apiService.loginUser({"phone": phone});
//       log("status:${response.statusCode}");
//       log("Data:${response.data}");

//       setState(() => isSendingOtp = false);

//       if (response.statusCode == 200 && response.data["status"] == 200) {
//         final backendOtp = response.data["otp"]?.toString();
//         if (backendOtp != null && backendOtp.length == 6) {
//           setState(() {
//             receivedOtp = backendOtp;
//           });
//           _showLoadingAndThenOtp(phone, backendOtp);
//         } else {
//           _showOtpPopup(phone, null);
//         }
//       } else {
//         _showOtpPopup(phone, null);
//       }
//     } on DioException catch (dioError) {
//       setState(() => isSendingOtp = false);

//       String errorMessage = "Something went wrong";

//       if (dioError.response != null) {
//         try {
//           errorMessage = dioError.response?.data['message'] ?? errorMessage;
//         } catch (_) {}
//       }

//       if (errorMessage.toLowerCase().contains('phone') ||
//           errorMessage.toLowerCase().contains('number')) {
//         setState(() {
//           phoneError = errorMessage;
//         });
//       } else {
//         showTopSnackBar(context, errorMessage, isError: true);
//       }
//     } catch (e) {
//       setState(() => isSendingOtp = false);
//       showTopSnackBar(context, "Failed to send OTP: $e", isError: true);
//     }
//   }

//   void _showLoadingAndThenOtp(String phone, String backendOtp) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (loadingContext) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           child: Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const SizedBox(height: 20),
//                 TweenAnimationBuilder(
//                   tween: Tween<double>(begin: 0, end: 1),
//                   duration: const Duration(milliseconds: 1500),
//                   builder: (context, double value, child) {
//                     return Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         SizedBox(
//                           width: 80,
//                           height: 80,
//                           child: CircularProgressIndicator(
//                             value: value,
//                             strokeWidth: 3,
//                             backgroundColor: Colors.grey[200],
//                             valueColor: const AlwaysStoppedAnimation<Color>(
//                               Colors.green,
//                             ),
//                           ),
//                         ),
//                         const Icon(
//                           Icons.mark_email_read_rounded,
//                           size: 35,
//                           color: Colors.green,
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//                 const SizedBox(height: 24),
//                 const Text(
//                   "Sending OTP",
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "We're sending a 6-digit code to\n${phoneController.text}",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(color: Colors.grey[600], fontSize: 14),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         );
//       },
//     );

//     Future.delayed(const Duration(milliseconds: 2000), () {
//       if (mounted) {
//         Navigator.pop(context);
//         _showOtpPopup(phone, backendOtp);
//       }
//     });
//   }

//   void _showOtpPopup(String phone, String? backendOtp) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return OtpVerification(
//           phone: phone,
//           backendOtp: backendOtp,
//           apiService: _apiService,
//           onResendOtp: () {
//             _sendOtp();
//           },
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFECFDF5),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFECFDF5),
//         elevation: 0,
//         centerTitle: true,
//         automaticallyImplyLeading: false,
//       ),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
//             child: Column(
//               children: [
//                 const SizedBox(height: 20),
//                 Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     color: Colors.green.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.phone_android_rounded,
//                     color: Colors.green,
//                     size: 40,
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 const Text(
//                   "Welcome Back",
//                   style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "Login with your phone number",
//                   style: TextStyle(color: Colors.grey[600], fontSize: 16),
//                 ),
//                 const SizedBox(height: 32),

//                 IntlPhoneField(
//                   decoration: InputDecoration(
//                     labelText: 'Phone Number',
//                     labelStyle: TextStyle(
//                       color: phoneError != null ? Colors.red : Colors.grey[600],
//                     ),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(16),
//                       borderSide: BorderSide(
//                         color: phoneError != null ? Colors.red : Colors.grey[300]!,
//                         width: phoneError != null ? 1.5 : 1,
//                       ),
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(16),
//                       borderSide: BorderSide(
//                         color: phoneError != null ? Colors.red : Colors.grey[300]!,
//                         width: phoneError != null ? 1.5 : 1,
//                       ),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(16),
//                       borderSide: BorderSide(
//                         color: phoneError != null ? Colors.red : Colors.green,
//                         width: 2,
//                       ),
//                     ),
//                     errorBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(16),
//                       borderSide: const BorderSide(
//                         color: Colors.red,
//                         width: 1.5,
//                       ),
//                     ),
//                     focusedErrorBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(16),
//                       borderSide: const BorderSide(color: Colors.red, width: 2),
//                     ),
//                     errorText: phoneError,
//                     errorStyle: const TextStyle(
//                       color: Colors.red,
//                       fontSize: 12,
//                     ),
//                     filled: true,
//                     fillColor: Colors.white,
//                     contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 12,
//                     ),
//                   ),
//                   initialCountryCode: 'IN',
//                   onChanged: (phone) {
//                     phoneController.text = phone.completeNumber;
//                     if (phoneError != null) {
//                       setState(() {
//                         phoneError = null;
//                       });
//                     }
//                   },
//                 ),

//                 const SizedBox(height: 24),

//                 Container(
//                   width: double.infinity,
//                   height: 55,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(16),
//                     gradient: const LinearGradient(
//                       colors: [Colors.green, Color(0xFF43A047)],
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.green.withOpacity(0.3),
//                         blurRadius: 10,
//                         offset: const Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: ElevatedButton(
//                     onPressed: isSendingOtp ? null : _sendOtp,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.transparent,
//                       shadowColor: Colors.transparent,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                     ),
//                     child: isSendingOtp
//                         ? const SizedBox(
//                             width: 24,
//                             height: 24,
//                             child: CircularProgressIndicator(
//                               color: Colors.white,
//                               strokeWidth: 2,
//                             ),
//                           )
//                         : const Text(
//                             "Send OTP",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                   ),
//                 ),

//                 const SizedBox(height: 28),

//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       "Don't have an account? ",
//                       style: TextStyle(color: Colors.grey[600]),
//                     ),
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(builder: (_) => const Signup()),
//                         );
//                       },
//                       child: const Text(
//                         "Register here",
//                         style: TextStyle(
//                           color: Colors.green,
//                           fontWeight: FontWeight.w600,
//                           decoration: TextDecoration.underline,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'dart:developer';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:hosta/common/top_snackbar.dart';
// import 'package:hosta/presentation/screens/auth/otp_verification.dart';
// import 'package:intl_phone_field/intl_phone_field.dart';
// import '../../../services/api_service.dart';
// import 'signup.dart';

// class Signin extends StatefulWidget {
//   const Signin({super.key});

//   @override
//   State<Signin> createState() => _SigninState();
// }

// class _SigninState extends State<Signin> {
//   final TextEditingController phoneController = TextEditingController();
//   final ApiService _apiService = ApiService();

//   bool isSendingOtp = false;
//   String? receivedOtp;
//   String? phoneError;

//   bool _validatePhoneNumber(String phone) {
//     String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

//     if (!cleaned.startsWith('+')) {
//       setState(() {
//         phoneError = 'Phone number must include country code (e.g., +91)';
//       });
//       return false;
//     }

//     int digitCount = cleaned.replaceAll('+', '').length;

//     if (digitCount < 10) {
//       setState(() {
//         phoneError = 'Phone number must have at least 10 digits';
//       });
//       return false;
//     } else if (digitCount > 15) {
//       setState(() {
//         phoneError = 'Phone number cannot exceed 15 digits';
//       });
//       return false;
//     }

//     setState(() {
//       phoneError = null;
//     });
//     return true;
//   }

//   Future<void> _sendOtp() async {
//     String phone = phoneController.text.trim();
    


    
// // Future<void> _sendOtp() async {
// //   String rawPhone = phoneController.text.trim();
  
// //   // ✅ Add this phone cleaning logic
// //   String phone = rawPhone
// //       .replaceAll('+', '')
// //       .replaceAll(' ', '')
// //       .replaceAll('-', '');
  
// //   // Remove +91 or 91 if present
// //   if (phone.startsWith('91') && phone.length == 12) {
// //     phone = phone.substring(2);
// //   }
  
// //   // ✅ Check if it's exactly 10 digits
// //   if (phone.length != 10) {
// //     setState(() {
// //       phoneError = "Enter 10-digit mobile number";
// //     });
// //     return;
// //   }
  
// //   setState(() {
// //     phoneError = null;
// //     isSendingOtp = true;
// //   });
  
// //   try {
// //     // ✅ Send cleaned phone number (10 digits only)
// //     final response = await _apiService.loginUser({"phone": phone});
    
// //     log("status:${response.statusCode}");
// //     log("Data:${response.data}");
    
// //     setState(() => isSendingOtp = false);
    
// //     if (response.statusCode == 200 && response.data["status"] == 200) {
// //       final backendOtp = response.data["otp"]?.toString();
// //       if (backendOtp != null && backendOtp.length == 6) {
// //         setState(() {
// //           receivedOtp = backendOtp;
// //         });
// //         _showLoadingAndThenOtp(phone, backendOtp);
// //       } else {
// //         _showOtpPopup(phone, null);
// //       }
// //     } else {
// //       _showOtpPopup(phone, null);
// //     }
// //   } on DioException catch (dioError) {
// //     setState(() => isSendingOtp = false);
// //     // ... rest of error handling
// //   }
// // }
// Future<void> _sendOtp() async {
//   String rawPhone = phoneController.text.trim();
  
//   // Clean phone number - remove +91, spaces, dashes
//   String cleanedPhone = rawPhone
//       .replaceAll('+', '')
//       .replaceAll(' ', '')
//       .replaceAll('-', '');
  
//   // Remove 91 if present (91 9876543210 -> 9876543210)
//   if (cleanedPhone.startsWith('91') && cleanedPhone.length == 12) {
//     cleanedPhone = cleanedPhone.substring(2);
//   }
  
//   // Validate - must be exactly 10 digits
//   if (cleanedPhone.length != 10) {
//     setState(() {
//       phoneError = "Enter 10-digit mobile number";
//     });
//     return;
//   }
  
//   setState(() {
//     phoneError = null;
//     isSendingOtp = true;
//   });
  
//   try {
//     // Send CLEANED phone number
//     final response = await _apiService.loginUser({"phone": cleanedPhone});
    
//     log("status:${response.statusCode}");
//     log("Data:${response.data}");
    
//     setState(() => isSendingOtp = false);
    
//     if (response.statusCode == 200 && response.data["status"] == 200) {
//       final backendOtp = response.data["otp"]?.toString();
//       if (backendOtp != null && backendOtp.length == 6) {
//         setState(() {
//           receivedOtp = backendOtp;
//         });
//         _showLoadingAndThenOtp(cleanedPhone, backendOtp);
//       } else {
//         _showOtpPopup(cleanedPhone, null);
//       }
//     } else {
//       _showOtpPopup(cleanedPhone, null);
//     }
//   } on DioException catch (dioError) {
//     setState(() => isSendingOtp = false);
    
//     String errorMessage = "Something went wrong";
//     if (dioError.response != null) {
//       try {
//         errorMessage = dioError.response?.data['message'] ?? errorMessage;
//       } catch (_) {}
//     }
    
//     if (errorMessage.toLowerCase().contains('phone') ||
//         errorMessage.toLowerCase().contains('number')) {
//       setState(() {
//         phoneError = errorMessage;
//       });
//     } else {
//       showTopSnackBar(context, errorMessage, isError: true);
//     }
//   } catch (e) {
//     setState(() => isSendingOtp = false);
//     showTopSnackBar(context, "Failed to send OTP: $e", isError: true);
//   }
// }



//     if (!_validatePhoneNumber(phone)) {
//       return;
//     }

//     try {
//       setState(() => isSendingOtp = true);

//       final response = await _apiService.loginUser({"phone": phone});
//       log("status:${response.statusCode}");
//       log("Data:${response.data}");

//       setState(() => isSendingOtp = false);

//       if (response.statusCode == 200 && response.data["status"] == 200) {
//         final backendOtp = response.data["otp"]?.toString();
//         if (backendOtp != null && backendOtp.length == 6) {
//           setState(() {
//             receivedOtp = backendOtp;
//           });
//           _showLoadingAndThenOtp(phone, backendOtp);
//         } else {
//           _showOtpPopup(phone, null);
//         }
//       } else {
//         _showOtpPopup(phone, null);
//       }
//     } on DioException catch (dioError) {
//       setState(() => isSendingOtp = false);

//       String errorMessage = "Something went wrong";

//       if (dioError.response != null) {
//         try {
//           errorMessage = dioError.response?.data['message'] ?? errorMessage;
//         } catch (_) {}
//       }

//       if (errorMessage.toLowerCase().contains('phone') ||
//           errorMessage.toLowerCase().contains('number')) {
//         setState(() {
//           phoneError = errorMessage;
//         });
//       } else {
//         showTopSnackBar(context, errorMessage, isError: true);
//       }
//     } catch (e) {
//       setState(() => isSendingOtp = false);
//       showTopSnackBar(context, "Failed to send OTP: $e", isError: true);
//     }
//   }

//   void _showLoadingAndThenOtp(String phone, String backendOtp) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (loadingContext) {
//         return Dialog(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           child: Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const SizedBox(height: 20),
//                 TweenAnimationBuilder(
//                   tween: Tween<double>(begin: 0, end: 1),
//                   duration: const Duration(milliseconds: 1500),
//                   builder: (context, double value, child) {
//                     return Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         SizedBox(
//                           width: 80,
//                           height: 80,
//                           child: CircularProgressIndicator(
//                             value: value,
//                             strokeWidth: 3,
//                             backgroundColor: Colors.grey[200],
//                             valueColor: const AlwaysStoppedAnimation<Color>(
//                               Colors.green,
//                             ),
//                           ),
//                         ),
//                         const Icon(
//                           Icons.mark_email_read_rounded,
//                           size: 35,
//                           color: Colors.green,
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//                 const SizedBox(height: 24),
//                 const Text(
//                   "Sending OTP",
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "We're sending a 6-digit code to\n${phoneController.text}",
//                   textAlign: TextAlign.center,
//                   style: TextStyle(color: Colors.grey[600], fontSize: 14),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//         );
//       },
//     );

//     Future.delayed(const Duration(milliseconds: 2000), () {
//       if (mounted) {
//         Navigator.pop(context);
//         _showOtpPopup(phone, backendOtp);
//       }
//     });
//   }

//   void _showOtpPopup(String phone, String? backendOtp) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) {
//         return OtpVerification(
//           phone: phone,
//           backendOtp: backendOtp,
//           apiService: _apiService,
//           onResendOtp: () {
//             _sendOtp();
//           },
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFECFDF5),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFECFDF5),
//         elevation: 0,
//         centerTitle: true,
//         automaticallyImplyLeading: false,
//       ),
//       body: SafeArea(
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             // Get screen dimensions
//             final screenWidth = MediaQuery.of(context).size.width;
//             final screenHeight = MediaQuery.of(context).size.height;
            
//             // Responsive values
//             final isSmallScreen = screenWidth < 360;
//             final isLargeScreen = screenWidth > 600;
//             final isTablet = screenWidth > 768;
            
//             // Responsive padding
//             final horizontalPadding = isTablet ? 48.0 : (isSmallScreen ? 16.0 : 24.0);
//             final verticalPadding = isTablet ? 48.0 : 24.0;
            
//             // Responsive icon container size
//             final iconContainerSize = isSmallScreen ? 60.0 : (isTablet ? 100.0 : 80.0);
//             final iconSize = isSmallScreen ? 30.0 : (isTablet ? 50.0 : 40.0);
            
//             // Responsive text sizes
//             final welcomeFontSize = isSmallScreen ? 24.0 : (isTablet ? 36.0 : 28.0);
//             final subtitleFontSize = isSmallScreen ? 14.0 : (isTablet ? 18.0 : 16.0);
//             final buttonFontSize = isSmallScreen ? 14.0 : 16.0;
            
//             // Responsive button height
//             final buttonHeight = isSmallScreen ? 48.0 : (isTablet ? 60.0 : 55.0);
            
//             // Responsive spacing
//             final spacing1 = isSmallScreen ? 12.0 : (isTablet ? 24.0 : 20.0);
//             final spacing2 = isSmallScreen ? 24.0 : (isTablet ? 48.0 : 32.0);
            
//             return Center(
//               child: SingleChildScrollView(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: horizontalPadding, 
//                   vertical: verticalPadding
//                 ),
//                 child: ConstrainedBox(
//                   constraints: BoxConstraints(
//                     maxWidth: isTablet ? 500 : screenWidth,
//                   ),
//                   child: Column(
//                     children: [
//                       SizedBox(height: isSmallScreen ? 10 : (isTablet ? 30 : 20)),
                      
//                       // Icon Container
//                       Container(
//                         width: iconContainerSize,
//                         height: iconContainerSize,
//                         decoration: BoxDecoration(
//                           color: Colors.green.withOpacity(0.1),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           Icons.phone_android_rounded,
//                           color: Colors.green,
//                           size: iconSize,
//                         ),
//                       ),
                      
//                       SizedBox(height: spacing1),
                      
//                       // Welcome Text
//                       Text(
//                         "Welcome Back",
//                         style: TextStyle(
//                           fontSize: welcomeFontSize, 
//                           fontWeight: FontWeight.bold
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
                      
//                       SizedBox(height: isSmallScreen ? 4 : 8),
                      
//                       // Subtitle
//                       Text(
//                         "Login with your phone number",
//                         style: TextStyle(
//                           color: Colors.grey[600], 
//                           fontSize: subtitleFontSize
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
                      
//                       SizedBox(height: spacing2),

//                       // Phone Input Field
//                       IntlPhoneField(
//                         decoration: InputDecoration(
//                           labelText: 'Phone Number',
//                           labelStyle: TextStyle(
//                             color: phoneError != null ? Colors.red : Colors.grey[600],
//                             fontSize: isSmallScreen ? 12 : 14,
//                           ),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(16),
//                             borderSide: BorderSide(
//                               color: phoneError != null ? Colors.red : Colors.grey[300]!,
//                               width: phoneError != null ? 1.5 : 1,
//                             ),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(16),
//                             borderSide: BorderSide(
//                               color: phoneError != null ? Colors.red : Colors.grey[300]!,
//                               width: phoneError != null ? 1.5 : 1,
//                             ),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(16),
//                             borderSide: BorderSide(
//                               color: phoneError != null ? Colors.red : Colors.green,
//                               width: 2,
//                             ),
//                           ),
//                           errorBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(16),
//                             borderSide: const BorderSide(
//                               color: Colors.red,
//                               width: 1.5,
//                             ),
//                           ),
//                           focusedErrorBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(16),
//                             borderSide: const BorderSide(color: Colors.red, width: 2),
//                           ),
//                           errorText: phoneError,
//                           errorStyle: const TextStyle(
//                             color: Colors.red,
//                             fontSize: 12,
//                           ),
//                           filled: true,
//                           fillColor: Colors.white,
//                           contentPadding: EdgeInsets.symmetric(
//                             horizontal: isSmallScreen ? 12 : 16,
//                             vertical: isSmallScreen ? 10 : 12,
//                           ),
//                         ),
//                         initialCountryCode: 'IN',
//                         onChanged: (phone) {
//                           phoneController.text = phone.completeNumber;
//                           if (phoneError != null) {
//                             setState(() {
//                               phoneError = null;
//                             });
//                           }
//                         },
//                       ),

//                       SizedBox(height: spacing2),

//                       // Send OTP Button
//                       Container(
//                         width: double.infinity,
//                         height: buttonHeight,
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(16),
//                           gradient: const LinearGradient(
//                             colors: [Colors.green, Color(0xFF43A047)],
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: Colors.green.withOpacity(0.3),
//                               blurRadius: 10,
//                               offset: const Offset(0, 5),
//                             ),
//                           ],
//                         ),
//                         child: ElevatedButton(
//                           onPressed: isSendingOtp ? null : _sendOtp,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.transparent,
//                             shadowColor: Colors.transparent,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                           ),
//                           child: isSendingOtp
//                               ? SizedBox(
//                                   width: isSmallScreen ? 20 : 24,
//                                   height: isSmallScreen ? 20 : 24,
//                                   child: const CircularProgressIndicator(
//                                     color: Colors.white,
//                                     strokeWidth: 2,
//                                   ),
//                                 )
//                               : Text(
//                                   "Send OTP",
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: buttonFontSize,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                         ),
//                       ),

//                       SizedBox(height: isSmallScreen ? 20 : 28),

//                       // Register Link
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             "Don't have an account? ",
//                             style: TextStyle(
//                               color: Colors.grey[600],
//                               fontSize: isSmallScreen ? 12 : 14,
//                             ),
//                           ),
//                           GestureDetector(
//                             onTap: () {
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (_) => const Signup()),
//                               );
//                             },
//                             child: Text(
//                               "Register here",
//                               style: TextStyle(
//                                 color: Colors.green,
//                                 fontWeight: FontWeight.w600,
//                                 decoration: TextDecoration.underline,
//                                 fontSize: isSmallScreen ? 12 : 14,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
                      
//                       // Add bottom padding for keyboard
//                       SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
//                     ],
//                   ),
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }


import 'dart:developer';
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
    
    log("📱 Cleaned phone number: $cleaned");
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
     log("Send OTP button tapped");
    String rawPhone = phoneController.text.trim();
    String cleanPhone = _cleanPhoneNumber(rawPhone);
    
    log("🚀 Sending OTP for phone: $cleanPhone");
    
    // Validate phone number
    if (!_validatePhoneNumber(cleanPhone)) {
      return;
    }

    setState(() {
      isSendingOtp = true;
      phoneError = null;
    });

    try {
      // Try different phone number formats that your backend might expect
      // Format 1: Just 10 digits (most common)
      final requestData = {"phone": cleanPhone};
      
      // Format 2: With country code (uncomment if above doesn't work)
      // final requestData = {"phone": "+91$cleanPhone"};
      
      // Format 3: With 91 prefix (uncomment if needed)
      // final requestData = {"phone": "91$cleanPhone"};
      
      log("📤 API Request - Endpoint: /users/login");
      log("📤 Request data: $requestData");
      
      final response = await _apiService.loginUser(requestData);
      
      log("📥 Response status: ${response.statusCode}");
      log("📥 Response data: ${response.data}");

      setState(() => isSendingOtp = false);

      // Check for successful response
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Check different possible success indicators
        if (response.data["status"] == 200 || 
            response.data["success"] == true ||
            response.data["otp"] != null) {
          
          final backendOtp = response.data["otp"]?.toString();
          final message = response.data["message"];
          
          log("✅ OTP sent successfully!");
          log("🔑 Backend OTP: $backendOtp");
          log("💬 Message: $message");
          
          if (backendOtp != null && backendOtp.length == 6) {
            _showLoadingAndThenOtp(cleanPhone, backendOtp);
          } else {
            // Still show OTP screen even if no OTP in response (user will enter manually)
            _showOtpPopup(cleanPhone, null);
          }
        } else {
          // API returned success status code but indicates failure in response body
          String errorMsg = response.data['message'] ?? 'Failed to send OTP';
          log("❌ API returned error: $errorMsg");
          
          if (errorMsg.toLowerCase().contains('user') && 
              errorMsg.toLowerCase().contains('not found')) {
            // User not registered - show signup option
            _showUserNotFoundDialog(errorMsg);
          } else {
            _showErrorDialog(errorMsg);
          }
        }
      } else {
        // HTTP error status code
        String errorMsg = response.data['message'] ?? 'Failed to send OTP';
        log("❌ HTTP Error ${response.statusCode}: $errorMsg");
        _showErrorDialog(errorMsg);
      }
    } on DioException catch (dioError) {
      setState(() => isSendingOtp = false);
      
      log("❌ DioException occurred");
      log("Error type: ${dioError.type}");
      log("Error message: ${dioError.message}");
      
      String errorMessage = "Something went wrong";
      
      if (dioError.response != null) {
        log("Response status: ${dioError.response?.statusCode}");
        log("Response data: ${dioError.response?.data}");
        try {
          errorMessage = dioError.response?.data['message'] ?? 
                        dioError.response?.data['error'] ?? 
                        errorMessage;
        } catch (_) {}
      } else if (dioError.type == DioExceptionType.connectionTimeout) {
        errorMessage = "Connection timeout. Please check your internet.";
      } else if (dioError.type == DioExceptionType.receiveTimeout) {
        errorMessage = "Server not responding. Please try again.";
      } else if (dioError.type == DioExceptionType.connectionError) {
        errorMessage = "No internet connection. Please check your network.";
      } else if (dioError.type == DioExceptionType.cancel) {
        errorMessage = "Request cancelled.";
      }
      
      _showErrorDialog(errorMessage);
    } catch (e) {
      setState(() => isSendingOtp = false);
      log("❌ Unexpected error: $e");
      _showErrorDialog("Failed to send OTP: $e");
    }
  }
  
  void _showErrorDialog(String message) {
    log("⚠️ Showing error: $message");
    
    if (message.toLowerCase().contains('phone') ||
        message.toLowerCase().contains('number') ||
        message.toLowerCase().contains('invalid')) {
      setState(() {
        phoneError = message;
      });
    } else {
      showTopSnackBar(context, message, isError: true);
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
    log("📱 Showing loading dialog for phone: +91$phone");
    
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
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.green,
                            ),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  "We're sending a 6-digit code to\n+91$phone",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
  log("🔐 Showing OTP dialog for phone: +91$phone");
  log("🔑 With backend OTP: $backendOtp");
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.05,
          vertical: MediaQuery.of(context).size.height * 0.05,
        ),
        child: OtpVerification(
          phone: "+91$phone", // Keep +91 for display only
          backendOtp: backendOtp,
          apiService: _apiService,
          onResendOtp: () {
            log("🔄 Resend OTP requested");
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
    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFECFDF5),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isSmallScreen = screenWidth < 360;
            final isTablet = screenWidth > 768;
            
            final horizontalPadding = isTablet ? 48.0 : (isSmallScreen ? 16.0 : 24.0);
            final verticalPadding = isTablet ? 48.0 : 24.0;
            final iconContainerSize = isSmallScreen ? 60.0 : (isTablet ? 100.0 : 80.0);
            final iconSize = isSmallScreen ? 30.0 : (isTablet ? 50.0 : 40.0);
            final welcomeFontSize = isSmallScreen ? 24.0 : (isTablet ? 36.0 : 28.0);
            final subtitleFontSize = isSmallScreen ? 14.0 : (isTablet ? 18.0 : 16.0);
            final buttonFontSize = isSmallScreen ? 14.0 : 16.0;
            final buttonHeight = isSmallScreen ? 48.0 : (isTablet ? 60.0 : 55.0);
            final spacing1 = isSmallScreen ? 12.0 : (isTablet ? 24.0 : 20.0);
            final spacing2 = isSmallScreen ? 24.0 : (isTablet ? 48.0 : 32.0);
            
            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding, 
                  vertical: verticalPadding
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 500 : screenWidth,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: isSmallScreen ? 10 : (isTablet ? 30 : 20)),
                      
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
                          fontWeight: FontWeight.bold
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      
                      Text(
                        "Login with your phone number",
                        style: TextStyle(
                          color: Colors.grey[600], 
                          fontSize: subtitleFontSize
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: spacing2),

                      IntlPhoneField(
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(
                            color: phoneError != null ? Colors.red : Colors.grey[600],
                            fontSize: isSmallScreen ? 12 : 14,
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
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                          errorText: phoneError,
                          errorStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16,
                            vertical: isSmallScreen ? 10 : 12,
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
                              ? SizedBox(
                                  width: isSmallScreen ? 20 : 24,
                                  height: isSmallScreen ? 20 : 24,
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

                      SizedBox(height: isSmallScreen ? 20 : 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isSmallScreen ? 12 : 14,
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
                                fontSize: isSmallScreen ? 12 : 14,
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
            );
          },
        ),
      ),
    );
  }
}