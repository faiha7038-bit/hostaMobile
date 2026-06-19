// // import 'package:flutter/material.dart';
// // import 'package:hosta/services/api_service.dart';
// // import 'package:url_launcher/url_launcher.dart';
// // import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// // class Contact extends StatefulWidget {
// //   const Contact({super.key});

// //   @override
// //   State<Contact> createState() => _ContactState();
// // }

// // class _ContactState extends State<Contact> {
// //   final TextEditingController nameController = TextEditingController();
// //   final TextEditingController emailController = TextEditingController();
// //   final TextEditingController messageController = TextEditingController();

// //   bool isSubmitting = false;
// //   String? statusMessage;
// //   bool isSuccess = false;

// //   final ApiService _apiService = ApiService();

// //   Future<void> _submitFeedback() async {
// //     // Validate fields
// //     if (nameController.text.isEmpty) {
// //       setState(() {
// //         statusMessage = "Please enter your name";
// //         isSuccess = false;
// //       });
// //       return;
// //     }
    
// //     if (emailController.text.isEmpty) {
// //       setState(() {
// //         statusMessage = "Please enter your email";
// //         isSuccess = false;
// //       });
// //       return;
// //     }
    
// //     if (!_isValidEmail(emailController.text)) {
// //       setState(() {
// //         statusMessage = "Please enter a valid email address";
// //         isSuccess = false;
// //       });
// //       return;
// //     }
    
// //     if (messageController.text.isEmpty) {
// //       setState(() {
// //         statusMessage = "Please enter your message";
// //         isSuccess = false;
// //       });
// //       return;
// //     }

// //     setState(() {
// //       isSubmitting = true;
// //       statusMessage = null;
// //     });

// //     try {
// //       // Create beautiful HTML email template
// //       String htmlContent = _buildEmailTemplate(
// //         name: nameController.text,
// //         email: emailController.text,
// //         message: messageController.text,
// //       );

// //       // Prepare data for API
// //       final emailData = {
// //         "from": emailController.text,
// //         "to": "hostahealthcare@gmail.com",
// //         "subject": "New Contact Form Message from ${nameController.text}",
// //         "text": htmlContent, // Send HTML content
// //       };

// //       // Send email using your API endpoint
// //       final response = await _apiService.sendEmail(emailData);

// //       if (response.statusCode == 200) {
// //         setState(() {
// //           statusMessage = "✅ Thank you for contacting us! We'll get back to you soon.";
// //           isSuccess = true;
// //           nameController.clear();
// //           emailController.clear();
// //           messageController.clear();
// //         });
// //       } else {
// //         setState(() {
// //           statusMessage = "❌ Failed to send message. Please try again.";
// //           isSuccess = false;
// //         });
// //       }
// //     } catch (e) {
// //       setState(() {
// //         statusMessage = "⚠️ Network error. Please check your connection.";
// //         isSuccess = false;
// //       });
// //     }

// //     setState(() {
// //       isSubmitting = false;
// //     });
// //   }

// //   // Email validation
// //   bool _isValidEmail(String email) {
// //     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
// //   }

// //   // Beautiful HTML email template
// //   String _buildEmailTemplate({
// //     required String name,
// //     required String email,
// //     required String message,
// //   }) {
// //     return '''
// //     <!DOCTYPE html>
// //     <html>
// //     <head>
// //       <meta charset="UTF-8">
// //       <meta name="viewport" content="width=device-width, initial-scale=1.0">
// //     </head>
// //     <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4;">
// //       <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #f4f4f4; padding: 20px;">
// //         <tr>
// //           <td align="center">
// //             <table width="600" cellpadding="0" cellspacing="0" border="0" style="background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
              
// //               <!-- Header with Green Background -->
// //               <tr>
// //                 <td style="background: linear-gradient(135deg, #43a047 0%, #2e7d32 100%); padding: 30px 20px; text-align: center;">
// //                   <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 600;">Hosta Healthcare</h1>
// //                   <p style="color: #e8f5e9; margin: 10px 0 0 0; font-size: 16px;">New Contact Form Submission</p>
// //                 </td>
// //               </tr>
              
// //               <!-- Content -->
// //               <tr>
// //                 <td style="padding: 40px 30px;">
// //                   <!-- Greeting -->
// //                   <p style="color: #2e7d32; font-size: 18px; margin: 0 0 20px 0; font-weight: 500;">👋 You have a new message!</p>
                  
// //                   <!-- Sender Details Card -->
// //                   <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #f1f8e9; border-radius: 10px; margin-bottom: 25px; border-left: 4px solid #43a047;">
// //                     <tr>
// //                       <td style="padding: 20px;">
// //                         <h3 style="color: #2e7d32; margin: 0 0 15px 0; font-size: 18px; font-weight: 600;">📋 Sender Information</h3>
// //                         <table width="100%" cellpadding="5" cellspacing="0" border="0">
// //                           <tr>
// //                             <td width="100" style="color: #558b2f; font-weight: 500;">Name:</td>
// //                             <td style="color: #333333; font-weight: 500;">$name</td>
// //                           </tr>
// //                           <tr>
// //                             <td style="color: #558b2f; font-weight: 500;">Email:</td>
// //                             <td style="color: #333333;">
// //                               <a href="mailto:$email" style="color: #43a047; text-decoration: none; font-weight: 500;">$email</a>
// //                             </td>
// //                           </tr>
// //                         </table>
// //                       </td>
// //                     </tr>
// //                   </table>
                  
// //                   <!-- Message Card -->
// //                   <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #ffffff; border-radius: 10px; margin-bottom: 25px; border: 1px solid #e0e0e0;">
// //                     <tr>
// //                       <td style="padding: 20px;">
// //                         <h3 style="color: #2e7d32; margin: 0 0 15px 0; font-size: 18px; font-weight: 600;">💬 Message</h3>
// //                         <p style="color: #555555; line-height: 1.6; margin: 0; font-size: 15px; background-color: #fafafa; padding: 15px; border-radius: 8px; border-left: 3px solid #43a047;">
// //                           ${message.replaceAll('\n', '<br>')}
// //                         </p>
// //                       </td>
// //                     </tr>
// //                   </table>
                  
// //                   <!-- Reply Button -->
// //                   <table width="100%" cellpadding="0" cellspacing="0" border="0">
// //                     <tr>
// //                       <td align="center">
// //                         <a href="mailto:$email?subject=Re: Your message to Hosta Healthcare" style="display: inline-block; background: linear-gradient(135deg, #43a047 0%, #2e7d32 100%); color: #ffffff; text-decoration: none; padding: 12px 30px; border-radius: 25px; font-weight: 500; font-size: 16px; margin: 10px 0;">
// //                           ↩️ Reply to $name
// //                         </a>
// //                       </td>
// //                     </tr>
// //                   </table>
// //                 </td>
// //               </tr>
              
// //               <!-- Footer -->
// //               <tr>
// //                 <td style="background-color: #f1f8e9; padding: 20px 30px; text-align: center; border-top: 1px solid #c8e6c9;">
// //                   <p style="color: #558b2b; margin: 0 0 10px 0; font-size: 14px;">This message was sent from the Hosta Healthcare contact form.</p>
// //                   <p style="color: #558b2b; margin: 0; font-size: 13px;">© ${DateTime.now().year} Hosta Healthcare. All rights reserved.</p>
// //                 </td>
// //               </tr>
// //             </table>
// //           </td>
// //         </tr>
// //       </table>
// //     </body>
// //     </html>
// //     ''';
// //   }

// //   Future<void> _openUrl(String url) async {
// //     final uri = Uri.parse(url);
// //     if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text("Could not open $url"),
// //             backgroundColor: Colors.red,
// //           ),
// //         );
// //       }
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final screenSize = MediaQuery.of(context).size;
// //     final screenHeight = screenSize.height;
// //     final screenWidth = screenSize.width;
// //     final isSmallScreen = screenWidth < 600;
// //     final isTablet = screenWidth >= 600 && screenWidth < 1200;
// //     final isDesktop = screenWidth >= 1200;
    
// //     // Responsive padding
// //     final horizontalPadding = isDesktop ? screenWidth * 0.1 : (isTablet ? screenWidth * 0.05 : screenWidth * 0.04);
// //     final cardPadding = isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.06;
// //     final fontSize = isSmallScreen ? screenWidth * 0.05 : (isTablet ? screenWidth * 0.055 : screenWidth * 0.06);
// //     final buttonHeight = isSmallScreen ? screenHeight * 0.068 : screenHeight * 0.073;
    
// //     return Scaffold(
// //       backgroundColor: const Color(0xFFECFDF5),
// //       appBar: AppBar(
// //         backgroundColor: Colors.green,
// //         elevation: 2,
// //         toolbarHeight: isSmallScreen ? kToolbarHeight : (isTablet ? 64 : 72),
// //         title: Text(
// //           "Contact Us",
// //           style: TextStyle(
// //             color: Colors.white,
// //             fontWeight: FontWeight.w600,
// //             fontSize: isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.055,
// //           ),
// //         ),
// //         leading: IconButton(
// //           icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.06),
// //           onPressed: () => Navigator.pop(context),
// //         ),
// //         centerTitle: true,
// //       ),
// //       body: SingleChildScrollView(
// //         padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: screenHeight * 0.02),
// //         child: Column(
// //           children: [
// //             _buildCard(
// //               screenWidth: screenWidth,
// //               screenHeight: screenHeight,
// //               isSmallScreen: isSmallScreen,
// //               cardPadding: cardPadding,
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     "Send Us a Message",
// //                     style: TextStyle(
// //                       fontSize: fontSize,
// //                       fontWeight: FontWeight.w600,
// //                       color: Colors.green,
// //                     ),
// //                   ),
// //                   SizedBox(height: isSmallScreen ? screenHeight * 0.015 : screenHeight * 0.02),
                  
