import 'package:flutter/material.dart';

class About extends StatelessWidget {
  const About({super.key});

  // Helper to clamp a responsive value between min and max.
  double _clamp(double value, double min, double max) =>
      value.clamp(min, max) as double;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    // Responsive font sizes (with sensible limits)
    final double appBarTitleSize = _clamp(screenWidth * 0.055, 16, 24);
    final double sectionTitleSize = _clamp(screenWidth * 0.055, 18, 28);
    final double bodyTextSize = _clamp(screenWidth * 0.04, 14, 18);
    final double smallTextSize = _clamp(screenWidth * 0.035, 12, 16);
    final double featureTitleSize = _clamp(screenWidth * 0.035, 12, 16);
    final double featureDescSize = _clamp(screenWidth * 0.03, 10, 14);

    // Responsive spacing
    final double horizontalPadding = screenWidth * 0.05;
    final double verticalPadding = screenHeight * 0.02;
    final double sectionSpacing = screenHeight * 0.03;
    final double smallSpacing = screenHeight * 0.015;
    final double tinySpacing = screenHeight * 0.005;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "About",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: appBarTitleSize,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(screenWidth, screenHeight),

            SizedBox(height: sectionSpacing),

            // About Section
            _buildSection(
              title: "About Our App",
              icon: Icons.info_outline,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              children: [
                Text(
                  "Welcome to our innovative hospital finder platform that connects patients with nearby hospitals and doctors. "
                  "Our goal is to make healthcare access simple, fast, and stress-free.",
                  style: _bodyTextStyle(screenWidth, bodyTextSize),
                ),
                SizedBox(height: smallSpacing),
                Text(
                  "You can search hospitals, book appointments, and even access emergency ambulance services instantly.",
                  style: _bodyTextStyle(screenWidth, bodyTextSize),
                ),
              ],
            ),

            SizedBox(height: sectionSpacing),

