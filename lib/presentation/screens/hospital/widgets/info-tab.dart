import 'package:flutter/material.dart';

class InfoTab extends StatelessWidget {
  final Map<String, dynamic> hospital;
  final Function(String) makePhoneCall;

  const InfoTab({
    super.key,
    required this.hospital,
    required this.makePhoneCall,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow(Icons.location_on, hospital["address"] ?? "No address provided"),
        _infoRow(Icons.phone, hospital["phone"] ?? "No phone number", onTap: () {
          if (hospital["phone"] != null) {
            makePhoneCall(hospital["phone"]);
          }
        }),
        _infoRow(Icons.email, hospital["email"] ?? "No email provided"),
        _infoRow(Icons.medical_services, hospital["type"] ?? "Unknown type"),
        if (hospital["about"] != null && hospital["about"].isNotEmpty)
          _infoRow(Icons.info, hospital["about"]),
        if (hospital["emergencyContact"] != null && hospital["emergencyContact"] != "00000000")
          _infoRow(Icons.emergency, "Emergency: ${hospital["emergencyContact"]}", onTap: () {
            makePhoneCall(hospital["emergencyContact"]);
          }),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.green, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}