// //                   // Name Field
// //                   _buildInputField(
// //                     label: "Your Name *",
// //                     controller: nameController,
// //                     hint: "Enter your full name",
// //                     icon: Icons.person_outline,
// //                     isSmallScreen: isSmallScreen,
// //                     screenWidth: screenWidth,
// //                     screenHeight: screenHeight,
// //                   ),
                  
// //                   // Email Field
// //                   _buildInputField(
// //                     label: "Email Address *",
// //                     controller: emailController,
// //                     hint: "Enter your email",
// //                     keyboardType: TextInputType.emailAddress,
// //                     icon: Icons.email_outlined,
// //                     isSmallScreen: isSmallScreen,
// //                     screenWidth: screenWidth,
// //                     screenHeight: screenHeight,
// //                   ),
                  
// //                   // Message Field
// //                   _buildInputField(
// //                     label: "Your Message *",
// //                     controller: messageController,
// //                     hint: "How can we help you?",
// //                     maxLines: 5,
// //                     icon: Icons.message_outlined,
// //                     isSmallScreen: isSmallScreen,
// //                     screenWidth: screenWidth,
// //                     screenHeight: screenHeight,
// //                   ),
                  
// //                   SizedBox(height: isSmallScreen ? screenHeight * 0.02 : screenHeight * 0.025),
                  
// //                   // Submit Button
// //                   SizedBox(
// //                     width: double.infinity,
// //                     height: buttonHeight,
// //                     child: ElevatedButton(
// //                       onPressed: isSubmitting ? null : _submitFeedback,
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: Colors.green,
// //                         foregroundColor: Colors.white,
// //                         shape: RoundedRectangleBorder(
// //                           borderRadius: BorderRadius.circular(screenWidth * 0.025),
// //                         ),
// //                         elevation: 2,
// //                       ),
// //                       child: isSubmitting
// //                           ? SizedBox(
// //                               height: isSmallScreen ? screenWidth * 0.06 : screenWidth * 0.07,
// //                               width: isSmallScreen ? screenWidth * 0.06 : screenWidth * 0.07,
// //                               child: const CircularProgressIndicator(
// //                                 strokeWidth: 2,
// //                                 color: Colors.white,
// //                               ),
// //                             )
// //                           : Row(
// //                               mainAxisAlignment: MainAxisAlignment.center,
// //                               children: [
// //                                 Icon(Icons.send, color: Colors.white, size: isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.055),
// //                                 SizedBox(width: screenWidth * 0.02),
// //                                 Text(
// //                                   "Send Message",
// //                                   style: TextStyle(
// //                                     fontWeight: FontWeight.bold,
// //                                     fontSize: isSmallScreen ? screenWidth * 0.04 : screenWidth * 0.045,
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                     ),
// //                   ),
                  
// //                   // Status Message
// //                   if (statusMessage != null) ...[
// //                     SizedBox(height: isSmallScreen ? screenHeight * 0.015 : screenHeight * 0.02),
// //                     Container(
// //                       padding: EdgeInsets.all(isSmallScreen ? screenWidth * 0.03 : screenWidth * 0.035),
// //                       decoration: BoxDecoration(
// //                         color: isSuccess 
// //                             ? Colors.green.withOpacity(0.1) 
// //                             : Colors.red.withOpacity(0.1),
// //                         borderRadius: BorderRadius.circular(screenWidth * 0.02),
// //                         border: Border.all(
// //                           color: isSuccess ? Colors.green : Colors.red,
// //                           width: screenWidth * 0.0025,
// //                         ),
// //                       ),
// //                       child: Row(
// //                         children: [
// //                           Icon(
// //                             isSuccess ? Icons.check_circle : Icons.error,
// //                             color: isSuccess ? Colors.green : Colors.red,
// //                             size: isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.055,
// //                           ),
// //                           SizedBox(width: screenWidth * 0.02),
// //                           Expanded(
// //                             child: Text(
// //                               statusMessage!,
// //                               style: TextStyle(
// //                                 color: isSuccess ? Colors.green : Colors.red,
// //                                 fontWeight: FontWeight.w500,
// //                                 fontSize: isSmallScreen ? screenWidth * 0.035 : screenWidth * 0.0375,
// //                               ),
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                   ]
// //                 ],
// //               ),
// //             ),

// //             // Social Media Section
// //             _buildCard(
// //               screenWidth: screenWidth,
// //               screenHeight: screenHeight,
// //               isSmallScreen: isSmallScreen,
// //               cardPadding: cardPadding,
// //               child: Column(
// //                 children: [
// //                   Text(
// //                     "Get in Touch",
// //                     style: TextStyle(
// //                       fontSize: fontSize,
// //                       fontWeight: FontWeight.w600,
// //                       color: Colors.green,
// //                     ),
// //                   ),
// //                   SizedBox(height: isSmallScreen ? screenHeight * 0.025 : screenHeight * 0.03),
                  
// //                   // Contact Info
// //                   Container(
// //                     padding: EdgeInsets.all(isSmallScreen ? screenWidth * 0.0375 : screenWidth * 0.045),
// //                     decoration: BoxDecoration(
// //                       color: const Color(0xFFF1F8E9),
// //                       borderRadius: BorderRadius.circular(screenWidth * 0.025),
// //                     ),
// //                     child: Row(
// //                       mainAxisAlignment: MainAxisAlignment.center,
// //                       children: [
// //                         Icon(Icons.email, color: Colors.green, size: isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.055),
// //                         SizedBox(width: screenWidth * 0.02),
// //                         Text(
// //                           "hostahealthcare@gmail.com",
// //                           style: TextStyle(
// //                             fontSize: isSmallScreen ? screenWidth * 0.035 : screenWidth * 0.04,
// //                             fontWeight: FontWeight.w500,
// //                           ),
// //                         ),
// //                       ],
// //                     ),
// //                   ),
                  
// //                   SizedBox(height: isSmallScreen ? screenHeight * 0.025 : screenHeight * 0.03),
                  
// //                   // Social Icons - Responsive layout
// //                   LayoutBuilder(
// //                     builder: (context, constraints) {
// //                       return Wrap(
// //                         spacing: isSmallScreen ? screenWidth * 0.05 : (isTablet ? screenWidth * 0.075 : screenWidth * 0.1),
// //                         runSpacing: screenHeight * 0.02,
// //                         alignment: WrapAlignment.center,
// //                         children: [
// //                           _buildSocialButton(
// //                             icon: Icons.phone,
// //                             label: "Call",
// //                             onTap: () => _openUrl("tel:8714412090"),
// //                             isSmallScreen: isSmallScreen,
// //                             screenWidth: screenWidth,
// //                             screenHeight: screenHeight,
// //                           ),
// //                           _buildSocialButton(
// //                             icon: FontAwesomeIcons.whatsapp,
// //                             label: "WhatsApp",
// //                             isFaIcon: true,
// //                             onTap: () => _openUrl("https://wa.me/918714412090"),
// //                             isSmallScreen: isSmallScreen,
// //                             screenWidth: screenWidth,
// //                             screenHeight: screenHeight,
// //                           ),
// //                           _buildSocialButton(
// //                             icon: FontAwesomeIcons.facebook,
// //                             label: "Facebook",
// //                             isFaIcon: true,
// //                             onTap: () => _openUrl("https://www.facebook.com/profile.php?id=61568947746890&mibextid=LQQJ4d"),
// //                             isSmallScreen: isSmallScreen,
// //                             screenWidth: screenWidth,
// //                             screenHeight: screenHeight,
// //                           ),
// //                           _buildSocialButton(
// //                             icon: FontAwesomeIcons.instagram,
// //                             label: "Instagram",
// //                             isFaIcon: true,
// //                             onTap: () => _openUrl("https://www.instagram.com/hosta_healthcare/?igsh=MnR6d3h0YTJlbXEy"),
// //                             isSmallScreen: isSmallScreen,
// //                             screenWidth: screenWidth,
// //                             screenHeight: screenHeight,
// //                           ),
// //                           _buildSocialButton(
// //                             icon: Icons.email,
// //                             label: "Email",
// //                             onTap: () => _openUrl("mailto:hostahealthcare@gmail.com?subject=Inquiry&body=Hello Hosta,"),
// //                             isSmallScreen: isSmallScreen,
// //                             screenWidth: screenWidth,
// //                             screenHeight: screenHeight,
// //                           ),
// //                         ],
// //                       );
// //                     },
// //                   ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildSocialButton({
// //     required dynamic icon,
// //     required String label,
// //     required VoidCallback onTap,
// //     bool isFaIcon = false,
// //     required bool isSmallScreen,
// //     required double screenWidth,
// //     required double screenHeight,
// //   }) {
// //     final buttonSize = isSmallScreen ? screenWidth * 0.125 : screenWidth * 0.1375;
// //     final iconSize = isSmallScreen ? screenWidth * 0.06 : screenWidth * 0.07;
// //     final fontSize = isSmallScreen ? screenWidth * 0.0275 : screenWidth * 0.03;
    
