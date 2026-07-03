import 'package:flutter/material.dart';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

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

    // Responsive clamped values used throughout
    final double padding = _clamp(screenWidth * 0.04, 12, 24);
    final double iconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double spacing = _clamp(screenWidth * 0.025, 6, 16);
    final double textSize = _clamp(screenWidth * 0.0375, 14, 22);
    final double verticalMargin = _clamp(screenHeight * 0.01, 6, 16);

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
      padding: EdgeInsets.all(padding),
      children: [
        _infoRow(
          Icons.location_on,
          addressText,
          iconSize,
          spacing,
          textSize,
          verticalMargin,
        ),
        _infoRow(
          Icons.phone,
          hospital["phone"] ?? "No phone number",
          iconSize,
          spacing,
          textSize,
          verticalMargin,
          onTap: () {
            if (hospital["phone"] != null &&
                hospital["phone"].toString().isNotEmpty) {
              makePhoneCall(hospital["phone"].toString());
            }
          },
        ),
        _infoRow(
          Icons.email,
          hospital["email"] ?? "No email provided",
          iconSize,
          spacing,
          textSize,
          verticalMargin,
        ),
        _infoRow(
          Icons.medical_services,
          hospital["type"] ?? "Unknown type",
          iconSize,
          spacing,
          textSize,
          verticalMargin,
        ),
        if (hospital["about"] != null && hospital["about"].toString().isNotEmpty)
          _infoRow(
            Icons.info,
            hospital["about"].toString(),
            iconSize,
            spacing,
            textSize,
            verticalMargin,
          ),
        if (hospital["emergencyContact"] != null &&
            hospital["emergencyContact"].toString().isNotEmpty &&
            hospital["emergencyContact"].toString() != "0" &&
            hospital["emergencyContact"].toString() != "00000000")
          _infoRow(
            Icons.emergency,
            "Emergency: ${hospital["emergencyContact"]}",
            iconSize,
            spacing,
            textSize,
            verticalMargin,
            onTap: () {
              makePhoneCall(hospital["emergencyContact"].toString());
            },
          ),
      ],
    );
  }

  Widget _infoRow(
    IconData icon,
    String text,
    double iconSize,
    double spacing,
    double textSize,
    double verticalMargin, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: verticalMargin),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.green, size: iconSize),
            SizedBox(width: spacing),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: textSize,
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