

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationTab extends StatefulWidget {
  final Map<String, dynamic> hospital;
  final double? userLatitude;
  final double? userLongitude;

  const LocationTab({
    super.key,
    required this.hospital,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  State<LocationTab> createState() => _LocationTabState();
}

class _LocationTabState extends State<LocationTab> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  final Set<Marker> markers = {};

  late LatLng hospitalPosition;

  String _getAddressString(dynamic addr) {
    if (addr == null) return "Address not available";

    if (addr is String) return addr;

    if (addr is Map) {
      final parts = <String>[];

      if (addr['place'] != null &&
          addr['place'].toString().isNotEmpty) {
        parts.add(addr['place'].toString());
      }

      if (addr['district'] != null &&
          addr['district'].toString().isNotEmpty) {
        parts.add(addr['district'].toString());
      }

      if (addr['state'] != null &&
          addr['state'].toString().isNotEmpty) {
        parts.add(addr['state'].toString());
      }

      return parts.join(', ');
    }

    return "Address not available";
  }

  @override
  void initState() {
    super.initState();

    final lat = double.tryParse(
          widget.hospital["latitude"]?.toString() ?? "",
        ) ??
        0;

    final lng = double.tryParse(
          widget.hospital["longitude"]?.toString() ?? "",
        ) ??
        0;

    hospitalPosition = LatLng(lat, lng);

    _setMarker();
  }

  void _setMarker() {
    markers.clear();

    markers.add(
      Marker(
        markerId: const MarkerId("hospital"),
        position: hospitalPosition,
        infoWindow: InfoWindow(
          title: widget.hospital["name"] ?? "Hospital",
          snippet: _getAddressString(
            widget.hospital["address"],
          ),
        ),
      ),
    );

    // USER LOCATION MARKER
    if (widget.userLatitude != null &&
        widget.userLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("user"),
          position: LatLng(
            widget.userLatitude!,
            widget.userLongitude!,
          ),
          infoWindow: const InfoWindow(
            title: "Your Location",
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: hospitalPosition,
        zoom: 15,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
    );
  }
}