// //     return Column(
// //       mainAxisSize: MainAxisSize.min,
// //       children: [
// //         InkWell(
// //           onTap: onTap,
// //           borderRadius: BorderRadius.circular(screenWidth * 0.075),
// //           child: Container(
// //             width: buttonSize,
// //             height: buttonSize,
// //             decoration: BoxDecoration(
// //               color: Colors.green.withOpacity(0.1),
// //               shape: BoxShape.circle,
// //             ),
// //             child: Center(
// //               child: isFaIcon
// //                   ? FaIcon(icon, color: Colors.green, size: iconSize)
// //                   : Icon(icon, color: Colors.green, size: iconSize),
// //             ),
// //           ),
// //         ),
// //         SizedBox(height: screenHeight * 0.005),
// //         Text(
// //           label,
// //           style: TextStyle(fontSize: fontSize),
// //         ),
// //       ],
// //     );
// //   }

// //   Widget _buildCard({
// //     required Widget child,
// //     required double screenWidth,
// //     required double screenHeight,
// //     required bool isSmallScreen,
// //     required double cardPadding,
// //   }) {
// //     final maxWidth = screenWidth > 800 ? 800.0 : double.infinity;
    
// //     return Center(
// //       child: Container(
// //         width: maxWidth,
// //         margin: EdgeInsets.only(bottom: screenHeight * 0.02),
// //         padding: EdgeInsets.all(cardPadding),
// //         decoration: BoxDecoration(
// //           color: Colors.white,
// //           borderRadius: BorderRadius.circular(screenWidth * 0.04),
// //           boxShadow: [
// //             BoxShadow(
// //               color: Colors.green.withOpacity(0.1),
// //               blurRadius: screenWidth * 0.025,
// //               offset: const Offset(0, 4),
// //             )
// //           ],
// //         ),
// //         child: child,
// //       ),
// //     );
// //   }

// //   Widget _buildInputField({
// //     required String label,
// //     required TextEditingController controller,
// //     String? hint,
// //     TextInputType? keyboardType,
// //     int maxLines = 1,
// //     required IconData icon,
// //     required bool isSmallScreen,
// //     required double screenWidth,
// //     required double screenHeight,
// //   }) {
// //     final fontSize = isSmallScreen ? screenWidth * 0.0375 : screenWidth * 0.04;
// //     final padding = isSmallScreen ? screenWidth * 0.03 : screenWidth * 0.035;
// //     final iconSize = isSmallScreen ? screenWidth * 0.05 : screenWidth * 0.055;
    
// //     return Padding(
// //       padding: EdgeInsets.only(bottom: screenHeight * 0.02),
// //       child: Column(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           Text(
// //             label,
// //             style: TextStyle(
// //               fontWeight: FontWeight.w500,
// //               color: Colors.green,
// //               fontSize: fontSize,
// //             ),
// //           ),
// //           SizedBox(height: screenHeight * 0.0075),
// //           TextField(
// //             controller: controller,
// //             keyboardType: keyboardType,
// //             maxLines: maxLines,
// //             textInputAction: maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
// //             style: TextStyle(fontSize: fontSize),
// //             decoration: InputDecoration(
// //               hintText: hint,
// //               hintStyle: TextStyle(fontSize: fontSize - (screenWidth * 0.0025)),
// //               prefixIcon: Icon(icon, color: Colors.green, size: iconSize),
// //               filled: true,
// //               fillColor: const Color(0xFFF8FAFC),
// //               contentPadding: EdgeInsets.symmetric(
// //                 horizontal: padding,
// //                 vertical: maxLines > 1 ? screenHeight * 0.02 : padding,
// //               ),
// //               border: OutlineInputBorder(
// //                 borderRadius: BorderRadius.circular(screenWidth * 0.025),
// //                 borderSide: BorderSide.none,
// //               ),
// //               enabledBorder: OutlineInputBorder(
// //                 borderRadius: BorderRadius.circular(screenWidth * 0.025),
// //                 borderSide: BorderSide.none,
// //               ),
// //               focusedBorder: OutlineInputBorder(
// //                 borderRadius: BorderRadius.circular(screenWidth * 0.025),
// //                 borderSide: const BorderSide(color: Colors.green, width: 1.5),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';
// import 'package:hosta/services/api_service.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// class Contact extends StatefulWidget {
//   const Contact({super.key});

//   @override
//   State<Contact> createState() => _ContactState();
// }

// class _ContactState extends State<Contact> with SingleTickerProviderStateMixin {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController messageController = TextEditingController();

//   bool isSubmitting = false;
//   String? statusMessage;
//   bool isSuccess = false;

//   final ApiService _apiService = ApiService();
//   late AnimationController _animationController;

//   // Focus nodes for better keyboard handling
//   final FocusNode _nameFocus = FocusNode();
//   final FocusNode _emailFocus = FocusNode();
//   final FocusNode _messageFocus = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _nameFocus.dispose();
//     _emailFocus.dispose();
//     _messageFocus.dispose();
//     nameController.dispose();
//     emailController.dispose();
//     messageController.dispose();
//     super.dispose();
//   }

//   Future<void> _submitFeedback() async {
//     // Validate fields with improved error messages
//     if (nameController.text.trim().isEmpty) {
//       _showError("Please enter your name");
//       return;
//     }
    
//     if (emailController.text.trim().isEmpty) {
//       _showError("Please enter your email address");
//       return;
//     }
    
//     if (!_isValidEmail(emailController.text.trim())) {
//       _showError("Please enter a valid email address");
//       return;
//     }
    
//     if (messageController.text.trim().isEmpty) {
//       _showError("Please enter your message");
//       return;
//     }

//     setState(() {
//       isSubmitting = true;
//       statusMessage = null;
//     });

//     try {
//       String htmlContent = _buildEmailTemplate(
//         name: nameController.text.trim(),
//         email: emailController.text.trim(),
//         message: messageController.text.trim(),
//       );

//       final emailData = {
//         "from": emailController.text.trim(),
//         "to": "hostahealthcare@gmail.com",
//         "subject": "New Contact Form Message from ${nameController.text.trim()}",
//         "text": htmlContent,
//       };

//       final response = await _apiService.sendEmail(emailData);

//       if (response.statusCode == 200) {
//         setState(() {
//           statusMessage = "✅ Thank you for contacting us! We'll get back to you soon.";
//           isSuccess = true;
//           nameController.clear();
//           emailController.clear();
//           messageController.clear();
//         });
//         _showSuccessSnackBar();
//       } else {
//         setState(() {
//           statusMessage = "❌ Failed to send message. Please try again.";
//           isSuccess = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         statusMessage = "⚠️ Network error. Please check your connection.";
//         isSuccess = false;
//       });
//     }

//     setState(() {
//       isSubmitting = false;
//     });
//   }

//   void _showError(String message) {
//     setState(() {
//       statusMessage = message;
//       isSuccess = false;
//     });
//   }

//   void _showSuccessSnackBar() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text('Message sent successfully! 🎉'),
//         backgroundColor: Colors.green.shade700,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         duration: const Duration(seconds: 3),
//         action: SnackBarAction(
//           label: 'OK',
//           textColor: Colors.white,
//           onPressed: () {},
//         ),
//       ),
//     );
//   }

//   bool _isValidEmail(String email) {
//     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
//   }

//   String _buildEmailTemplate({
//     required String name,
//     required String email,
//     required String message,
//   }) {
//     return '''
//     <!DOCTYPE html>
//     <html>
//     <head>
//       <meta charset="UTF-8">
//       <meta name="viewport" content="width=device-width, initial-scale=1.0">
//     </head>
//     <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4;">
//       <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #f4f4f4; padding: 20px;">
//         <tr>
//           <td align="center">
//             <table width="600" cellpadding="0" cellspacing="0" border="0" style="background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
              
//               <!-- Header with Gradient -->
//               <tr>
//                 <td style="background: linear-gradient(135deg, #43a047 0%, #2e7d32 100%); padding: 30px 20px; text-align: center;">
//                   <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 600;">Hosta Healthcare</h1>
//                   <p style="color: #e8f5e9; margin: 10px 0 0 0; font-size: 16px;">New Contact Form Submission</p>
//                 </td>
//               </tr>
              
//               <!-- Content -->
//               <tr>
//                 <td style="padding: 40px 30px;">
//                   <p style="color: #2e7d32; font-size: 18px; margin: 0 0 20px 0; font-weight: 500;">👋 You have a new message!</p>
                  
