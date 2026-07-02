// import 'package:flutter/material.dart';

// class About extends StatelessWidget {
//   const About({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
//     final isSmallScreen = screenWidth < 600;

//     return Scaffold(
//       backgroundColor: const Color(0xFFECFDF5),
//       appBar: AppBar(
//         backgroundColor: Colors.green,
//         elevation: 3,
//         shadowColor: Colors.green.shade100,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: screenWidth * 0.055),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: Text(
//           "About",
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//             fontSize: screenWidth * 0.05,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(screenWidth * 0.05),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 🌿 Header
//             Center(
//               child: Column(
//                 children: [
//                   Icon(Icons.local_hospital, size: screenWidth * 0.18, color: Colors.green[700]),
//                   SizedBox(height: screenHeight * 0.015),
//                   Text(
//                     "Hospital Finder",
//                     style: TextStyle(
//                       fontSize: screenWidth * 0.065,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.green,
//                     ),
//                   ),
//                   SizedBox(height: screenHeight * 0.01),
//                   Text(
//                     "Connecting you to quality healthcare easily.",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: screenWidth * 0.04,
//                       color: Colors.black54,
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             SizedBox(height: screenHeight * 0.037),

//             // 🌿 About Section
//             _buildSectionTitle("About Our App", screenWidth),
//             Text(
//               "Welcome to our innovative hospital finder platform that connects patients with nearby hospitals and doctors. "
//               "Our goal is to make healthcare access simple, fast, and stress-free.",
//               style: TextStyle(
//                 fontSize: screenWidth * 0.04, 
//                 color: Colors.black87, 
//                 height: 1.5,
//               ),
//             ),
//             SizedBox(height: screenHeight * 0.012),
//             Text(
//               "You can search hospitals, book appointments, and even access emergency ambulance services instantly.",
//               style: TextStyle(
//                 fontSize: screenWidth * 0.04, 
//                 color: Colors.black87, 
//                 height: 1.5,
//               ),
//             ),

//             SizedBox(height: screenHeight * 0.037),

//             // 🌿 Key Features
//             _buildSectionTitle("Key Features", screenWidth),
//             Wrap(
//               spacing: screenWidth * 0.035,
//               runSpacing: screenHeight * 0.0175,
//               children: const [
//                 FeatureCard(
//                   icon: Icons.search,
//                   title: "Find Hospitals",
//                   description: "Locate nearby hospitals easily.",
//                 ),
//                 FeatureCard(
//                   icon: Icons.calendar_month,
//                   title: "Book Appointments",
//                   description: "Schedule consultations quickly.",
//                 ),
//                 FeatureCard(
//                   icon: Icons.emergency,
//                   title: "Emergency Help",
//                   description: "Access ambulance services fast.",
//                 ),
//                 FeatureCard(
//                   icon: Icons.person_add,
//                   title: "Register Hospitals",
//                   description: "Sign up as a healthcare provider.",
//                 ),
//                 FeatureCard(
//                   icon: Icons.assignment,
//                   title: "Doctor Details",
//                   description: "View hospital specialties & doctors.",
//                 ),
//                 FeatureCard(
//                   icon: Icons.access_time,
//                   title: "Working Hours",
//                   description: "Check real-time doctor availability.",
//                 ),
//               ],
//             ),

//             SizedBox(height: screenHeight * 0.037),

//             // 🌿 Find Section
//             _buildSectionTitle("Find Hospitals Near You", screenWidth),
//             Text(
//               "Use our search feature to find hospitals and doctors nearby. Simply enter your area or city to begin.",
//               style: TextStyle(
//                 fontSize: screenWidth * 0.04, 
//                 color: Colors.black87, 
//                 height: 1.5,
//               ),
//             ),

//             SizedBox(height: screenHeight * 0.037),

//             // 🌿 For Hospitals
//             _buildSectionTitle("For Hospitals", screenWidth),
//             Text(
//               "Healthcare providers can join our platform to:",
//               style: TextStyle(
//                 fontSize: screenWidth * 0.04, 
//                 color: Colors.black87, 
//                 height: 1.5,
//               ),
//             ),
//             SizedBox(height: screenHeight * 0.012),
//             _BulletList(items: [
//               "Showcase facilities and services",
//               "Manage appointments and patient bookings",
//               "Add doctor details and specialties",
//               "Provide updates about working hours"
//             ]),
//             SizedBox(height: screenHeight * 0.012),
//             Text(
//               "Contact us to learn more about listing your hospital.",
//               style: TextStyle(
//                 fontSize: screenWidth * 0.04, 
//                 color: Colors.black87,
//               ),
//             ),

//             SizedBox(height: screenHeight * 0.037),

//             // 🌿 Commitment
//             _buildSectionTitle("Our Commitment", screenWidth),
//             _BulletList(items: [
//               "Simplifying access to healthcare",
//               "Providing accurate information",
//               "Ensuring a seamless experience",
//               "Improving based on feedback",
//               "Maintaining data privacy and security",
//             ]),

//             SizedBox(height: screenHeight * 0.05),
//             Center(
//               child: Text(
//                 "© 2025 Hospital Finder App",
//                 style: TextStyle(
//                   fontSize: screenWidth * 0.035,
//                   color: Colors.grey[600],
//                 ),
//               ),
//             ),
//             SizedBox(height: screenHeight * 0.012),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title, double screenWidth) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: screenWidth * 0.025),
//       child: Text(
//         title,
//         style: TextStyle(
//           fontSize: screenWidth * 0.055,
//           fontWeight: FontWeight.w600,
//           color: Colors.green,
//         ),
//       ),
//     );
//   }
// }

