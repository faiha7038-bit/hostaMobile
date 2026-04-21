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

  @override
  Widget build(BuildContext context) {
    final lat = hospital["latitude"]?.toString() ?? "0";
    final lng = hospital["longitude"]?.toString() ?? "0";
    
    // Check if coordinates are valid
    if (lat == "0" && lng == "0") {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Location not available",
              style: TextStyle(fontSize: 16, color: Colors.grey),
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
            address: hospital["address"] ?? "",
          ),
        ),
        
        // Open in Maps Button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: onOpenMaps,
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            label: const Text(
              "Open in Google Maps",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}