//                   <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #f1f8e9; border-radius: 10px; margin-bottom: 25px; border-left: 4px solid #43a047;">
//                     <tr>
//                       <td style="padding: 20px;">
//                         <h3 style="color: #2e7d32; margin: 0 0 15px 0; font-size: 18px; font-weight: 600;">📋 Sender Information</h3>
//                         <table width="100%" cellpadding="5" cellspacing="0" border="0">
//                           <tr>
//                             <td width="100" style="color: #558b2f; font-weight: 500;">Name:</td>
//                             <td style="color: #333333; font-weight: 500;">$name</td>
//                           </tr>
//                           <tr>
//                             <td style="color: #558b2f; font-weight: 500;">Email:</td>
//                             <td style="color: #333333;">
//                               <a href="mailto:$email" style="color: #43a047; text-decoration: none; font-weight: 500;">$email</a>
//                             </td>
//                           </tr>
//                         </table>
//                       </td>
//                     </tr>
//                   </table>
                  
//                   <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #ffffff; border-radius: 10px; margin-bottom: 25px; border: 1px solid #e0e0e0;">
//                     <tr>
//                       <td style="padding: 20px;">
//                         <h3 style="color: #2e7d32; margin: 0 0 15px 0; font-size: 18px; font-weight: 600;">💬 Message</h3>
//                         <p style="color: #555555; line-height: 1.6; margin: 0; font-size: 15px; background-color: #fafafa; padding: 15px; border-radius: 8px; border-left: 3px solid #43a047;">
//                           ${message.replaceAll('\n', '<br>')}
//                         </p>
//                       </td>
//                     </tr>
//                   </table>
                  
//                   <table width="100%" cellpadding="0" cellspacing="0" border="0">
//                     <tr>
//                       <td align="center">
//                         <a href="mailto:$email?subject=Re: Your message to Hosta Healthcare" style="display: inline-block; background: linear-gradient(135deg, #43a047 0%, #2e7d32 100%); color: #ffffff; text-decoration: none; padding: 12px 30px; border-radius: 25px; font-weight: 500; font-size: 16px; margin: 10px 0;">
//                           ↩️ Reply to $name
//                         </a>
//                       </td>
//                     </tr>
//                   </table>
//                 </td>
//               </tr>
              
//               <tr>
//                 <td style="background-color: #f1f8e9; padding: 20px 30px; text-align: center; border-top: 1px solid #c8e6c9;">
//                   <p style="color: #558b2b; margin: 0 0 10px 0; font-size: 14px;">This message was sent from the Hosta Healthcare contact form.</p>
//                   <p style="color: #558b2b; margin: 0; font-size: 13px;">© ${DateTime.now().year} Hosta Healthcare. All rights reserved.</p>
//                 </td>
//               </tr>
//             </table>
//           </td>
//         </tr>
//       </table>
//     </body>
//     </html>
//     ''';
//   }

//   Future<void> _openUrl(String url) async {
//     final uri = Uri.parse(url);
//     if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Could not open $url"),
//             backgroundColor: Colors.red,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     final isSmallScreen = screenSize.width < 600;
//     final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
//     final isDesktop = screenSize.width >= 1200;
    
//     final horizontalPadding = isDesktop ? screenSize.width * 0.15 : (isTablet ? screenSize.width * 0.08 : screenSize.width * 0.04);
//     final cardPadding = isSmallScreen ? screenSize.width * 0.05 : screenSize.width * 0.04;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: PreferredSize(
//         preferredSize: Size.fromHeight(isSmallScreen ? 60 : 70),
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Colors.green.shade700, Colors.green.shade400],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.green.withOpacity(0.3),
//                 blurRadius: 10,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: AppBar(
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             toolbarHeight: isSmallScreen ? 60 : 70,
//             title: Text(
//               "Contact Us",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w700,
//                 fontSize: isSmallScreen ? 20 : 24,
//                 letterSpacing: 0.5,
//               ),
//             ),
//             leading: IconButton(
//               icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
//               onPressed: () => Navigator.pop(context),
//               splashRadius: 24,
//             ),
//             centerTitle: true,
//           ),
//         ),
//       ),
//       body: FadeTransition(
//         opacity: _animationController,
//         child: SingleChildScrollView(
//           padding: EdgeInsets.symmetric(
//             horizontal: horizontalPadding,
//             vertical: screenSize.height * 0.02,
//           ),
//           child: Column(
//             children: [
//               // Hero Section
//               _buildHeroSection(screenSize, isSmallScreen),
              
//               const SizedBox(height: 20),
              
//               // Main Contact Card
//               _buildContactCard(screenSize, isSmallScreen, cardPadding),
              
//               const SizedBox(height: 20),
              
//               // Quick Contact Section
//               _buildQuickContactSection(screenSize, isSmallScreen),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeroSection(Size screenSize, bool isSmallScreen) {
//     return Container(
//       padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.green.shade50, Colors.green.shade100],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.green.shade200, width: 1),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "We're Here to Help!",
//                   style: TextStyle(
//                     fontSize: isSmallScreen ? 18 : 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green.shade800,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "Have questions or need assistance? Reach out to us and we'll get back to you within 24 hours.",
//                   style: TextStyle(
//                     fontSize: isSmallScreen ? 13 : 15,
//                     color: Colors.grey.shade700,
//                     height: 1.5,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.green.shade700,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(Icons.timer, color: Colors.white, size: 16),
//                       const SizedBox(width: 4),
//                       Text(
//                         "Response within 24 hrs",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: isSmallScreen ? 11 : 13,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (!isSmallScreen)
//             Container(
//               width: 80,
//               height: 80,
//               decoration: BoxDecoration(
//                 color: Colors.green.shade200,
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.support_agent,
//                 color: Colors.green,
//                 size: 40,
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildContactCard(Size screenSize, bool isSmallScreen, double cardPadding) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.shade200,
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//             spreadRadius: 5,
//           ),
//         ],
//       ),
//       padding: EdgeInsets.all(cardPadding),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade50,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(
//                   Icons.message_outlined,
//                   color: Colors.green.shade700,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Text(
//                 "Send a Message",
//                 style: TextStyle(
//                   fontSize: isSmallScreen ? 18 : 22,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.grey.shade900,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Fill in the details below and we'll get back to you soon.",
//             style: TextStyle(
//               fontSize: isSmallScreen ? 13 : 15,
//               color: Colors.grey.shade600,
//             ),
//           ),
//           const SizedBox(height: 24),
          
//           // Name Field
//           _buildModernInputField(
//             label: "Full Name",
//             controller: nameController,
//             hint: "Enter your full name",
//             icon: Icons.person_outline,
//             focusNode: _nameFocus,
//             isSmallScreen: isSmallScreen,
//             screenSize: screenSize,
//           ),
          
//           // Email Field
//           _buildModernInputField(
//             label: "Email Address",
//             controller: emailController,
//             hint: "Enter your email address",
//             icon: Icons.email_outlined,
//             keyboardType: TextInputType.emailAddress,
//             focusNode: _emailFocus,
//             isSmallScreen: isSmallScreen,
//             screenSize: screenSize,
//           ),
          
//           // Message Field
//           _buildModernInputField(
//             label: "Your Message",
//             controller: messageController,
//             hint: "How can we help you?",
//             icon: Icons.chat_bubble_outline,
//             maxLines: 5,
//             focusNode: _messageFocus,
//             isSmallScreen: isSmallScreen,
//             screenSize: screenSize,
//           ),
          
//           const SizedBox(height: 24),
          
//           // Submit Button
//           _buildSubmitButton(screenSize, isSmallScreen),
          
//           // Status Message
//           if (statusMessage != null) ...[
//             const SizedBox(height: 16),
//             _buildStatusMessage(isSmallScreen, screenSize),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildModernInputField({
//     required String label,
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     required FocusNode focusNode,
//     required bool isSmallScreen,
//     required Size screenSize,
//     TextInputType? keyboardType,
//     int maxLines = 1,
//   }) {
//     final isFocused = focusNode.hasFocus;
    
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: isSmallScreen ? 14 : 15,
//               color: Colors.grey.shade800,
//             ),
//           ),
//           const SizedBox(height: 6),
//           TextField(
//             controller: controller,
//             focusNode: focusNode,
//             keyboardType: keyboardType,
//             maxLines: maxLines,
//             textInputAction: maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
//             style: TextStyle(
//               fontSize: isSmallScreen ? 14 : 15,
//               color: Colors.grey.shade900,
//             ),
//             decoration: InputDecoration(
//               hintText: hint,
//               hintStyle: TextStyle(
//                 fontSize: isSmallScreen ? 13 : 14,
//                 color: Colors.grey.shade400,
//               ),
//               prefixIcon: Icon(icon, color: isFocused ? Colors.green.shade700 : Colors.grey.shade400, size: 20),
//               filled: true,
//               fillColor: isFocused ? Colors.green.shade50 : Colors.grey.shade50,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: maxLines > 1 ? 16 : 14,
//               ),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide.none,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(color: Colors.green.shade700, width: 2),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSubmitButton(Size screenSize, bool isSmallScreen) {
//     return SizedBox(
//       width: double.infinity,
//       height: isSmallScreen ? 52 : 56,
//       child: ElevatedButton(
//         onPressed: isSubmitting ? null : _submitFeedback,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.green.shade700,
//           foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//           elevation: 0,
//           disabledBackgroundColor: Colors.grey.shade300,
//         ),
//         child: isSubmitting
//             ? SizedBox(
//                 height: 24,
//                 width: 24,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2.5,
//                   color: Colors.white,
//                 ),
//               )
//             : Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.send, color: Colors.white, size: 20),
//                   const SizedBox(width: 10),
//                   Text(
//                     "Send Message",
//                     style: TextStyle(
//                       fontWeight: FontWeight.w700,
//                       fontSize: isSmallScreen ? 15 : 16,
//                       letterSpacing: 0.5,
//                     ),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }

