

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hosta/common/top_snackbar.dart';
import '../../../services/api_service.dart';
import 'signin.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
final formkey=GlobalKey<FormState>();
  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool acceptPolicy = false;
  bool isLoading = false;

  final ApiService _apiService = ApiService();

  // Helper function for responsive sizing
  double getResponsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  double getResponsiveHeight(BuildContext context, double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }

  double getResponsiveFontSize(BuildContext context, double size) {
    return MediaQuery.of(context).size.width * (size / 375); // 375 is base width
  }

  // ✅ NEW FUNCTION (fix lag)
Future<void> _handleSubmit() async {
  if (!formkey.currentState!.validate()) {
    return;
  }

  if (!acceptPolicy) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please accept the privacy policy"),
      ),
    );
    return;
  }

  setState(() => isLoading = true);
  await _submit();
}

  // ✅ CLEANED SUBMIT
  Future<void> _submit() async {
    final payload = {
      "name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "phone": phoneController.text.trim(),
      "password": passwordController.text.trim(),
    };

    try {
      final response = await _apiService.signupUser(payload);

      setState(() => isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration successful"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Signin()),
        );
      }
    } 
  on DioException catch (dioError) {
  setState(() => isLoading = false);

  String errorMessage = "Something went wrong";

  if (dioError.response != null) {
    final backendMessage =
        dioError.response?.data['message']
                ?.toString()
                .toLowerCase() ??
            '';

    if (backendMessage.contains('user already exists')) {
      errorMessage = 'User already exists';
    } else if (backendMessage.contains('phone')) {
      errorMessage = 'This phone number is already registered';
    } else if (backendMessage.contains('email')) {
      errorMessage = 'This email is already registered';
    } else {
      errorMessage =
          dioError.response?.data['message'] ?? errorMessage;
    }
  }

  showTopSnackBar(context, errorMessage, isError: true);
}
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        toolbarHeight: screenHeight * 0.08, // Responsive app bar height
        title: Text(
          "Registration",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: getResponsiveFontSize(context, 20),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, 
            color: Colors.white,
            size: getResponsiveFontSize(context, 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: formkey,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.064, // 24px on 375 width
              vertical: isKeyboardVisible ? screenHeight * 0.02 : screenHeight * 0.04,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Full Name Field
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    labelStyle: TextStyle(
                      fontSize: getResponsiveFontSize(context, 16),
                    ),
                    prefixIcon: Icon(Icons.person, 
                      size: getResponsiveFontSize(context, 20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.018,
                    ),
                  ),
  
                  style: TextStyle(
                    fontSize: getResponsiveFontSize(context, 16),
                  ),
                                   validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your name";
    }
    return null;
  },
                ),
                SizedBox(height: screenHeight * 0.02), // 16px on standard height
        
                // Email Field
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(
                      fontSize: getResponsiveFontSize(context, 16),
                    ),
                    prefixIcon: Icon(Icons.email,
                      size: getResponsiveFontSize(context, 20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.018,
                    ),
                  ),
  
                  style: TextStyle(
                    fontSize: getResponsiveFontSize(context, 16),
                  ),
                                    validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter email";
    }

    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(value.trim())) {
      return "Enter a valid email";
    }

    return null;
  },
                ),
                SizedBox(height: screenHeight * 0.02),
        
                // Phone Field
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    labelStyle: TextStyle(
                      fontSize: getResponsiveFontSize(context, 16),
                    ),
                    prefixIcon: Icon(Icons.phone,
                      size: getResponsiveFontSize(context, 20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.018,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: getResponsiveFontSize(context, 16),
                  ),
                   validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter phone number";
    }

    if (!RegExp(r'^[6-9][0-9]{9}$')
        .hasMatch(value.trim())) {
      return "Enter a valid phone number";
    }

    return null;
  },
                ),
                SizedBox(height: screenHeight * 0.02),
        
                // Password Field
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(
                      fontSize: getResponsiveFontSize(context, 16),
                    ),
                    prefixIcon: Icon(Icons.lock,
                      size: getResponsiveFontSize(context, 20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.018,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                        size: getResponsiveFontSize(context, 20),
                      ),
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: getResponsiveFontSize(context, 16),
                  ),
                   validator: (value) {
    if (value == null || value.isEmpty) {
      return "Please enter password";
    }

    if (value.length < 8) {
      return "Password must be at least 8 characters";
    }

    return null;
  },
                ),
                SizedBox(height: screenHeight * 0.02),
        
                // Confirm Password Field
                TextFormField(
                  controller: confirmController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    labelStyle: TextStyle(
                      fontSize: getResponsiveFontSize(context, 16),
                    ),
                    prefixIcon: Icon(Icons.lock_outline,
                      size: getResponsiveFontSize(context, 20),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.018,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        size: getResponsiveFontSize(context, 20),
                      ),
                      onPressed: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: getResponsiveFontSize(context, 16),
                  ),
                    validator: (value) {
    if (value == null || value.isEmpty) {
      return "Please confirm password";
    }

    if (value != passwordController.text) {
      return "Passwords do not match";
    }

    return null;
  },
                ),
                SizedBox(height: screenHeight * 0.02),
        
                // Privacy Policy Checkbox
                Row(
                  children: [
                    SizedBox(
                      width: getResponsiveWidth(context, 0.07), // Responsive checkbox size
                      height: getResponsiveHeight(context, 0.04),
                      child: Checkbox(
                        value: acceptPolicy,
                        onChanged: (val) => setState(() => acceptPolicy = val!),
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: "I accept the ",
                          style: TextStyle(
                            fontSize: getResponsiveFontSize(context, 14),
                          ),
                          children: [
                            TextSpan(
                              text: "Privacy Policy",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                                fontSize: getResponsiveFontSize(context, 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.025),
        
                // Submit Button
                ElevatedButton(
                  onPressed: isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(
                      double.infinity,
                      screenHeight * 0.065, // Responsive button height
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: getResponsiveHeight(context, 0.025),
                          width: getResponsiveWidth(context, 0.05),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Submit",
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: getResponsiveFontSize(context, 16),
                          ),
                        ),
                ),
        
                SizedBox(height: screenHeight * 0.02),
        
                // Login Link
                    Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Have an account? ",
                      style: TextStyle(
                        fontSize: getResponsiveFontSize(context, 14),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const Signin()),
                      ),
                      child: Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: getResponsiveFontSize(context, 14),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Add bottom padding when keyboard is visible
                SizedBox(height: isKeyboardVisible ? screenHeight * 0.02 : 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}