// // 🌿 Feature Card Widget
// class FeatureCard extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final String description;

//   const FeatureCard({
//     super.key,
//     required this.icon,
//     required this.title,
//     required this.description,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
    
//     return Container(
//       width: (screenWidth / 2) - (screenWidth * 0.07),
//       padding: EdgeInsets.all(screenWidth * 0.04),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(screenWidth * 0.035),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.green.withOpacity(0.1),
//             blurRadius: 6,
//             offset: const Offset(0, 3),
//           )
//         ],
//       ),
//       child: Column(
//         children: [
//           Icon(icon, size: screenWidth * 0.12, color: Colors.green),
//           SizedBox(height: screenHeight * 0.01),
//           Text(
//             title,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: screenWidth * 0.04,
//               color: Colors.green,
//             ),
//           ),
//           SizedBox(height: screenHeight * 0.0075),
//           Text(
//             description,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: screenWidth * 0.035,
//               color: Colors.black54,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // 🌿 Bullet List Widget
// class _BulletList extends StatelessWidget {
//   final List<String> items;
//   const _BulletList({required this.items});

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final screenHeight = MediaQuery.of(context).size.height;
    
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: items
//           .map((item) => Padding(
//                 padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text("• ",
//                         style: TextStyle(
//                             fontSize: screenWidth * 0.045, 
//                             color: Colors.green, 
//                             height: 1.3)),
//                     Expanded(
//                       child: Text(
//                         item,
//                         style: TextStyle(
//                             fontSize: screenWidth * 0.04, 
//                             color: Colors.black87, 
//                             height: 1.4),
//                       ),
//                     ),
//                   ],
//                 ),
//               ))
//           .toList(),
//     );
//   }
// }


import 'package:flutter/material.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "About",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
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
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(screenWidth, screenHeight),
            
            SizedBox(height: screenHeight * 0.03),
            
            // About Section
            _buildSection(
              title: "About Our App",
              icon: Icons.info_outline,
              children: [
                Text(
                  "Welcome to our innovative hospital finder platform that connects patients with nearby hospitals and doctors. "
                  "Our goal is to make healthcare access simple, fast, and stress-free.",
                  style: _bodyTextStyle(screenWidth),
                ),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  "You can search hospitals, book appointments, and even access emergency ambulance services instantly.",
                  style: _bodyTextStyle(screenWidth),
                ),
              ],
            ),
            
            SizedBox(height: screenHeight * 0.03),
            
            // Features Section
            _buildSection(
              title: "Key Features",
              icon: Icons.star_outline,
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isSmallScreen ? 2 : 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
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
              ],
            ),
            
            SizedBox(height: screenHeight * 0.03),
            
            // Find Section
            _buildSection(
              title: "Find Hospitals Near You",
              icon: Icons.location_on_outlined,
              children: [
                Text(
                  "Use our search feature to find hospitals and doctors nearby. Simply enter your area or city to begin.",
                  style: _bodyTextStyle(screenWidth),
                ),
              ],
            ),
            
            SizedBox(height: screenHeight * 0.03),
            
            // For Hospitals Section
            _buildSection(
              title: "For Hospitals",
              icon: Icons.business_outlined,
              children: [
                Text(
                  "Healthcare providers can join our platform to:",
                  style: _bodyTextStyle(screenWidth),
                ),
                SizedBox(height: screenHeight * 0.012),
                _BulletList(items: [
                  "Showcase facilities and services",
                  "Manage appointments and patient bookings",
                  "Add doctor details and specialties",
                  "Provide updates about working hours"
                ]),
                SizedBox(height: screenHeight * 0.015),
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined, color: Colors.green, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Contact us at hosta@gmail.com to learn more about listing your hospital.",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
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
            
            SizedBox(height: screenHeight * 0.03),
            
            // Commitment Section
            _buildSection(
              title: "Our Commitment",
              icon: Icons.verified_outlined,
              children: [
                _BulletList(items: [
                  "Simplifying access to healthcare",
                  "Providing accurate information",
                  "Ensuring a seamless experience",
                  "Improving based on feedback",
                  "Maintaining data privacy and security",
                ]),
              ],
            ),
            
            SizedBox(height: screenHeight * 0.04),
            
            // Footer
            Center(
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      color: Colors.green,
                      size: 30,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  Text(
                    "Hospital Finder",
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    "© 2025 All Rights Reserved",
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.06),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green[400]!,
            Colors.green[700]!,
          ],
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
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.health_and_safety,
              size: screenWidth * 0.12,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          Text(
            "Your Health, Our Priority",
            style: TextStyle(
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenHeight * 0.008),
          Text(
            "Connecting you to quality healthcare easily",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
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
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.green[700], size: 24),
            SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
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

  TextStyle _bodyTextStyle(double screenWidth) {
    return TextStyle(
      fontSize: screenWidth * 0.04,
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
      padding: EdgeInsets.all(screenWidth * 0.04),
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
        border: Border.all(
          color: Colors.grey[100]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: screenWidth * 0.08,
              color: Colors.green[700],
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: screenWidth * 0.035,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: Colors.grey[600],
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// Bullet List Widget
class _BulletList extends StatelessWidget {
  final List<String> items;

  const _BulletList({required this.items});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
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
                        width: 6,
                        height: 6,
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
                            fontSize: screenWidth * 0.04,
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
}