//   Widget _buildStatusMessage(bool isSmallScreen, Size screenSize) {
//     return Container(
//       padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
//       decoration: BoxDecoration(
//         color: isSuccess 
//             ? Colors.green.shade50 
//             : Colors.red.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isSuccess ? Colors.green.shade200 : Colors.red.shade200,
//           width: 1,
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             isSuccess ? Icons.check_circle : Icons.error_outline,
//             color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
//             size: 22,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               statusMessage!,
//               style: TextStyle(
//                 color: isSuccess ? Colors.green.shade800 : Colors.red.shade800,
//                 fontWeight: FontWeight.w500,
//                 fontSize: isSmallScreen ? 13 : 14,
//                 height: 1.4,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickContactSection(Size screenSize, bool isSmallScreen) {
//     return Container(
//       padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.shade200,
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//             spreadRadius: 5,
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade50,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(
//                   Icons.phone_in_talk_outlined,
//                   color: Colors.green.shade700,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Text(
//                 "Quick Connect",
//                 style: TextStyle(
//                   fontSize: isSmallScreen ? 18 : 22,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.grey.shade900,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           Wrap(
//             spacing: isSmallScreen ? 8 : 16,
//             runSpacing: 12,
//             alignment: WrapAlignment.center,
//             children: [
//               _buildQuickContactButton(
//                 icon: FontAwesomeIcons.phone,
//                 label: "Call Us",
//                 color: Colors.blue.shade600,
//                 onTap: () => _openUrl("tel:8714412090"),
//                 isSmallScreen: isSmallScreen,
//               ),
//               _buildQuickContactButton(
//                 icon: FontAwesomeIcons.whatsapp,
//                 label: "WhatsApp",
//                 color: Colors.green.shade600,
//                 onTap: () => _openUrl("https://wa.me/918714412090"),
//                 isSmallScreen: isSmallScreen,
//               ),
//               _buildQuickContactButton(
//                 icon: FontAwesomeIcons.instagram,
//                 label: "Instagram",
//                 color: Colors.purple.shade600,
//                 onTap: () => _openUrl("https://www.instagram.com/hosta_healthcare/?igsh=MnR6d3h0YTJlbXEy"),
//                 isSmallScreen: isSmallScreen,
//               ),
//               _buildQuickContactButton(
//                 icon: FontAwesomeIcons.facebook,
//                 label: "Facebook",
//                 color: Colors.blue.shade700,
//                 onTap: () => _openUrl("https://www.facebook.com/profile.php?id=61568947746890&mibextid=LQQJ4d"),
//                 isSmallScreen: isSmallScreen,
//               ),
//               _buildQuickContactButton(
//                 icon: Icons.email,
//                 label: "Email",
//                 color: Colors.red.shade400,
//                 onTap: () => _openUrl("mailto:hostahealthcare@gmail.com?subject=Inquiry&body=Hello Hosta,"),
//                 isSmallScreen: isSmallScreen,
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.green.shade50,
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: Colors.green.shade200),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.email, color: Colors.green.shade700, size: 16),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     "hostahealthcare@gmail.com",
//                     style: TextStyle(
//                       fontSize: isSmallScreen ? 13 : 14,
//                       color: Colors.grey.shade800,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//                 if (!isSmallScreen)
//                   TextButton(
//                     onPressed: () => _openUrl("mailto:hostahealthcare@gmail.com"),
//                     child: const Text("Copy"),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuickContactButton({
//     required dynamic icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//     required bool isSmallScreen,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: EdgeInsets.symmetric(
//           horizontal: isSmallScreen ? 14 : 20,
//           vertical: isSmallScreen ? 10 : 12,
//         ),
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: color.withOpacity(0.2), width: 1),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               icon,
//               color: color,
//               size: isSmallScreen ? 18 : 20,
//             ),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: TextStyle(
//                 color: color,
//                 fontWeight: FontWeight.w600,
//                 fontSize: isSmallScreen ? 13 : 14,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
















// import 'package:flutter/material.dart';
// import 'package:hosta/services/api_service.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// class Contact extends StatefulWidget {
//   const Contact({super.key});

//   @override
//   State<Contact> createState() => _ContactState();
// }

// class _ContactState extends State<Contact> with SingleTickerProviderStateMixin {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController messageController = TextEditingController();

//   bool isSubmitting = false;
//   String? statusMessage;
//   bool isSuccess = false;

//   final ApiService _apiService = ApiService();
//   late AnimationController _animationController;

//   final FocusNode _nameFocus = FocusNode();
//   final FocusNode _emailFocus = FocusNode();
//   final FocusNode _messageFocus = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     _nameFocus.dispose();
//     _emailFocus.dispose();
//     _messageFocus.dispose();
//     nameController.dispose();
//     emailController.dispose();
//     messageController.dispose();
//     super.dispose();
//   }

//   Future<void> _submitFeedback() async {
//     if (nameController.text.trim().isEmpty) {
//       _showError("Please enter your name");
//       return;
//     }
    
//     if (emailController.text.trim().isEmpty) {
//       _showError("Please enter your email address");
//       return;
//     }
    
//     if (!_isValidEmail(emailController.text.trim())) {
//       _showError("Please enter a valid email address");
//       return;
//     }
    
//     if (messageController.text.trim().isEmpty) {
//       _showError("Please enter your message");
//       return;
//     }

//     setState(() {
//       isSubmitting = true;
//       statusMessage = null;
//     });

//     try {
//       String htmlContent = _buildEmailTemplate(
//         name: nameController.text.trim(),
//         email: emailController.text.trim(),
//         message: messageController.text.trim(),
//       );

//       final emailData = {
//         "from": emailController.text.trim(),
//         "to": "hostahealthcare@gmail.com",
//         "subject": "New Contact Form Message from ${nameController.text.trim()}",
//         "text": htmlContent,
//       };

//       final response = await _apiService.sendEmail(emailData);

//       if (response.statusCode == 200) {
//         setState(() {
//           statusMessage = "✅ Thank you for contacting us! We'll get back to you soon.";
//           isSuccess = true;
//           nameController.clear();
//           emailController.clear();
//           messageController.clear();
//         });
//         _showSuccessSnackBar();
//       } else {
//         setState(() {
//           statusMessage = "❌ Failed to send message. Please try again.";
//           isSuccess = false;
//         });
//       }
//     } catch (e) {
//       setState(() {
//         statusMessage = "⚠️ Network error. Please check your connection.";
//         isSuccess = false;
//       });
//     }

//     setState(() {
//       isSubmitting = false;
//     });
//   }

//   void _showError(String message) {
//     setState(() {
//       statusMessage = message;
//       isSuccess = false;
//     });
//   }

//   void _showSuccessSnackBar() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text('Message sent successfully! 🎉'),
//         backgroundColor: Colors.green.shade700,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         duration: const Duration(seconds: 3),
//         action: SnackBarAction(
//           label: 'OK',
//           textColor: Colors.white,
//           onPressed: () {},
//         ),
//       ),
//     );
//   }

//   bool _isValidEmail(String email) {
//     return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
//   }

