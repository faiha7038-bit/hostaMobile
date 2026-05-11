import 'dart:developer';
import 'package:flutter/material.dart';
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
    log("=== OTP SCREEN INITIALIZED ===");
    log("Phone number received: ${widget.phone}");
    log("Backend OTP received: ${widget.backendOtp}");
    
    if (widget.backendOtp != null && widget.backendOtp!.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && otpController.text.isEmpty) {
          log("Auto-filling OTP: ${widget.backendOtp}");
          otpController.text = widget.backendOtp!;
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted && !isVerifying) {
              _verifyOtp();
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

  Future<void> _verifyOtp() async {
    String otp = otpController.text.trim();
    String phone = widget.phone;
    
    log("=== STARTING OTP VERIFICATION ===");
    log("Original phone: $phone");
    
    // Clean phone number - extract only 10 digits
    String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (cleanPhone.length == 12 && cleanPhone.startsWith('91')) {
      cleanPhone = cleanPhone.substring(2);
    } else if (cleanPhone.length > 10) {
      cleanPhone = cleanPhone.substring(cleanPhone.length - 10);
    }
    
    log("Cleaned phone: $cleanPhone");
    log("Entered OTP: $otp");
    
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
        "FcmToken": token,
      });
      
      log("Response status: ${response.statusCode}");
      log("Response data: ${response.data}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data["status"] == 200 || response.data["userDetails"] != null) {
          log("✅ OTP verification successful!");
          
          final userDetails = response.data["userDetails"] ?? response.data["data"];
          
          if (userDetails != null) {
            final userId = userDetails["_id"] ?? userDetails["id"];
            final userPhone = userDetails["phone"];
            final donorId = userDetails["donorId"];
            
            final prefs = await SharedPreferences.getInstance();
            
            if (userId != null) {
              await prefs.setString('userId', userId.toString());
            }
            if (userPhone != null) {
              await prefs.setString('userPhone', userPhone.toString());
            }
            if (donorId != null && donorId.toString().isNotEmpty) {
              await prefs.setString('bloodId', donorId.toString());
            }
            if (response.data["token"] != null) {
              await prefs.setString('authToken', response.data["token"].toString());
            }
            
            if (mounted) {
              showTopSnackBar(context, "Login successful!");
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Bottomnav()),
                (route) => false,
              );
            }
          }
        } else {
          setState(() {
            otpError = response.data["message"] ?? "Invalid OTP";
            isVerifying = false;
          });
        }
      } else {
        setState(() {
          otpError = response.data["message"] ?? "Verification failed";
          isVerifying = false;
        });
      }
    } catch (e) {
      log("Error: $e");
      setState(() {
        otpError = "Something went wrong. Please try again.";
        isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _startResendTimer();
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 400, // Fixed width instead of MediaQuery
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smartphone_rounded, color: Colors.green, size: 25),
            ),
            const SizedBox(height: 12),

            // Title
            const Text(
              "Enter Verification Code",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            // Subtitle
            Text(
              "Code sent to ${widget.phone}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // PIN Field
            SizedBox(
  height: 60,
  child:
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: otpError != null ? Colors.red : Colors.grey[300]!,
      width: 1.5,
    ),
    borderRadius: BorderRadius.circular(10),
  ),
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: LayoutBuilder(
      builder: (context, constraints) {
        return PinCodeTextField(
          appContext: context,
          length: 6,
          controller: otpController,
          keyboardType: TextInputType.number,
          autoDismissKeyboard: true,
          enablePinAutofill: true,
          autoFocus: true,
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(8),
            fieldHeight: 40,
            fieldWidth: (constraints.maxWidth - 20) / 6, // Dynamic width based on container
            activeFillColor: Colors.white,
            selectedFillColor: Colors.white,
            inactiveFillColor: Colors.grey[50],
            activeColor: otpError != null ? Colors.red : Colors.green,
            selectedColor: otpError != null ? Colors.red : Colors.blue,
            inactiveColor: otpError != null ? Colors.red : Colors.grey[300]!,
            borderWidth: 1,
          ),
          onCompleted: (value) {
            if (!isVerifying) _verifyOtp();
          },
          onChanged: (value) {
            if (otpError != null) setState(() => otpError = null);
            if (value.length == 6 && !isVerifying && !isOtpFilled) {
              setState(() => isOtpFilled = true);
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && !isVerifying) _verifyOtp();
              });
            }
          },
        );
      },
    ),
  ),
),
),

            // Error Message
            if (otpError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(otpError!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: isVerifying ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isVerifying
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Verify & Login", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 12),

            // Resend Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Didn't receive code? ", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                if (resendAfter > 0)
                  Text(
                    "Resend in ${resendAfter}s",
                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 12),
                  )
                else
                  GestureDetector(
                    onTap: isVerifying ? null : () {
                      Navigator.pop(context);
                      widget.onResendOtp();
                    },
                    child: const Text(
                      "Resend OTP",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}