import 'package:flutter/material.dart';

class DoctorDetailScreen extends StatefulWidget {
  const DoctorDetailScreen({super.key});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  int appointmentCount = 124;
  double rating = 4.5;
  int reviewCount = 38;

  String consultationType = "clinic";
  String hospitalName = "City Hospital";
  String hospitalAddress = "Calicut, Kerala";
  String clinicAddress = "Kozhikode Town Clinic";
  double fees = 300;

  List<Map<String, dynamic>> reviews = [
    {"name": "Rahul", "stars": 5, "comment": "Very friendly doctor"},
    {"name": "Anjali", "stars": 4, "comment": "Good experience"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),

      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Doctor Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
          leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 HEADER
            _doctorHeader(),

            const SizedBox(height: 20),

            /// 🔹 HOSPITAL
            _infoCard(
              icon: Icons.local_hospital,
              title: hospitalName,
              subtitle: hospitalAddress,
            ),

            const SizedBox(height: 12),

            /// 🔹 CONSULTATION TYPE
            _consultationInfo(),

            const SizedBox(height: 12),

            /// 🔹 FEES
            _feesCard(),

            const SizedBox(height: 20),

            /// 🔹 TIMINGS
            const Text(
              "Available Timings",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            _timingTile("Monday", "9:00 AM - 1:00 PM"),
            _timingTile("Wednesday", "10:00 AM - 2:00 PM"),

            const SizedBox(height: 20),

            /// 🔹 ABOUT
            const Text(
              "About Doctor",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              "Experienced doctor with excellent patient care.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            /// 🔹 REVIEWS
            const Text(
              "Patient Reviews",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...reviews.map(
              (r) => _reviewTile(r["name"], r["stars"], r["comment"]),
            ),

            const SizedBox(height: 10),

            /// 🔹 ADD REVIEW BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _showReviewDialog,
                child: const Text("Write a Review"),
              ),
            ),

            const SizedBox(height: 30),

            /// 🔹 BOOK BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "BOOK APPOINTMENT",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 HEADER
  Widget _doctorHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
           CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage("assets/doctor.jpg",),
            ),
          
          const SizedBox(width: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Dr. John Mathew",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const Text("Cardiologist", style: TextStyle(color: Colors.green)),

              const SizedBox(height: 6),

              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  Text("$rating"),
                  Text(" ($reviewCount)"),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                "$appointmentCount+ Appointments",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔹 CONSULTATION
  Widget _consultationInfo() {
    String text = consultationType == "hospital"
        ? hospitalAddress
        : consultationType == "clinic"
        ? clinicAddress
        : "Home Visit Available";

    return _infoCard(
      icon: Icons.location_on,
      title: consultationType.toUpperCase(),
      subtitle: text,
    );
  }

  /// 🔹 FEES
  Widget _feesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.currency_rupee, color: Colors.green),
          const SizedBox(width: 10),
          const Text(
            "Consultation Fee",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(
            "₹$fees",
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 INFO CARD
  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔹 TIMINGS
  Widget _timingTile(String day, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 18, color: Colors.green),
          const SizedBox(width: 10),
          Text(day),
          const Spacer(),
          Text(time, style: const TextStyle(color: Colors.green)),
        ],
      ),
    );
  }

  /// 🔹 REVIEW TILE
  Widget _reviewTile(String name, int stars, String comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Row(
                children: List.generate(
                  stars,
                  (index) =>
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _showReviewDialog() {
    final controller = TextEditingController();
    int stars = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Add Review"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// ⭐ STAR RATING UI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            stars = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.star,
                            size: 28, // control size here
                            color: index < stars
                                ? Colors.amber
                                : Colors.grey[300],
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 10),

                  /// ✍️ REVIEW TEXT
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Write your review",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),

                ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;

                    setState(() {
                      reviews.add({
                        "name": "You",
                        "stars": stars,
                        "comment": controller.text,
                      });
                      reviewCount++;
                    });

                    Navigator.pop(context);
                  },
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