//   String _buildEmailTemplate({
//     required String name,
//     required String email,
//     required String message,
//   }) {
//     return '''
//     <!DOCTYPE html>
//     <html>
//     <head>
//       <meta charset="UTF-8">
//       <meta name="viewport" content="width=device-width, initial-scale=1.0">
//     </head>
//     <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4;">
//       <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #f4f4f4; padding: 20px;">
//         <tr>
//           <td align="center">
//             <table width="600" cellpadding="0" cellspacing="0" border="0" style="background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
//               <tr>
//                 <td style="background: linear-gradient(135deg, #43a047 0%, #2e7d32 100%); padding: 30px 20px; text-align: center;">
//                   <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 600;">Hosta Healthcare</h1>
//                   <p style="color: #e8f5e9; margin: 10px 0 0 0; font-size: 16px;">New Contact Form Submission</p>
//                 </td>
//               </tr>
//               <tr>
//                 <td style="padding: 40px 30px;">
//                   <p style="color: #2e7d32; font-size: 18px; margin: 0 0 20px 0; font-weight: 500;">👋 You have a new message!</p>
//                   <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #f1f8e9; border-radius: 10px; margin-bottom: 25px; border-left: 4px solid #43a047;">
//                     <tr>
//                       <td style="padding: 20px;">
//                         <h3 style="color: #2e7d32; margin: 0 0 15px 0; font-size: 18px; font-weight: 600;">📋 Sender Information</h3>
//                         <table width="100%" cellpadding="5" cellspacing="0" border="0">
//                           <tr>
//                             <td width="100" style="color: #558b2f; font-weight: 500;">Name:</td>
//                             <td style="color: #333333; font-weight: 500;">$name</td>
//                           </tr>
//                           <tr>
//                             <td style="color: #558b2f; font-weight: 500;">Email:</td>
//                             <td style="color: #333333;">
//                               <a href="mailto:$email" style="color: #43a047; text-decoration: none; font-weight: 500;">$email</a>
//                             </td>
//                           </tr>
//                         </table>
//                       </td>
//                     </tr>
//                   </table>
//                   <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #ffffff; border-radius: 10px; margin-bottom: 25px; border: 1px solid #e0e0e0;">
//                     <tr>
//                       <td style="padding: 20px;">
//                         <h3 style="color: #2e7d32; margin: 0 0 15px 0; font-size: 18px; font-weight: 600;">💬 Message</h3>
//                         <p style="color: #555555; line-height: 1.6; margin: 0; font-size: 15px; background-color: #fafafa; padding: 15px; border-radius: 8px; border-left: 3px solid #43a047;">
//                           ${message.replaceAll('\n', '<br>')}
//                         </p>
//                       </td>
//                     </tr>
//                   </table>
//                   <table width="100%" cellpadding="0" cellspacing="0" border="0">
//                     <tr>
//                       <td align="center">
//                         <a href="mailto:$email?subject=Re: Your message to Hosta Healthcare" style="display: inline-block; background: linear-gradient(135deg, #43a047 0%, #2e7d32 100%); color: #ffffff; text-decoration: none; padding: 12px 30px; border-radius: 25px; font-weight: 500; font-size: 16px; margin: 10px 0;">
//                           ↩️ Reply to $name
//                         </a>
//                       </td>
//                     </tr>
//                   </table>
//                 </td>
//               </tr>
//               <tr>
//                 <td style="background-color: #f1f8e9; padding: 20px 30px; text-align: center; border-top: 1px solid #c8e6c9;">
//                   <p style="color: #558b2b; margin: 0 0 10px 0; font-size: 14px;">This message was sent from the Hosta Healthcare contact form.</p>
//                   <p style="color: #558b2b; margin: 0; font-size: 13px;">© ${DateTime.now().year} Hosta Healthcare. All rights reserved.</p>
//                 </td>
//               </tr>
//             </table>
//           </td>
//         </tr>
//       </table>
//     </body>
//     </html>
//     ''';
//   }

//   Future<void> _openUrl(String url) async {
//     final uri = Uri.parse(url);
//     if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Could not open $url"),
//             backgroundColor: Colors.red,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenSize = MediaQuery.of(context).size;
//     final isSmallScreen = screenSize.width < 600;
//     final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
//     final isDesktop = screenSize.width >= 1200;
    
//     final horizontalPadding = isDesktop ? screenSize.width * 0.15 : (isTablet ? screenSize.width * 0.08 : screenSize.width * 0.04);
//     final cardPadding = isSmallScreen ? screenSize.width * 0.05 : screenSize.width * 0.04;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       appBar: PreferredSize(
//         preferredSize: Size.fromHeight(isSmallScreen ? 60 : 70),
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Colors.green.shade700, Colors.green.shade500],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.green.withOpacity(0.3),
//                 blurRadius: 10,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: AppBar(
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             toolbarHeight: isSmallScreen ? 60 : 70,
//             title: Text(
//               "Contact Us",
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w700,
//                 fontSize: isSmallScreen ? 20 : 24,
//                 letterSpacing: 0.5,
//               ),
//             ),
//             leading: IconButton(
//               icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
//               onPressed: () => Navigator.pop(context),
//               splashRadius: 24,
//             ),
//             centerTitle: true,
//           ),
//         ),
//       ),
//       body: FadeTransition(
//         opacity: _animationController,
//         child: SingleChildScrollView(
//           padding: EdgeInsets.symmetric(
//             horizontal: horizontalPadding,
//             vertical: screenSize.height * 0.02,
//           ),
//           child: Column(
//             children: [
//               // Hero Section
//               _buildHeroSection(screenSize, isSmallScreen),
              
//               const SizedBox(height: 20),
              
//               // Main Contact Form Card
//               _buildContactFormCard(screenSize, isSmallScreen, cardPadding),
              
//               const SizedBox(height: 20),
              
//               // Quick Connect Section - Clean App Icons Only
//               _buildQuickConnectSection(screenSize, isSmallScreen),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeroSection(Size screenSize, bool isSmallScreen) {
//     return Container(
//       padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.green.shade50, Colors.green.shade100],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.green.shade200, width: 1),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   "We're Here to Help!",
//                   style: TextStyle(
//                     fontSize: isSmallScreen ? 18 : 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.green.shade800,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   "Have questions or need assistance? Fill out the form below and we'll get back to you within 24 hours.",
//                   style: TextStyle(
//                     fontSize: isSmallScreen ? 13 : 15,
//                     color: Colors.grey.shade700,
//                     height: 1.5,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: Colors.green.shade700,
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(Icons.timer, color: Colors.white, size: 16),
//                       const SizedBox(width: 4),
//                       Text(
//                         "Response within 24 hrs",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: isSmallScreen ? 11 : 13,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (!isSmallScreen)
//             Container(
//               width: 80,
//               height: 80,
//               decoration: BoxDecoration(
//                 color: Colors.green.shade200,
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.support_agent,
//                 color: Colors.green,
//                 size: 40,
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildContactFormCard(Size screenSize, bool isSmallScreen, double cardPadding) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.shade200,
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//             spreadRadius: 5,
//           ),
//         ],
//       ),
//       padding: EdgeInsets.all(cardPadding),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade50,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(
//                   Icons.message_outlined,
//                   color: Colors.green.shade700,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Text(
//                 "Send a Message",
//                 style: TextStyle(
//                   fontSize: isSmallScreen ? 18 : 22,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.grey.shade900,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Fill in the details below and we'll get back to you soon.",
//             style: TextStyle(
//               fontSize: isSmallScreen ? 13 : 15,
//               color: Colors.grey.shade600,
//             ),
//           ),
//           const SizedBox(height: 24),
          
//           // Name Field
//           _buildModernInputField(
//             label: "Full Name",
//             controller: nameController,
//             hint: "Enter your full name",
//             icon: Icons.person_outline,
//             focusNode: _nameFocus,
//             isSmallScreen: isSmallScreen,
//             screenSize: screenSize,
//           ),
          
//           // Email Field
//           _buildModernInputField(
//             label: "Email Address",
//             controller: emailController,
//             hint: "Enter your email address",
//             icon: Icons.email_outlined,
//             keyboardType: TextInputType.emailAddress,
//             focusNode: _emailFocus,
//             isSmallScreen: isSmallScreen,
//             screenSize: screenSize,
//           ),
          
//           // Message Field
//           _buildModernInputField(
//             label: "Your Message",
//             controller: messageController,
//             hint: "How can we help you?",
//             icon: Icons.chat_bubble_outline,
//             maxLines: 5,
//             focusNode: _messageFocus,
//             isSmallScreen: isSmallScreen,
//             screenSize: screenSize,
//           ),
          
//           const SizedBox(height: 24),
          
//           // Submit Button
//           _buildSubmitButton(screenSize, isSmallScreen),
          
//           // Status Message
//           if (statusMessage != null) ...[
//             const SizedBox(height: 16),
//             _buildStatusMessage(isSmallScreen, screenSize),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildModernInputField({
//     required String label,
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     required FocusNode focusNode,
//     required bool isSmallScreen,
//     required Size screenSize,
//     TextInputType? keyboardType,
//     int maxLines = 1,
//   }) {
//     final isFocused = focusNode.hasFocus;
    
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontWeight: FontWeight.w600,
//               fontSize: isSmallScreen ? 14 : 15,
//               color: Colors.grey.shade800,
//             ),
//           ),
//           const SizedBox(height: 6),
//           TextField(
//             controller: controller,
//             focusNode: focusNode,
//             keyboardType: keyboardType,
//             maxLines: maxLines,
//             textInputAction: maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
//             style: TextStyle(
//               fontSize: isSmallScreen ? 14 : 15,
//               color: Colors.grey.shade900,
//             ),
//             decoration: InputDecoration(
//               hintText: hint,
//               hintStyle: TextStyle(
//                 fontSize: isSmallScreen ? 13 : 14,
//                 color: Colors.grey.shade400,
//               ),
//               prefixIcon: Icon(icon, color: isFocused ? Colors.green.shade700 : Colors.grey.shade400, size: 20),
//               filled: true,
//               fillColor: isFocused ? Colors.green.shade50 : Colors.grey.shade50,
//               contentPadding: EdgeInsets.symmetric(
//                 horizontal: 16,
//                 vertical: maxLines > 1 ? 16 : 14,
//               ),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide.none,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: BorderSide(color: Colors.green.shade700, width: 2),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSubmitButton(Size screenSize, bool isSmallScreen) {
//     return SizedBox(
//       width: double.infinity,
//       height: isSmallScreen ? 52 : 56,
//       child: ElevatedButton(
//         onPressed: isSubmitting ? null : _submitFeedback,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.green.shade700,
//           foregroundColor: Colors.white,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(14),
//           ),
//           elevation: 0,
//           disabledBackgroundColor: Colors.grey.shade300,
//         ),
//         child: isSubmitting
//             ? SizedBox(
//                 height: 24,
//                 width: 24,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2.5,
//                   color: Colors.white,
//                 ),
//               )
//             : Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.send, color: Colors.white, size: 20),
//                   const SizedBox(width: 10),
//                   Text(
//                     "Send Message",
//                     style: TextStyle(
//                       fontWeight: FontWeight.w700,
//                       fontSize: isSmallScreen ? 15 : 16,
//                       letterSpacing: 0.5,
//                     ),
//                   ),
//                 ],
//               ),
//       ),
//     );
//   }

