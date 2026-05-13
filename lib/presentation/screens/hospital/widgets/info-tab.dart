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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // ✅ Format address from object
    final addressObj = hospital["address"];
    String addressText = "No address provided";
    if (addressObj is Map<String, dynamic>) {
      final place = addressObj["place"] ?? "";
      final district = addressObj["district"] ?? "";
      final state = addressObj["state"] ?? "";
      final pincode = addressObj["pincode"] ?? "";
      final country = addressObj["country"] ?? "";
      
      List<String> parts = [];
      if (place.toString().isNotEmpty) parts.add(place);
      if (district.toString().isNotEmpty) parts.add(district);
      if (state.toString().isNotEmpty) parts.add(state);
      if (pincode.toString().isNotEmpty) parts.add(pincode.toString());
      if (country.toString().isNotEmpty) parts.add(country);
      addressText = parts.join(", ");
    } else if (addressObj is String) {
      addressText = addressObj; // fallback for old format
    }

    return ListView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      children: [
        _infoRow(Icons.location_on, addressText, screenWidth, screenHeight),
        _infoRow(Icons.phone, hospital["phone"] ?? "No phone number", screenWidth, screenHeight, onTap: () {
          if (hospital["phone"] != null && hospital["phone"].toString().isNotEmpty) {
            makePhoneCall(hospital["phone"].toString());
          }
        }),
        _infoRow(Icons.email, hospital["email"] ?? "No email provided", screenWidth, screenHeight),
        _infoRow(Icons.medical_services, hospital["type"] ?? "Unknown type", screenWidth, screenHeight),
        if (hospital["about"] != null && hospital["about"].toString().isNotEmpty)
          _infoRow(Icons.info, hospital["about"].toString(), screenWidth, screenHeight),
        if (hospital["emergencyContact"] != null && 
            hospital["emergencyContact"].toString().isNotEmpty &&
            hospital["emergencyContact"].toString() != "0" &&
            hospital["emergencyContact"].toString() != "00000000")
          _infoRow(Icons.emergency, "Emergency: ${hospital["emergencyContact"]}", screenWidth, screenHeight, onTap: () {
            makePhoneCall(hospital["emergencyContact"].toString());
          }),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text, double screenWidth, double screenHeight, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.green, size: screenWidth * 0.055),
            SizedBox(width: screenWidth * 0.025),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: screenWidth * 0.0375,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}