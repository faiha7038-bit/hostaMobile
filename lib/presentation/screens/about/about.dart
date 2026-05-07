import 'package:flutter/material.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 3,
        shadowColor: Colors.green.shade100,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: screenWidth * 0.055),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "About",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: screenWidth * 0.05,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌿 Header
            Center(
              child: Column(
                children: [
                  Icon(Icons.local_hospital, size: screenWidth * 0.18, color: Colors.green[700]),
                  SizedBox(height: screenHeight * 0.015),
                  Text(
                    "Hospital Finder",
                    style: TextStyle(
                      fontSize: screenWidth * 0.065,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    "Connecting you to quality healthcare easily.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.037),

            // 🌿 About Section
            _buildSectionTitle("About Our App", screenWidth),
            Text(
              "Welcome to our innovative hospital finder platform that connects patients with nearby hospitals and doctors. "
              "Our goal is to make healthcare access simple, fast, and stress-free.",
              style: TextStyle(
                fontSize: screenWidth * 0.04, 
                color: Colors.black87, 
                height: 1.5,
              ),
            ),
            SizedBox(height: screenHeight * 0.012),
            Text(
              "You can search hospitals, book appointments, and even access emergency ambulance services instantly.",
              style: TextStyle(
                fontSize: screenWidth * 0.04, 
                color: Colors.black87, 
                height: 1.5,
              ),
            ),

            SizedBox(height: screenHeight * 0.037),

            // 🌿 Key Features
            _buildSectionTitle("Key Features", screenWidth),
            Wrap(
              spacing: screenWidth * 0.035,
              runSpacing: screenHeight * 0.0175,
              children: const [
                FeatureCard(
                  icon: Icons.search,
                  title: "Find Hospitals",
                  description: "Locate nearby hospitals easily.",
                ),
                FeatureCard(
                  icon: Icons.calendar_month,
                  title: "Book Appointments",
                  description: "Schedule consultations quickly.",
                ),
                FeatureCard(
                  icon: Icons.emergency,
                  title: "Emergency Help",
                  description: "Access ambulance services fast.",
                ),
                FeatureCard(
                  icon: Icons.person_add,
                  title: "Register Hospitals",
                  description: "Sign up as a healthcare provider.",
                ),
                FeatureCard(
                  icon: Icons.assignment,
                  title: "Doctor Details",
                  description: "View hospital specialties & doctors.",
                ),
                FeatureCard(
                  icon: Icons.access_time,
                  title: "Working Hours",
                  description: "Check real-time doctor availability.",
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.037),

            // 🌿 Find Section
            _buildSectionTitle("Find Hospitals Near You", screenWidth),
            Text(
              "Use our search feature to find hospitals and doctors nearby. Simply enter your area or city to begin.",
              style: TextStyle(
                fontSize: screenWidth * 0.04, 
                color: Colors.black87, 
                height: 1.5,
              ),
            ),

            SizedBox(height: screenHeight * 0.037),

            // 🌿 For Hospitals
            _buildSectionTitle("For Hospitals", screenWidth),
            Text(
              "Healthcare providers can join our platform to:",
              style: TextStyle(
                fontSize: screenWidth * 0.04, 
                color: Colors.black87, 
                height: 1.5,
              ),
            ),
            SizedBox(height: screenHeight * 0.012),
            _BulletList(items: [
              "Showcase facilities and services",
              "Manage appointments and patient bookings",
              "Add doctor details and specialties",
              "Provide updates about working hours"
            ]),
            SizedBox(height: screenHeight * 0.012),
            Text(
              "Contact us to learn more about listing your hospital.",
              style: TextStyle(
                fontSize: screenWidth * 0.04, 
                color: Colors.black87,
              ),
            ),

            SizedBox(height: screenHeight * 0.037),

            // 🌿 Commitment
            _buildSectionTitle("Our Commitment", screenWidth),
            _BulletList(items: [
              "Simplifying access to healthcare",
              "Providing accurate information",
              "Ensuring a seamless experience",
              "Improving based on feedback",
              "Maintaining data privacy and security",
            ]),

            SizedBox(height: screenHeight * 0.05),
            Center(
              child: Text(
                "© 2025 Hospital Finder App",
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.grey[600],
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.012),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.025),
      child: Text(
        title,
        style: TextStyle(
          fontSize: screenWidth * 0.055,
          fontWeight: FontWeight.w600,
          color: Colors.green,
        ),
      ),
    );
  }
}

// 🌿 Feature Card Widget
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      width: (screenWidth / 2) - (screenWidth * 0.07),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: screenWidth * 0.12, color: Colors.green),
          SizedBox(height: screenHeight * 0.01),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.04,
              color: Colors.green,
            ),
          ),
          SizedBox(height: screenHeight * 0.0075),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

// 🌿 Bullet List Widget
class _BulletList extends StatelessWidget {
  final List<String> items;
  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => Padding(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• ",
                        style: TextStyle(
                            fontSize: screenWidth * 0.045, 
                            color: Colors.green, 
                            height: 1.3)),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                            fontSize: screenWidth * 0.04, 
                            color: Colors.black87, 
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}