//   Widget _buildStatusMessage(bool isSmallScreen, Size screenSize) {
//     return Container(
//       padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
//       decoration: BoxDecoration(
//         color: isSuccess 
//             ? Colors.green.shade50 
//             : Colors.red.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: isSuccess ? Colors.green.shade200 : Colors.red.shade200,
//           width: 1,
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             isSuccess ? Icons.check_circle : Icons.error_outline,
//             color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
//             size: 22,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               statusMessage!,
//               style: TextStyle(
//                 color: isSuccess ? Colors.green.shade800 : Colors.red.shade800,
//                 fontWeight: FontWeight.w500,
//                 fontSize: isSmallScreen ? 13 : 14,
//                 height: 1.4,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ========== QUICK CONNECT - CLEAN APP ICONS ONLY ==========
//   Widget _buildQuickConnectSection(Size screenSize, bool isSmallScreen) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.shade200,
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//             spreadRadius: 5,
//           ),
//         ],
//       ),
//       padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.green.shade50,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(
//                   Icons.bolt_outlined,
//                   color: Colors.green.shade700,
//                   size: 24,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Text(
//                 "Quick Connect",
//                 style: TextStyle(
//                   fontSize: isSmallScreen ? 18 : 22,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.grey.shade900,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Connect with us through your preferred channel",
//             style: TextStyle(
//               fontSize: isSmallScreen ? 12 : 13,
//               color: Colors.grey.shade600,
//             ),
//           ),
//           const SizedBox(height: 20),
          
//           // App Icons Only - No Rectangles
//           Wrap(
//             spacing: isSmallScreen ? 20 : 30,
//             runSpacing: 16,
//             alignment: WrapAlignment.start,
//             children: [
//               _buildAppIcon(
//                 icon: FontAwesomeIcons.phone,
//                 label: "Call",
//                 onTap: () => _openUrl("tel:8714412090"),
//                 isSmallScreen: isSmallScreen,
//               ),
//               _buildAppIcon(
//                 icon: FontAwesomeIcons.whatsapp,
//                 label: "WhatsApp",
//                 onTap: () => _openUrl("https://wa.me/918714412090"),
//                 isSmallScreen: isSmallScreen,
//               ),
//               _buildAppIcon(
//                 icon: FontAwesomeIcons.instagram,
//                 label: "Instagram",
//                 onTap: () => _openUrl("https://www.instagram.com/hosta_healthcare/?igsh=MnR6d3h0YTJlbXEy"),
//                 isSmallScreen: isSmallScreen,
//               ),
//               _buildAppIcon(
//                 icon: FontAwesomeIcons.facebook,
//                 label: "Facebook",
//                 onTap: () => _openUrl("https://www.facebook.com/profile.php?id=61568947746890&mibextid=LQQJ4d"),
//                 isSmallScreen: isSmallScreen,
//               ),
//               _buildAppIcon(
//                 icon: Icons.email,
//                 label: "Email",
//                 onTap: () => _openUrl("mailto:hostahealthcare@gmail.com?subject=Inquiry&body=Hello Hosta,"),
//                 isSmallScreen: isSmallScreen,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAppIcon({
//     required dynamic icon,
//     required String label,
//     required VoidCallback onTap,
//     required bool isSmallScreen,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(50),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: isSmallScreen ? 56 : 64,
//             height: isSmallScreen ? 56 : 64,
//             decoration: BoxDecoration(
//               color: Colors.green.shade50,
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               icon,
//               color: Colors.green.shade700,
//               size: isSmallScreen ? 26 : 30,
//             ),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: isSmallScreen ? 11 : 12,
//               color: Colors.grey.shade700,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }




import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hosta/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:developer'; // For logging

class Contact extends StatefulWidget {
  const Contact({super.key});

  @override
  State<Contact> createState() => _ContactState();
}

class _ContactState extends State<Contact> with SingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  bool isSubmitting = false;
  String? statusMessage;
  bool isSuccess = false;

  final ApiService _apiService = ApiService();
  late AnimationController _animationController;

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _messageFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _messageFocus.dispose();
    nameController.dispose();
    emailController.dispose();
    messageController.dispose();
    super.dispose();
  }
  // In Contact screen - Update _submitFeedback

Future<void> _submitFeedback() async {
  // Validate fields
  if (nameController.text.trim().isEmpty) {
    _showError("Please enter your name");
    return;
  }
  
  if (emailController.text.trim().isEmpty) {
    _showError("Please enter your email address");
    return;
  }
  
  if (!_isValidEmail(emailController.text.trim())) {
    _showError("Please enter a valid email address");
    return;
  }
  
  if (messageController.text.trim().isEmpty) {
    _showError("Please enter your message");
    return;
  }

  setState(() {
    isSubmitting = true;
    statusMessage = "⏳ Sending your message...";
    isSuccess = false;
  });

  try {
    final emailData = {
      "to": "hostahealthcare@gmail.com",
      "from": nameController.text.trim(),
      "email": emailController.text.trim(),
      "subject": "New Contact Form Message from ${nameController.text.trim()}",
      "text": messageController.text.trim(),
      "html": _buildEmailTemplate(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        message: messageController.text.trim(),
      ),
    };

    await _apiService.sendEmail(emailData);
    
    setState(() {
      statusMessage = "✅ Thank you for contacting us! We'll get back to you soon.";
      isSuccess = true;
      nameController.clear();
      emailController.clear();
      messageController.clear();
    });
    _showSuccessSnackBar();
    
  } catch (e) {
    setState(() {
      statusMessage = "⚠️ ${e.toString().replaceAll('Exception: ', '')}";
      isSuccess = false;
    });
  }

  setState(() {
    isSubmitting = false;
  });
}
// Future<void> _submitFeedback() async {
//   // Validate fields
//   if (nameController.text.trim().isEmpty) {
//     _showError("Please enter your name");
//     return;
//   }
  
//   if (emailController.text.trim().isEmpty) {
//     _showError("Please enter your email address");
//     return;
//   }
  
//   if (!_isValidEmail(emailController.text.trim())) {
//     _showError("Please enter a valid email address");
//     return;
//   }
  
//   if (messageController.text.trim().isEmpty) {
//     _showError("Please enter your message");
//     return;
//   }

//   setState(() {
//     isSubmitting = true;
//     statusMessage = "⏳ Sending your message...";
//     isSuccess = false;
//   });

//   try {
//     // Build HTML email content
//     String htmlContent = _buildEmailTemplate(
//       name: nameController.text.trim(),
//       email: emailController.text.trim(),
//       message: messageController.text.trim(),
//     );

//     // Prepare data for API - Match the format your backend expects
//     final emailData = {
//       "from": nameController.text.trim(),
//       "email": emailController.text.trim(), // Added this
//       "to": "hostahealthcare@gmail.com",
//       "subject": "New Contact Form Message from ${nameController.text.trim()}",
//       "text": messageController.text.trim(),
//       "html": htmlContent,
//       "message": messageController.text.trim(), // Added this
//     };

//     log("📧 Sending email data: $emailData");

//     // Send email using your API endpoint
//     final response = await _apiService.sendEmail(emailData);
    
