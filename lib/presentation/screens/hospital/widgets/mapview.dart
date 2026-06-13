
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OSMMapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String hospitalName;
  final String address;
  final double? userLatitude;
  final double? userLongitude;

  const OSMMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.hospitalName,
    required this.address,
    this.userLatitude,
    this.userLongitude,
  });

  @override
  State<OSMMapView> createState() => _OSMMapViewState();
}

class _OSMMapViewState extends State<OSMMapView> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMap();
  }

  void _loadMap() {
    double lat = widget.latitude;
    double lng = widget.longitude;
    
    // Fix invalid coordinates
    if (lat < -90 || lat > 90 || lat == 0 || lat == 123456789) {
      lat = widget.userLatitude ?? 11.03614;
      lng = widget.userLongitude ?? 76.10219;
    }
    
    final hasUser = widget.userLatitude != null && widget.userLongitude != null;
    
    final String html = """
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=yes">
        <style>
            body, html { margin: 0; padding: 0; height: 100%; width: 100%; }
            #map { height: 100%; width: 100%; }
        </style>
        <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
        <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    </head>
    <body>
        <div id="map"></div>
        <script>
            var hospitalLat = $lat;
            var hospitalLng = $lng;
            var hasUser = ${hasUser ? 'true' : 'false'};
            var userLat = ${widget.userLatitude ?? 0};
            var userLng = ${widget.userLongitude ?? 0};
            
            var map = L.map('map').setView([hospitalLat, hospitalLng], 16);
            
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '© OpenStreetMap'
            }).addTo(map);
            
            // Hospital marker
            L.marker([hospitalLat, hospitalLng]).bindPopup('<b>${widget.hospitalName}</b><br>${widget.address}').addTo(map).openPopup();
            
            ${hasUser ? '''
            // User marker
            L.marker([userLat, userLng]).bindPopup('<b>Your Location</b>').addTo(map);
            
            // Route line
            L.polyline([[userLat, userLng], [hospitalLat, hospitalLng]], {color: 'blue', weight: 3}).addTo(map);
            
            // Fit both locations
            var bounds = L.latLngBounds([[userLat, userLng], [hospitalLat, hospitalLng]]);
            map.fitBounds(bounds);
            ''' : ''}
        </script>
    </body>
    </html>
    """;
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) => setState(() => isLoading = false),
          onWebResourceError: (error) => setState(() => isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse('data:text/html;charset=utf-8,${Uri.encodeComponent(html)}'));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (isLoading)
          const Center(child: CircularProgressIndicator(color: Colors.green)),
      ],
    );
  }
}