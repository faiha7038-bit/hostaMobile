
import 'package:flutter/material.dart';
import 'package:hosta/presentation/screens/hospital/widgets/mapview.dart';


class LocationTab extends StatelessWidget {
  final Map<String, dynamic> hospital;
  final double? userLatitude;
  final double? userLongitude;

  const LocationTab({
    super.key,
    required this.hospital,
    this.userLatitude,
    this.userLongitude,
  });

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
    final lat = hospital["latitude"]?.toString() ?? "0";
    final lng = hospital["longitude"]?.toString() ?? "0";
    final addressString = _getAddressString(hospital["address"]);
    
    return OSMMapView(
      latitude: double.tryParse(lat) ?? 0,
      longitude: double.tryParse(lng) ?? 0,
      hospitalName: hospital["name"] ?? "Hospital",
      address: addressString,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );
  }
}