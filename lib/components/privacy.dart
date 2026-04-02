import 'package:flutter/material.dart';

class Privacy extends StatelessWidget {
  const Privacy({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: const Color(0xFFECFDF5),

      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 1,
        title: const Text(
          "Privacy Policy for Hosta",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // ✅ REMOVE const here (it blocks rebuild)
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            paragraph(
                "At Hosta, developed by Zorrow Tech IT Solutions, we respect your privacy and are committed to protecting the personal information you share with us. This Privacy Policy explains how we collect, use, and safeguard your data when you use our application."),

            heading("Information We Collect"),
            paragraph(
                "Location Data: We access your location to show you the nearest doctors, specialties, hospitals, and ambulances."),
            paragraph(
                "Personal Information: We collect your phone number and blood group if you choose to provide them. These are used to connect users who may need to find people nearby with specific blood groups."),
            paragraph(
                "Healthcare Information: We display details such as doctor names, available specialties, and working hours. This information is for reference only and is not a substitute for medical advice."),

            heading("How We Use Your Information"),
            listItem(
                "• To provide healthcare directory services like showing doctors, specialties, and hospitals near you."),
            listItem(
                "• To allow users to discover nearby people with specific blood groups for emergency support."),
            listItem(
                "• To provide ambulance location details to help users in emergencies."),
            listItem(
                "• To communicate with you if needed for support or service updates."),

            heading("Data Sharing and Disclosure"),
            paragraph(
                "We do not sell or rent your personal information. Your information may only be shared:"),
            listItem(
                "• With nearby users (only blood group and location visibility, if you enable it)."),
            listItem(
                "• Authentication: We use Twilio to send OTPs for login. Twilio may temporarily process your phone number only for this purpose and does not use it for any other activity."),
            listItem("• When required by law or government authorities."),
            listItem(
                "• With trusted service providers who help us operate our services, under strict confidentiality agreements."),

            heading("Data Security"),
            paragraph(
                "We use industry-standard security measures to protect your information. However, no method of storage or transmission is 100% secure, and we cannot guarantee absolute security."),

            heading("Your Choices"),
            paragraph(
                "You can disable location services at any time in your device settings, though some features may not function properly without it."),
            paragraph(
                "Data Deletion Request: If you wish to delete your account or any personal data you have shared with us, you can send an email request to zorrowtech@gmail.com. We will permanently remove your data from our systems within 30 days of receiving your request."),

            heading("Children’s Privacy"),
            paragraph(
                "Our app is not intended for children under 13. We do not knowingly collect data from children."),

            heading("Disclaimer"),
            paragraph(
                "The Hosta app provides healthcare directory information only and is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of a qualified healthcare provider for medical concerns."),

            heading("Changes to this Privacy Policy"),
            paragraph(
                "We may update this policy from time to time. Any changes will be posted on this page with the updated date."),

            heading("Contact Us"),
            paragraph(
                "If you have any questions or concerns about this Privacy Policy or your data, please contact us at:"),
            paragraph("Zorrow Tech IT Solutions\nEmail: zorrowtech@gmail.com\nPhone: +91-9400517720"),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// ---------- Helper Text Styles ----------
  Widget heading(String text) => Padding(
        padding: const EdgeInsets.only(top: 18, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      );

  Widget paragraph(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF444444),
            height: 1.5,
          ),
        ),
      );

  Widget listItem(String text) => Padding(
        padding: const EdgeInsets.only(left: 10, bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF444444),
            height: 1.5,
          ),
        ),
      );
}
