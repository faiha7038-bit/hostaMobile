// import 'package:flutter/material.dart';

// class Privacy extends StatelessWidget {
//   const Privacy({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isSmallScreen = screenWidth < 600;
//     final isTablet = screenWidth >= 600 && screenWidth < 1200;
//     final isDesktop = screenWidth >= 1200;
    
//     // Responsive padding and font sizes
//     final double horizontalPadding = isSmallScreen ? screenWidth * 0.05 : (isTablet ? screenWidth * 0.08 : screenWidth * 0.1);
//     final double headingFontSize = isSmallScreen ? screenWidth * 0.05 : (isTablet ? screenWidth * 0.035 : screenWidth * 0.028);
//     final double bodyFontSize = isSmallScreen ? screenWidth * 0.04 : (isTablet ? screenWidth * 0.028 : screenWidth * 0.022);
//     final double appBarTitleSize = screenWidth * 0.045;
//     final double iconSize = screenWidth * 0.055;
    
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: AppBar(
//         backgroundColor:Colors.green,
//         elevation: 0,
//         title: Text(
//           "Privacy Policy",
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w700,
//             fontSize: appBarTitleSize,
//             letterSpacing: 0.5,
//           ),
//         ),
//         centerTitle: true,
//         leading: IconButton(
//           icon: Icon(
//             Icons.arrow_back_ios_new, 
//             color: Colors.white, 
//             size: iconSize,
//           ),
//           onPressed: () => Navigator.pop(context),
//         ),
//         // shape: const RoundedRectangleBorder(
//         //   borderRadius: BorderRadius.vertical(
//         //     bottom: Radius.circular(20),
//         //   ),
//         // ),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.symmetric(
//           horizontal: horizontalPadding,
//           vertical: screenHeight * 0.025,
//         ),
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             maxWidth: isDesktop ? screenWidth * 0.7 : screenWidth,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Introduction Card
//               _buildSection(
//                 title: "Introduction",
//                 items: [
//                   "At Hosta, developed by Zorrow Tech IT Solutions, we respect your privacy and are committed to protecting the personal information you share with us. This Privacy Policy explains how we collect, use, and safeguard your data when you use our application."
//                 ],
//                 screenWidth: screenWidth,
//                 screenHeight: screenHeight,
//                 headingFontSize: headingFontSize,
//                 bodyFontSize: bodyFontSize,
//               ),
              
//               SizedBox(height: screenHeight * 0.01),
              
//               _buildSection(
//                 title: "Information We Collect",
//                 items: [
//                   "Location Data: We access your location to show you the nearest doctors, specialties, hospitals, and ambulances.",
//                   "Personal Information: We collect your phone number and blood group if you choose to provide them. These are used to connect users who may need to find people nearby with specific blood groups.",
//                   "Healthcare Information: We display details such as doctor names, available specialties, and working hours. This information is for reference only and is not a substitute for medical advice.",
//                 ],
//                 screenWidth: screenWidth,
//                 screenHeight: screenHeight,
//                 headingFontSize: headingFontSize,
//                 bodyFontSize: bodyFontSize,
//               ),

//               _buildSection(
//                 title: "How We Use Your Information",
//                 items: [
//                   "To provide healthcare directory services like showing doctors, specialties, and hospitals near you.",
//                   "To allow users to discover nearby people with specific blood groups for emergency support.",
//                   "To provide ambulance location details to help users in emergencies.",
//                   "To communicate with you if needed for support or service updates.",
//                 ],
//                 screenWidth: screenWidth,
//                 screenHeight: screenHeight,
//                 headingFontSize: headingFontSize,
//                 bodyFontSize: bodyFontSize,
//                 isBulletList: true,
//               ),

//               _buildSection(
//                 title: "Data Sharing and Disclosure",
//                 items: [
//                   "We do not sell or rent your personal information. Your information may only be shared:",
//                   "With nearby users (only blood group and location visibility, if you enable it).",
//                   "Authentication: We use Twilio to send OTPs for login. Twilio may temporarily process your phone number only for this purpose and does not use it for any other activity.",
//                   "When required by law or government authorities.",
//                   "With trusted service providers who help us operate our services, under strict confidentiality agreements.",
//                 ],
//                 screenWidth: screenWidth,
//                 screenHeight: screenHeight,
//                 headingFontSize: headingFontSize,
//                 bodyFontSize: bodyFontSize,
//                 isBulletList: true,
//               ),

//               _buildSection(
//                 title: "Data Security",
//                 items: [
//                   "We use industry-standard security measures to protect your information. However, no method of storage or transmission is 100% secure, and we cannot guarantee absolute security.",
//                 ],
//                 screenWidth: screenWidth,
//                 screenHeight: screenHeight,
//                 headingFontSize: headingFontSize,
//                 bodyFontSize: bodyFontSize,
//               ),

//               _buildSection(
//                 title: "Your Choices",
//                 items: [
//                   "You can disable location services at any time in your device settings, though some features may not function properly without it.",
//                   "Data Deletion Request: If you wish to delete your account or any personal data you have shared with us, you can send an email request to zorrowtech@gmail.com. We will permanently remove your data from our systems within 30 days of receiving your request.",
//                 ],
//                 screenWidth: screenWidth,
//                 screenHeight: screenHeight,
//                 headingFontSize: headingFontSize,
//                 bodyFontSize: bodyFontSize,
//               ),

//               _buildSection(
//                 title: "Children's Privacy",
//                 items: [
//                   "Our app is not intended for children under 13. We do not knowingly collect data from children.",
//                 ],
//                 screenWidth: screenWidth,
//                 screenHeight: screenHeight,
//                 headingFontSize: headingFontSize,
//                 bodyFontSize: bodyFontSize,
//               ),

//               _buildSection(
//                 title: "Disclaimer",
//                 items: [
//                   "The Hosta app provides healthcare directory information only and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of a qualified healthcare provider for medical concerns.",
//                 ],
//                 screenWidth: screenWidth,
//                 screenHeight: screenHeight,
//                 headingFontSize: headingFontSize,
//                 bodyFontSize: bodyFontSize,
//               ),

//               _buildSection(
//                 title: "Changes to this Privacy Policy",
//                 items: [
//                   "We may update this policy from time to time. Any changes will be posted on this page with the updated date.",
//                 ],
//                 screenWidth: screenWidth,
//                 screenHeight: screenHeight,
//                 headingFontSize: headingFontSize,
//                 bodyFontSize: bodyFontSize,
//               ),

//               // Contact Section with Green Highlight
//               _buildContactSection(
//                 screenWidth,
//                 screenHeight,
//                 headingFontSize,
//                 bodyFontSize,
//               ),

//               SizedBox(height: screenHeight * 0.04),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildIntroCard(String text, double screenWidth, double screenHeight, double fontSize) {
//     return Container(
//       padding: EdgeInsets.all(screenWidth * 0.04),
//       decoration: BoxDecoration(
//           color: Colors.green,
      
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//              color: Colors.green,
//             //color: Colors.green.withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           fontSize: fontSize,
//           color: Colors.white,
//           height: 1.6,
//           letterSpacing: 0.3,
//           fontWeight: FontWeight.w400,
//         ),
//       ),
//     );
//   }

//   Widget _buildSection({
//     required String title,
//     required List<String> items,
//     required double screenWidth,
//     required double screenHeight,
//     required double headingFontSize,
//     required double bodyFontSize,
//     bool isBulletList = false,
//   }) {
//     return Container(
//       margin: EdgeInsets.only(top: screenHeight * 0.025),
//       padding: EdgeInsets.all(screenWidth * 0.04),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.08),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 4,
//                 height: headingFontSize * 1.2,
//                 decoration: BoxDecoration(
//                 color: Colors.green,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               SizedBox(width: screenWidth * 0.02),
//               Text(
//                 title,
//                 style: TextStyle(
//                   fontSize: headingFontSize,
//                   fontWeight: FontWeight.w700,
//                   color: const Color(0xFF0F172A),
//                   letterSpacing: 0.3,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: screenHeight * 0.015),
//           ...items.map((item) => Padding(
//             padding: EdgeInsets.only(bottom: screenHeight * 0.01),
//             child: isBulletList 
//                 ? _buildBulletItem(item, screenWidth, screenHeight, bodyFontSize)
//                 : _buildParagraph(item, screenWidth, screenHeight, bodyFontSize),
//           )),
//         ],
//       ),
//     );
//   }

//   Widget _buildBulletItem(String text, double screenWidth, double screenHeight, double fontSize) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: EdgeInsets.only(top: screenHeight * 0.005),
//           child: Container(
//             width: 6,
//             height: 6,
//             decoration: const BoxDecoration(
//                color: Colors.green,
               
//               shape: BoxShape.circle,
//             ),
//           ),
//         ),
//         SizedBox(width: screenWidth * 0.025),
//         Expanded(
//           child: Text(
//             text,
//             style: TextStyle(
//               fontSize: fontSize,
//               color: const Color(0xFF334155),
//               height: 1.6,
//               letterSpacing: 0.3,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildParagraph(String text, double screenWidth, double screenHeight, double fontSize) {
//     return Text(
//       text,
//       style: TextStyle(
//         fontSize: fontSize,
//         color: const Color(0xFF334155),
//         height: 1.6,
//         letterSpacing: 0.3,
//       ),
//     );
//   }

//   Widget _buildContactSection(
//     double screenWidth,
//     double screenHeight,
//     double headingFontSize,
//     double bodyFontSize,
//   ) {
//     return Container(
//       margin: EdgeInsets.only(top: screenHeight * 0.025),
//       padding: EdgeInsets.all(screenWidth * 0.04),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.08),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 width: 4,
//                 height: headingFontSize * 1.2,
//                 decoration: BoxDecoration(
//                   color: Colors.green,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               SizedBox(width: screenWidth * 0.02),
//               Text(
//                 "Contact Us",
//                 style: TextStyle(
//                   fontSize: headingFontSize,
//                   fontWeight: FontWeight.w700,
//                   color: const Color(0xFF0F172A),
//                   letterSpacing: 0.3,
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: screenHeight * 0.015),
//           Text(
//             "If you have any questions or concerns about this Privacy Policy or your data, please contact us at:",
//             style: TextStyle(
//               fontSize: bodyFontSize,
//               color: const Color(0xFF334155),
//               height: 1.6,
//               letterSpacing: 0.3,
//             ),
//           ),
//           SizedBox(height: screenHeight * 0.015),
//           Container(
//             padding: EdgeInsets.all(screenWidth * 0.035),
//             decoration: BoxDecoration(
//               color: const Color(0xFFF0FDF4),
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(
//                 color: Colors.green,
//                 width: 1,
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildHighlightedText(
//                   "Zorrow Tech IT Solutions Pvtl Ltd",
//                   bodyFontSize,
//                 ),
//                 SizedBox(height: screenHeight * 0.008),
//                 _buildHighlightedText(
//                   "zorrowtech@gmail.com",
//                   bodyFontSize,
//                   isEmail: true,
//                 ),
//                 SizedBox(height: screenHeight * 0.008),
//                 _buildHighlightedText(
//                   "+91-9400517720",
//                   bodyFontSize,
//                   isPhone: true,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHighlightedText(
//     String text,
//     double fontSize, {
//     bool isEmail = false,
//     bool isPhone = false,
//   }) {
//     return Row(
//       children: [
//         if (isEmail)
//           Icon(
//             Icons.email_outlined,
//             size: fontSize * 1.2,
//             color: Colors.green,
//           ),
//         if (isPhone)
//           Icon(
//             Icons.phone_outlined,
//             size: fontSize * 1.2,
//             color: Colors.green,
//           ),
//         if (!isEmail && !isPhone)
//           Icon(
//             Icons.business_center_outlined,
//             size: fontSize * 1.2,
//             color:Colors.green,
//             // const Color(0xFF059669),
//           ),
//         SizedBox(width: fontSize * 0.5),
//         Text(
//           text,
//           style: TextStyle(
//             fontSize: fontSize,
//             fontWeight: FontWeight.w600,
//             color: Colors.green,
//             letterSpacing: 0.3,
//           ),
//         ),
//       ],
//     );
//   }
// }






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
    final double horizontalPadding = isSmallScreen 
        ? screenWidth * 0.05 
        : (isTablet ? screenWidth * 0.08 : screenWidth * 0.1);
    final double verticalPadding = screenHeight * 0.025;
    final double headingFontSize = isSmallScreen 
        ? screenWidth * 0.05 
        : (isTablet ? screenWidth * 0.035 : screenWidth * 0.028);
    final double bodyFontSize = isSmallScreen 
        ? screenWidth * 0.04 
        : (isTablet ? screenWidth * 0.028 : screenWidth * 0.022);
    final double appBarTitleSize = isSmallScreen 
        ? screenWidth * 0.045 
        : (isTablet ? screenWidth * 0.035 : screenWidth * 0.025);
    final double iconSize = isSmallScreen 
        ? screenWidth * 0.055 
        : (isTablet ? screenWidth * 0.04 : screenWidth * 0.03);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: Text(
          "Privacy Policy",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: appBarTitleSize,
            letterSpacing: 0.5,
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
        toolbarHeight: isSmallScreen 
            ? kToolbarHeight 
            : (isTablet 
                ? kToolbarHeight * 1.1 
                : kToolbarHeight * 1.2),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? screenWidth * 0.7 : screenWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Introduction Card
                _buildSection(
                  title: "Introduction",
                  items: [
                    "At Hosta, developed by Zorrow Tech IT Solutions, we respect your privacy and are committed to protecting the personal information you share with us. This Privacy Policy explains how we collect, use, and safeguard your data when you use our application."
                  ],
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  headingFontSize: headingFontSize,
                  bodyFontSize: bodyFontSize,
                  isIntro: true,
                ),
                
                SizedBox(height: screenHeight * 0.01),
                
                _buildSection(
                  title: "Information We Collect",
                  items: [
                    "Location Data: We access your location to show you the nearest doctors, specialties, hospitals, and ambulances.",
                    "Personal Information: We collect your phone number and blood group if you choose to provide them. These are used to connect users who may need to find people nearby with specific blood groups.",
                    "Healthcare Information: We display details such as doctor names, available specialties, and working hours. This information is for reference only and is not a substitute for medical advice.",
                  ],
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  headingFontSize: headingFontSize,
                  bodyFontSize: bodyFontSize,
                  isBulletList: false,
                ),

                _buildSection(
                  title: "How We Use Your Information",
                  items: [
                    "To provide healthcare directory services like showing doctors, specialties, and hospitals near you.",
                    "To allow users to discover nearby people with specific blood groups for emergency support.",
                    "To provide ambulance location details to help users in emergencies.",
                    "To communicate with you if needed for support or service updates.",
                  ],
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  headingFontSize: headingFontSize,
                  bodyFontSize: bodyFontSize,
                  isBulletList: true,
                ),

                _buildSection(
                  title: "Data Sharing and Disclosure",
                  items: [
                    "We do not sell or rent your personal information. Your information may only be shared:",
                    "With nearby users (only blood group and location visibility, if you enable it).",
                    "Authentication: We use Twilio to send OTPs for login. Twilio may temporarily process your phone number only for this purpose and does not use it for any other activity.",
                    "When required by law or government authorities.",
                    "With trusted service providers who help us operate our services, under strict confidentiality agreements.",
                  ],
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  headingFontSize: headingFontSize,
                  bodyFontSize: bodyFontSize,
                  isBulletList: true,
                ),

                _buildSection(
                  title: "Data Security",
                  items: [
                    "We use industry-standard security measures to protect your information. However, no method of storage or transmission is 100% secure, and we cannot guarantee absolute security.",
                  ],
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  headingFontSize: headingFontSize,
                  bodyFontSize: bodyFontSize,
                  isBulletList: false,
                ),

                _buildSection(
                  title: "Your Choices",
                  items: [
                    "You can disable location services at any time in your device settings, though some features may not function properly without it.",
                    "Data Deletion Request: If you wish to delete your account or any personal data you have shared with us, you can send an email request to zorrowtech@gmail.com. We will permanently remove your data from our systems within 30 days of receiving your request.",
                  ],
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  headingFontSize: headingFontSize,
                  bodyFontSize: bodyFontSize,
                  isBulletList: false,
                ),

                _buildSection(
                  title: "Children's Privacy",
                  items: [
                    "Our app is not intended for children under 13. We do not knowingly collect data from children.",
                  ],
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  headingFontSize: headingFontSize,
                  bodyFontSize: bodyFontSize,
                  isBulletList: false,
                ),

                _buildSection(
                  title: "Disclaimer",
                  items: [
                    "The Hosta app provides healthcare directory information only and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of a qualified healthcare provider for medical concerns.",
                  ],
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  headingFontSize: headingFontSize,
                  bodyFontSize: bodyFontSize,
                  isBulletList: false,
                ),

                _buildSection(
                  title: "Changes to this Privacy Policy",
                  items: [
                    "We may update this policy from time to time. Any changes will be posted on this page with the updated date.",
                  ],
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  headingFontSize: headingFontSize,
                  bodyFontSize: bodyFontSize,
                  isBulletList: false,
                ),

                // Contact Section with Green Highlight
                _buildContactSection(
                  screenWidth,
                  screenHeight,
                  headingFontSize,
                  bodyFontSize,
                ),

                SizedBox(height: screenHeight * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<String> items,
    required double screenWidth,
    required double screenHeight,
    required double headingFontSize,
    required double bodyFontSize,
    bool isBulletList = false,
    bool isIntro = false,
  }) {
    final isSmallScreen = screenWidth < 600;
    final sectionPadding = isSmallScreen 
        ? screenWidth * 0.04 
        : screenWidth * 0.035;
    
    return Container(
      margin: EdgeInsets.only(top: screenHeight * 0.025),
      padding: EdgeInsets.all(sectionPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: isSmallScreen ? 8 : 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmallScreen ? 4 : 5,
                height: headingFontSize * 1.2,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                title,
                style: TextStyle(
                  fontSize: headingFontSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          ...items.map((item) => Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.01),
            child: isBulletList 
                ? _buildBulletItem(item, screenWidth, screenHeight, bodyFontSize)
                : _buildParagraph(item, screenWidth, screenHeight, bodyFontSize, isIntro),
          )),
        ],
      ),
    );
  }

  Widget _buildBulletItem(
    String text, 
    double screenWidth, 
    double screenHeight, 
    double fontSize
  ) {
    final isSmallScreen = screenWidth < 600;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: screenHeight * 0.005),
          child: Container(
            width: isSmallScreen ? 6 : 7,
            height: isSmallScreen ? 6 : 7,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.025),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              color: const Color(0xFF334155),
              height: 1.6,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParagraph(
    String text, 
    double screenWidth, 
    double screenHeight, 
    double fontSize,
    bool isIntro,
  ) {
    final isSmallScreen = screenWidth < 600;
    
    if (isIntro) {
      return Container(
        padding: EdgeInsets.all(isSmallScreen 
            ? screenWidth * 0.04 
            : screenWidth * 0.035),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: isSmallScreen ? 10 : 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.white,
            height: 1.6,
            letterSpacing: 0.3,
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }
    
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        color: const Color(0xFF334155),
        height: 1.6,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildContactSection(
    double screenWidth,
    double screenHeight,
    double headingFontSize,
    double bodyFontSize,
  ) {
    final isSmallScreen = screenWidth < 600;
    final sectionPadding = isSmallScreen 
        ? screenWidth * 0.04 
        : screenWidth * 0.035;
    final iconSize = isSmallScreen 
        ? bodyFontSize * 1.2 
        : bodyFontSize * 1.4;
    
    return Container(
      margin: EdgeInsets.only(top: screenHeight * 0.025),
      padding: EdgeInsets.all(sectionPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: isSmallScreen ? 8 : 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmallScreen ? 4 : 5,
                height: headingFontSize * 1.2,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                "Contact Us",
                style: TextStyle(
                  fontSize: headingFontSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            "If you have any questions or concerns about this Privacy Policy or your data, please contact us at:",
            style: TextStyle(
              fontSize: bodyFontSize,
              color: const Color(0xFF334155),
              height: 1.6,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          Container(
            padding: EdgeInsets.all(isSmallScreen 
                ? screenWidth * 0.035 
                : screenWidth * 0.03),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 14),
              border: Border.all(
                color: Colors.green,
                width: isSmallScreen ? 1 : 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHighlightedText(
                  "Zorrow Tech IT Solutions Pvtl Ltd",
                  bodyFontSize,
                  icon: Icons.business_center_outlined,
                  iconSize: iconSize,
                ),
                SizedBox(height: screenHeight * 0.008),
                _buildHighlightedText(
                  "zorrowtech@gmail.com",
                  bodyFontSize,
                  icon: Icons.email_outlined,
                  iconSize: iconSize,
                ),
                SizedBox(height: screenHeight * 0.008),
                _buildHighlightedText(
                  "+91-9400517720",
                  bodyFontSize,
                  icon: Icons.phone_outlined,
                  iconSize: iconSize,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(
    String text,
    double fontSize, {
    required IconData icon,
    required double iconSize,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: iconSize,
          color: Colors.green,
        ),
        SizedBox(width: fontSize * 0.5),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Colors.green,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}