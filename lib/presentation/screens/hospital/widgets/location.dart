import 'package:flutter/material.dart';
import 'package:hosta/presentation/screens/hospital/widgets/loaction-mappreview.dart';

class LocationTab extends StatelessWidget {
  final Map<String, dynamic> hospital;
  final VoidCallback onOpenMaps;

  const LocationTab({
    super.key,
    required this.hospital,
    required this.onOpenMaps,
  });

  // Helper to convert address (Map or String) to a readable String
  String _getAddressString(dynamic addr) {
    if (addr == null) return "Address not available";
    if (addr is String) return addr;
    if (addr is Map) {
      final parts = <String>[];
      if (addr['place'] != null && addr['place'].toString().isNotEmpty) {
        parts.add(addr['place'].toString());
      }
      if (addr['district'] != null && addr['district'].toString().isNotEmpty) {
        parts.add(addr['district'].toString());
      }
      if (addr['state'] != null && addr['state'].toString().isNotEmpty) {
        parts.add(addr['state'].toString());
      }
      return parts.join(', ');
    }
    return "Address not available";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final lat = hospital["latitude"]?.toString() ?? "0";
    final lng = hospital["longitude"]?.toString() ?? "0";
    
    // Convert address to readable string
    final addressString = _getAddressString(hospital["address"]);
    
    // Check if coordinates are valid
    if (lat == "0" && lng == "0") {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: screenWidth * 0.16,
              color: Colors.grey,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              "Location not available",
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Map Preview
        Expanded(
          child: LocationMapPreview(
            latitude: double.tryParse(lat) ?? 0,
            longitude: double.tryParse(lng) ?? 0,
            hospitalName: hospital["name"] ?? "Hospital",
            address: addressString, // ✅ Now a String, not a Map
          ),
        ),
        
        // Open in Maps Button
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: ElevatedButton.icon(
            onPressed: onOpenMaps,
            icon: Icon(
              Icons.open_in_new,
              color: Colors.white,
              size: screenWidth * 0.05,
            ),
            label: Text(
              "Open in Google Maps",
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.04,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
            ),
          ),
        ),
      ],
    );
  }
}