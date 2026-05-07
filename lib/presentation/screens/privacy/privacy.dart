import 'package:flutter/material.dart';

class Privacy extends StatelessWidget {
  const Privacy({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;
    
    // Responsive padding and font sizes
    final double horizontalPadding = screenWidth * 0.04;
    final double headingFontSize = isSmallScreen ? screenWidth * 0.045 : (isTablet ? screenWidth * 0.035 : screenWidth * 0.03);
    final double bodyFontSize = isSmallScreen ? screenWidth * 0.038 : (isTablet ? screenWidth * 0.03 : screenWidth * 0.025);
    final double appBarTitleSize = screenWidth * 0.045;
    final double iconSize = screenWidth * 0.055;
    
    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: isSmallScreen ? 1 : 2,
        title: Text(
          "Privacy Policy for Hosta",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: appBarTitleSize,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new, 
            color: Colors.white, 
            size: iconSize,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: screenHeight * 0.02,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? screenWidth * 0.7 : screenWidth,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildParagraph(
                "At Hosta, developed by Zorrow Tech IT Solutions, we respect your privacy and are committed to protecting the personal information you share with us. This Privacy Policy explains how we collect, use, and safeguard your data when you use our application.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),
              
              _buildHeading("Information We Collect", screenWidth, screenHeight, headingFontSize),
              _buildParagraph(
                "Location Data: We access your location to show you the nearest doctors, specialties, hospitals, and ambulances.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),
              _buildParagraph(
                "Personal Information: We collect your phone number and blood group if you choose to provide them. These are used to connect users who may need to find people nearby with specific blood groups.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),
              _buildParagraph(
                "Healthcare Information: We display details such as doctor names, available specialties, and working hours. This information is for reference only and is not a substitute for medical advice.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),

              _buildHeading("How We Use Your Information", screenWidth, screenHeight, headingFontSize),
              _buildListItem(
                "• To provide healthcare directory services like showing doctors, specialties, and hospitals near you.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),
              _buildListItem(
                "• To allow users to discover nearby people with specific blood groups for emergency support.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),
              _buildListItem(
                "• To provide ambulance location details to help users in emergencies.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),
              _buildListItem(
                "• To communicate with you if needed for support or service updates.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),

              _buildHeading("Data Sharing and Disclosure", screenWidth, screenHeight, headingFontSize),
              _buildParagraph(
                "We do not sell or rent your personal information. Your information may only be shared:",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),
              _buildListItem(
                "• With nearby users (only blood group and location visibility, if you enable it).",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),
              _buildListItem(
                "• Authentication: We use Twilio to send OTPs for login. Twilio may temporarily process your phone number only for this purpose and does not use it for any other activity.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),
              _buildListItem(
                "• When required by law or government authorities.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),
              _buildListItem(
                "• With trusted service providers who help us operate our services, under strict confidentiality agreements.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),

              _buildHeading("Data Security", screenWidth, screenHeight, headingFontSize),
              _buildParagraph(
                "We use industry-standard security measures to protect your information. However, no method of storage or transmission is 100% secure, and we cannot guarantee absolute security.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),

              _buildHeading("Your Choices", screenWidth, screenHeight, headingFontSize),
              _buildParagraph(
                "You can disable location services at any time in your device settings, though some features may not function properly without it.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),
              _buildParagraph(
                "Data Deletion Request: If you wish to delete your account or any personal data you have shared with us, you can send an email request to zorrowtech@gmail.com. We will permanently remove your data from our systems within 30 days of receiving your request.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),

              _buildHeading("Children's Privacy", screenWidth, screenHeight, headingFontSize),
              _buildParagraph(
                "Our app is not intended for children under 13. We do not knowingly collect data from children.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),

              _buildHeading("Disclaimer", screenWidth, screenHeight, headingFontSize),
              _buildParagraph(
                "The Hosta app provides healthcare directory information only and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of a qualified healthcare provider for medical concerns.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),

              _buildHeading("Changes to this Privacy Policy", screenWidth, screenHeight, headingFontSize),
              _buildParagraph(
                "We may update this policy from time to time. Any changes will be posted on this page with the updated date.",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),

              _buildHeading("Contact Us", screenWidth, screenHeight, headingFontSize),
              _buildParagraph(
                "If you have any questions or concerns about this Privacy Policy or your data, please contact us at:",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),
              _buildParagraph(
                "Zorrow Tech IT Solutions\nEmail: zorrowtech@gmail.com\nPhone: +91-9400517720",
                screenWidth,
                screenHeight,
                bodyFontSize,
              ),

              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper Widgets with full MediaQuery responsiveness
  
  Widget _buildHeading(String text, double screenWidth, double screenHeight, double fontSize) {
    return Padding(
      padding: EdgeInsets.only(
        top: screenHeight * 0.022,
        bottom: screenHeight * 0.01,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          letterSpacing: screenWidth * 0.001,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text, double screenWidth, double screenHeight, double fontSize) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.012),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: const Color(0xFF444444),
          height: 1.5,
          letterSpacing: screenWidth * 0.0005,
        ),
      ),
    );
  }

  Widget _buildListItem(String text, double screenWidth, double screenHeight, double fontSize) {
    return Padding(
      padding: EdgeInsets.only(
        left: screenWidth * 0.025,
        bottom: screenHeight * 0.0075,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color: const Color(0xFF444444),
          height: 1.5,
          letterSpacing: screenWidth * 0.0005,
        ),
      ),
    );
  }
}