//     log("📧 Response status: ${response.statusCode}");
//     log("📧 Response data: ${response.data}");

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       setState(() {
//         statusMessage = "✅ Thank you for contacting us! We'll get back to you soon.";
//         isSuccess = true;
//         nameController.clear();
//         emailController.clear();
//         messageController.clear();
//       });
//       _showSuccessSnackBar();
//     } else {
//       setState(() {
//         statusMessage = "❌ Failed to send message. Please try again.";
//         isSuccess = false;
//       });
//     }
//   } on DioException catch (e) {
//     log("❌ Dio error: ${e.message}");
//     log("❌ Error type: ${e.type}");
//     log("❌ Response data: ${e.response?.data}");
    
//     String errorMessage = "⚠️ Unable to send message. ";
//     if (e.type == DioExceptionType.connectionTimeout) {
//       errorMessage += "Connection timeout. Please check your internet.";
//     } else if (e.type == DioExceptionType.receiveTimeout) {
//       errorMessage += "Server not responding. Please try again.";
//     } else if (e.response?.statusCode == 404) {
//       errorMessage += "Email service not found. Please contact support.";
//     } else if (e.response?.statusCode == 500) {
//       errorMessage += "Server error. Please try again later.";
//     } else {
//       errorMessage += "Please try again later.";
//     }
    
//     setState(() {
//       statusMessage = errorMessage;
//       isSuccess = false;
//     });
//   } catch (e) {
//     log("❌ Unknown error: $e");
//     setState(() {
//       statusMessage = "⚠️ Unable to send message. Please try again later.";
//       isSuccess = false;
//     });
//   }

//   setState(() {
//     isSubmitting = false;
//   });
// }

  void _showError(String message) {
    setState(() {
      statusMessage = message;
      isSuccess = false;
    });
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Message sent successfully! 🎉'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _buildEmailTemplate({
    required String name,
    required String email,
    required String message,
  }) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="margin: 0; padding: 0; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f4f4f4;">
      <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #f4f4f4; padding: 20px;">
        <tr>
          <td align="center">
            <table width="600" cellpadding="0" cellspacing="0" border="0" style="background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
              <tr>
                <td style="background: linear-gradient(135deg, #43a047 0%, #2e7d32 100%); padding: 30px 20px; text-align: center;">
                  <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 600;">Hosta Healthcare</h1>
                  <p style="color: #e8f5e9; margin: 10px 0 0 0; font-size: 16px;">New Contact Form Submission</p>
                </td>
              </tr>
              <tr>
                <td style="padding: 40px 30px;">
                  <p style="color: #2e7d32; font-size: 18px; margin: 0 0 20px 0; font-weight: 500;">👋 You have a new message!</p>
                  <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #f1f8e9; border-radius: 10px; margin-bottom: 25px; border-left: 4px solid #43a047;">
                    <tr>
                      <td style="padding: 20px;">
                        <h3 style="color: #2e7d32; margin: 0 0 15px 0; font-size: 18px; font-weight: 600;">📋 Sender Information</h3>
                        <table width="100%" cellpadding="5" cellspacing="0" border="0">
                          <tr>
                            <td width="100" style="color: #558b2f; font-weight: 500;">Name:</td>
                            <td style="color: #333333; font-weight: 500;">$name</td>
                          </tr>
                          <tr>
                            <td style="color: #558b2f; font-weight: 500;">Email:</td>
                            <td style="color: #333333;">
                              <a href="mailto:$email" style="color: #43a047; text-decoration: none; font-weight: 500;">$email</a>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                  <table width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #ffffff; border-radius: 10px; margin-bottom: 25px; border: 1px solid #e0e0e0;">
                    <tr>
                      <td style="padding: 20px;">
                        <h3 style="color: #2e7d32; margin: 0 0 15px 0; font-size: 18px; font-weight: 600;">💬 Message</h3>
                        <p style="color: #555555; line-height: 1.6; margin: 0; font-size: 15px; background-color: #fafafa; padding: 15px; border-radius: 8px; border-left: 3px solid #43a047;">
                          ${message.replaceAll('\n', '<br>')}
                        </p>
                      </td>
                    </tr>
                  </table>
                  <table width="100%" cellpadding="0" cellspacing="0" border="0">
                    <tr>
                      <td align="center">
                        <a href="mailto:$email?subject=Re: Your message to Hosta Healthcare" style="display: inline-block; background: linear-gradient(135deg, #43a047 0%, #2e7d32 100%); color: #ffffff; text-decoration: none; padding: 12px 30px; border-radius: 25px; font-weight: 500; font-size: 16px; margin: 10px 0;">
                          ↩️ Reply to $name
                        </a>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>
              <tr>
                <td style="background-color: #f1f8e9; padding: 20px 30px; text-align: center; border-top: 1px solid #c8e6c9;">
                  <p style="color: #558b2b; margin: 0 0 10px 0; font-size: 14px;">This message was sent from the Hosta Healthcare contact form.</p>
                  <p style="color: #558b2b; margin: 0; font-size: 13px;">© ${DateTime.now().year} Hosta Healthcare. All rights reserved.</p>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
    </body>
    </html>
    ''';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not open $url"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isTablet = screenSize.width >= 600 && screenSize.width < 1200;
    final isDesktop = screenSize.width >= 1200;
    
    final horizontalPadding = isDesktop ? screenSize.width * 0.15 : (isTablet ? screenSize.width * 0.08 : screenSize.width * 0.04);
    final cardPadding = isSmallScreen ? screenSize.width * 0.05 : screenSize.width * 0.04;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isSmallScreen ? 60 : 70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade700, Colors.green.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: isSmallScreen ? 60 : 70,
            title: Text(
              "Contact Us",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: isSmallScreen ? 20 : 24,
                letterSpacing: 0.5,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              splashRadius: 24,
            ),
            centerTitle: true,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _animationController,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: screenSize.height * 0.02,
          ),
          child: Column(
            children: [
              _buildHeroSection(screenSize, isSmallScreen),
              const SizedBox(height: 20),
              _buildContactFormCard(screenSize, isSmallScreen, cardPadding),
              const SizedBox(height: 20),
              _buildQuickConnectSection(screenSize, isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(Size screenSize, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "We're Here to Help!",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Have questions or need assistance? Fill out the form below and we'll get back to you within 24 hours.",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "Response within 24 hrs",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 11 : 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isSmallScreen)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                color: Colors.green,
                size: 40,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactFormCard(Size screenSize, bool isSmallScreen, double cardPadding) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 5,
          ),
        ],
      ),
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.message_outlined,
                  color: Colors.green.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Send a Message",
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Fill in the details below and we'll get back to you soon.",
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 15,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildModernInputField(
            label: "Full Name",
            controller: nameController,
            hint: "Enter your full name",
            icon: Icons.person_outline,
            focusNode: _nameFocus,
            isSmallScreen: isSmallScreen,
            screenSize: screenSize,
          ),
          
          _buildModernInputField(
            label: "Email Address",
            controller: emailController,
            hint: "Enter your email address",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            focusNode: _emailFocus,
            isSmallScreen: isSmallScreen,
            screenSize: screenSize,
          ),
          
          _buildModernInputField(
            label: "Your Message",
            controller: messageController,
            hint: "How can we help you?",
            icon: Icons.chat_bubble_outline,
            maxLines: 5,
            focusNode: _messageFocus,
            isSmallScreen: isSmallScreen,
            screenSize: screenSize,
          ),
          
          const SizedBox(height: 24),
          _buildSubmitButton(screenSize, isSmallScreen),
          
          if (statusMessage != null) ...[
            const SizedBox(height: 16),
            _buildStatusMessage(isSmallScreen, screenSize),
          ],
        ],
      ),
    );
  }

  Widget _buildModernInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required FocusNode focusNode,
    required bool isSmallScreen,
    required Size screenSize,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final isFocused = focusNode.hasFocus;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 14 : 15,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            maxLines: maxLines,
            textInputAction: maxLines == 1 ? TextInputAction.next : TextInputAction.newline,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 15,
              color: Colors.grey.shade900,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                color: Colors.grey.shade400,
              ),
              prefixIcon: Icon(icon, color: isFocused ? Colors.green.shade700 : Colors.grey.shade400, size: 20),
              filled: true,
              fillColor: isFocused ? Colors.green.shade50 : Colors.grey.shade50,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 16 : 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.green.shade700, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(Size screenSize, bool isSmallScreen) {
    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 52 : 56,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : _submitFeedback,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: isSubmitting
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "Send Message",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: isSmallScreen ? 15 : 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatusMessage(bool isSmallScreen, Size screenSize) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
      decoration: BoxDecoration(
        color: isSuccess 
            ? Colors.green.shade50 
            : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error_outline,
            color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusMessage!,
              style: TextStyle(
                color: isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                fontWeight: FontWeight.w500,
                fontSize: isSmallScreen ? 13 : 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickConnectSection(Size screenSize, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 5,
          ),
        ],
      ),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.bolt_outlined,
                  color: Colors.green.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Quick Connect",
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Connect with us through your preferred channel",
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          
          Wrap(
            spacing: isSmallScreen ? 20 : 30,
            runSpacing: 16,
            alignment: WrapAlignment.start,
            children: [
              _buildAppIcon(
                icon: FontAwesomeIcons.phone,
                label: "Call",
                onTap: () => _openUrl("tel:8714412090"),
                isSmallScreen: isSmallScreen,
              ),
              _buildAppIcon(
                icon: FontAwesomeIcons.whatsapp,
                label: "WhatsApp",
                onTap: () => _openUrl("https://wa.me/918714412090"),
                isSmallScreen: isSmallScreen,
              ),
              _buildAppIcon(
                icon: FontAwesomeIcons.instagram,
                label: "Instagram",
                onTap: () => _openUrl("https://www.instagram.com/hosta_healthcare/?igsh=MnR6d3h0YTJlbXEy"),
                isSmallScreen: isSmallScreen,
              ),
              _buildAppIcon(
                icon: FontAwesomeIcons.facebook,
                label: "Facebook",
                onTap: () => _openUrl("https://www.facebook.com/profile.php?id=61568947746890&mibextid=LQQJ4d"),
                isSmallScreen: isSmallScreen,
              ),
              _buildAppIcon(
                icon: Icons.email,
                label: "Email",
                onTap: () => _openUrl("mailto:hostahealthcare@gmail.com?subject=Inquiry&body=Hello Hosta,"),
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon({
    required dynamic icon,
    required String label,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSmallScreen ? 56 : 64,
            height: isSmallScreen ? 56 : 64,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.green.shade700,
              size: isSmallScreen ? 26 : 30,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}