import 'package:flutter/material.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 3,
        shadowColor: Colors.green.shade100,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "About",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌿 Header
            Center(
              child: Column(
                children: [
                  Icon(Icons.local_hospital, size: 70, color: Colors.green[700]),
                  const SizedBox(height: 12),
                  const Text(
                    "Hospital Finder",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Connecting you to quality healthcare easily.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🌿 About Section
            _buildSectionTitle("About Our App"),
            const Text(
              "Welcome to our innovative hospital finder platform that connects patients with nearby hospitals and doctors. "
              "Our goal is to make healthcare access simple, fast, and stress-free.",
              style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 10),
            const Text(
              "You can search hospitals, book appointments, and even access emergency ambulance services instantly.",
              style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
            ),

            const SizedBox(height: 30),

            // 🌿 Key Features
            _buildSectionTitle("Key Features"),
            Wrap(
              spacing: 14,
              runSpacing: 14,
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

            const SizedBox(height: 30),

            // 🌿 Find Section
            _buildSectionTitle("Find Hospitals Near You"),
            const Text(
              "Use our search feature to find hospitals and doctors nearby. Simply enter your area or city to begin.",
              style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
            ),

            const SizedBox(height: 30),

            // 🌿 For Hospitals
            _buildSectionTitle("For Hospitals"),
            const Text(
              "Healthcare providers can join our platform to:",
              style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 10),
            const _BulletList(items: [
              "Showcase facilities and services",
              "Manage appointments and patient bookings",
              "Add doctor details and specialties",
              "Provide updates about working hours"
            ]),
            const SizedBox(height: 10),
            const Text(
              "Contact us to learn more about listing your hospital.",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),

            const SizedBox(height: 30),

            // 🌿 Commitment
            _buildSectionTitle("Our Commitment"),
            const _BulletList(items: [
              "Simplifying access to healthcare",
              "Providing accurate information",
              "Ensuring a seamless experience",
              "Improving based on feedback",
              "Maintaining data privacy and security",
            ]),

            const SizedBox(height: 40),
            Center(
              child: Text(
                "© 2025 Hospital Finder App",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
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
    return Container(
      width: (MediaQuery.of(context).size.width / 2) - 28,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          Icon(icon, size: 48, color: Colors.green),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ",
                        style: TextStyle(
                            fontSize: 18, color: Colors.green, height: 1.3)),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black87, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
