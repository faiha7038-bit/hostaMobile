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
  final formkey = GlobalKey<FormState>();
  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool acceptPolicy = false;
  bool isLoading = false;

  final ApiService _apiService = ApiService();

  // Clamp helper for responsive values
  double _clamp(double value, double min, double max) =>
      value.clamp(min, max) as double;

  // Helper function for responsive sizing with clamping
  double getResponsiveWidth(BuildContext context, double percentage) {
    final value = MediaQuery.of(context).size.width * percentage;
    return _clamp(value, 20, 120); // clamp between 20 and 120
  }

  double getResponsiveHeight(BuildContext context, double percentage) {
    final value = MediaQuery.of(context).size.height * percentage;
    return _clamp(value, 10, 80); // clamp between 10 and 80
  }

  double getResponsiveFontSize(BuildContext context, double size) {
    final baseWidth = 375.0;
    final value = MediaQuery.of(context).size.width * (size / baseWidth);
    return _clamp(value, 12, 24); // clamp between 12 and 24
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
    } on DioException catch (dioError) {
      setState(() => isLoading = false);

      String errorMessage = "Something went wrong";

      if (dioError.response != null) {
        final backendMessage =
            dioError.response?.data['message']?.toString().toLowerCase() ?? '';

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

    // Clamped dimensions used throughout
    final double appBarHeight = _clamp(screenHeight * 0.08, 56, 80);
    final double titleFontSize = getResponsiveFontSize(context, 20);
    final double backIconSize = getResponsiveFontSize(context, 20);
    final double labelFontSize = getResponsiveFontSize(context, 16);
    final double fieldIconSize = getResponsiveFontSize(context, 20);
    final double checkboxSize = _clamp(screenWidth * 0.07, 24, 48);
    final double checkboxHeight = _clamp(screenHeight * 0.04, 20, 48);
    final double buttonHeight = _clamp(screenHeight * 0.065, 48, 64);
    final double loaderSize = _clamp(screenHeight * 0.025, 20, 32);
    final double loaderWidth = _clamp(screenWidth * 0.05, 20, 40);
    final double fieldRadius = _clamp(screenWidth * 0.032, 8, 16);
    final double horizontalPadding = screenWidth * 0.064;
    final double verticalPadding = isKeyboardVisible
        ? screenHeight * 0.02
        : screenHeight * 0.04;
    final double contentPaddingH = screenWidth * 0.04;
    final double contentPaddingV = screenHeight * 0.018;
    final double spacing = screenHeight * 0.02;
    final double spacingSmall = screenHeight * 0.025;
    final double spacingLarge = screenHeight * 0.02;

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        toolbarHeight: appBarHeight, // Responsive app bar height
        title: Text(
          "Registration",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: titleFontSize,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: backIconSize,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: formkey,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
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
                      fontSize: labelFontSize,
                    ),
                    prefixIcon: Icon(
                      Icons.person,
                      size: fieldIconSize,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fieldRadius),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: contentPaddingH,
                      vertical: contentPaddingV,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: labelFontSize,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter your name";
                    }
                    return null;
                  },
                ),
                SizedBox(height: spacing),

                // Email Field
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(
                      fontSize: labelFontSize,
                    ),
                    prefixIcon: Icon(
                      Icons.email,
                      size: fieldIconSize,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fieldRadius),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: contentPaddingH,
                      vertical: contentPaddingV,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: labelFontSize,
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
                SizedBox(height: spacing),

                // Phone Field
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                    labelStyle: TextStyle(
                      fontSize: labelFontSize,
                    ),
                    prefixIcon: Icon(
                      Icons.phone,
                      size: fieldIconSize,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fieldRadius),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: contentPaddingH,
                      vertical: contentPaddingV,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: labelFontSize,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter phone number";
                    }

                    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value.trim())) {
                      return "Enter a valid phone number";
                    }

                    return null;
                  },
                ),
                SizedBox(height: spacing),

                // Password Field
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(
                      fontSize: labelFontSize,
                    ),
                    prefixIcon: Icon(
                      Icons.lock,
                      size: fieldIconSize,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fieldRadius),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: contentPaddingH,
                      vertical: contentPaddingV,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                        size: fieldIconSize,
                      ),
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: labelFontSize,
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
                SizedBox(height: spacing),

                // Confirm Password Field
                TextFormField(
                  controller: confirmController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    labelStyle: TextStyle(
                      fontSize: labelFontSize,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      size: fieldIconSize,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fieldRadius),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: contentPaddingH,
                      vertical: contentPaddingV,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        size: fieldIconSize,
                      ),
                      onPressed: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: labelFontSize,
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
                SizedBox(height: spacing),

                // Privacy Policy Checkbox
                Row(
                  children: [
                    SizedBox(
                      width: checkboxSize,
                      height: checkboxHeight,
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
                            fontSize: labelFontSize,
                          ),
                          children: [
                            TextSpan(
                              text: "Privacy Policy",
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                                fontSize: labelFontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacingSmall),

                // Submit Button
                ElevatedButton(
                  onPressed: isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(
                      double.infinity,
                      buttonHeight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(fieldRadius),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: loaderSize,
                          width: loaderWidth,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Submit",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: labelFontSize,
                          ),
                        ),
                ),

                SizedBox(height: spacing),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Have an account? ",
                      style: TextStyle(
                        fontSize: labelFontSize,
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
                          fontSize: labelFontSize,
                        ),
                      ),
                    ),
                  ],
                ),

                // Add bottom padding when keyboard is visible
                SizedBox(height: isKeyboardVisible ? spacing : 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}