            // Features Section
            _buildSection(
              title: "Key Features",
              icon: Icons.star_outline,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isSmallScreen ? 2 : 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    FeatureCard(
                      icon: Icons.search,
                      title: "Find Hospitals",
                      description: "Locate nearby hospitals easily.",
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    FeatureCard(
                      icon: Icons.calendar_month,
                      title: "Book Appointments",
                      description: "Schedule consultations quickly.",
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    FeatureCard(
                      icon: Icons.emergency,
                      title: "Emergency Help",
                      description: "Access ambulance services fast.",
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    FeatureCard(
                      icon: Icons.person_add,
                      title: "Register Hospitals",
                      description: "Sign up as a healthcare provider.",
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    FeatureCard(
                      icon: Icons.assignment,
                      title: "Doctor Details",
                      description: "View hospital specialties & doctors.",
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                    FeatureCard(
                      icon: Icons.access_time,
                      title: "Working Hours",
                      description: "Check real-time doctor availability.",
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: sectionSpacing),

            // Find Section
            _buildSection(
              title: "Find Hospitals Near You",
              icon: Icons.location_on_outlined,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              children: [
                Text(
                  "Use our search feature to find hospitals and doctors nearby. Simply enter your area or city to begin.",
                  style: _bodyTextStyle(screenWidth, bodyTextSize),
                ),
              ],
            ),

            SizedBox(height: sectionSpacing),

            // For Hospitals Section
            _buildSection(
              title: "For Hospitals",
              icon: Icons.business_outlined,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              children: [
                Text(
                  "Healthcare providers can join our platform to:",
                  style: _bodyTextStyle(screenWidth, bodyTextSize),
                ),
                SizedBox(height: tinySpacing),
                _BulletList(
                  items: [
                    "Showcase facilities and services",
                    "Manage appointments and patient bookings",
                    "Add doctor details and specialties",
                    "Provide updates about working hours",
                  ],
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                ),
                SizedBox(height: smallSpacing),
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        color: Colors.green,
                        size: _clamp(screenWidth * 0.065, 20, 32),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Contact us at hosta@gmail.com to learn more about listing your hospital.",
                          style: TextStyle(
                            fontSize: bodyTextSize,
                            color: Colors.green,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: sectionSpacing),

            // Commitment Section
            _buildSection(
              title: "Our Commitment",
              icon: Icons.verified_outlined,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              children: [
                _BulletList(
                  items: [
                    "Simplifying access to healthcare",
                    "Providing accurate information",
                    "Ensuring a seamless experience",
                    "Improving based on feedback",
                    "Maintaining data privacy and security",
                  ],
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                ),
              ],
            ),

            SizedBox(height: sectionSpacing * 1.5),

            // Footer
            Center(
              child: Column(
                children: [
                  Container(
                    width: _clamp(screenWidth * 0.15, 50, 80),
                    height: _clamp(screenWidth * 0.15, 50, 80),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      color: Colors.green,
                      size: _clamp(screenWidth * 0.08, 24, 40),
                    ),
                  ),
                  SizedBox(height: smallSpacing),
                  Text(
                    "Hospital Finder",
                    style: TextStyle(
                      fontSize: _clamp(screenWidth * 0.04, 14, 22),
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: tinySpacing),
                  Text(
                    "© ${DateTime.now().year} All Rights Reserved",
                    style: TextStyle(
                      fontSize: _clamp(screenWidth * 0.035, 10, 16),
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: verticalPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth, double screenHeight) {
    final double headerPadding = screenWidth * 0.06;
    final double iconSize = _clamp(screenWidth * 0.12, 50, 90);
    final double titleSize = _clamp(screenWidth * 0.055, 20, 34);
    final double subtitleSize = _clamp(screenWidth * 0.04, 14, 22);

    return Container(
      padding: EdgeInsets.all(headerPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.green[400]!, Colors.green[700]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(_clamp(screenWidth * 0.04, 10, 20)),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.health_and_safety,
              size: iconSize,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            "Your Health, Our Priority",
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenHeight * 0.008),
          Text(
            "Connecting you to quality healthcare easily",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: subtitleSize,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required double screenWidth,
    required double screenHeight,
    required List<Widget> children,
  }) {
    final double iconSize = _clamp(screenWidth * 0.065, 20, 32);
    final double titleSize = _clamp(screenWidth * 0.055, 18, 28);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.green[700], size: iconSize),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ...children,
      ],
    );
  }

  TextStyle _bodyTextStyle(double screenWidth, double fontSize) {
    return TextStyle(
      fontSize: fontSize,
      color: Colors.black87,
      height: 1.6,
      letterSpacing: 0.2,
    );
  }
}

// Feature Card Widget
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final double screenWidth;
  final double screenHeight;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    final double iconSize = _clamp(screenWidth * 0.08, 28, 44);
    final double titleSize = _clamp(screenWidth * 0.035, 12, 18);
    final double descSize = _clamp(screenWidth * 0.03, 10, 14);
    final double padding = screenWidth * 0.04;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[100]!, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(_clamp(screenWidth * 0.025, 6, 14)),
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: titleSize,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: descSize,
              color: Colors.grey[600],
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  double _clamp(double value, double min, double max) =>
      value.clamp(min, max) as double;
}

// Bullet List Widget
class _BulletList extends StatelessWidget {
  final List<String> items;
  final double screenWidth;
  final double screenHeight;

  const _BulletList({
    required this.items,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    final double fontSize = _clamp(screenWidth * 0.04, 14, 20);
    final double padding = screenWidth * 0.04;
    final double bulletSize = _clamp(screenWidth * 0.015, 4, 8);

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((item) => Padding(
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: screenHeight * 0.005),
                        width: bulletSize,
                        height: bulletSize,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: fontSize,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  double _clamp(double value, double min, double max) =>
      value.clamp(min, max) as double;
}