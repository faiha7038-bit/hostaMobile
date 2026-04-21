import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LocationMapPreview extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String hospitalName;
  final String address;

  const LocationMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.hospitalName,
    required this.address,
  });

  @override
  State<LocationMapPreview> createState() => _LocationMapPreviewState();
}

class _LocationMapPreviewState extends State<LocationMapPreview> {
  late final WebViewController _controller;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    final mapsUrl = _getGoogleMapsUrl();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print("WebView loading: $progress%");
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() => isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            print("WebView error: ${error.description}");
            setState(() {
              isLoading = false;
              hasError = true;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(mapsUrl));
  }

  String _getGoogleMapsUrl() {
    // Use OpenStreetMap as a free alternative that works without API key
    // This will show a proper interactive map
    return "https://www.openstreetmap.org/export/embed.html?bbox=${widget.longitude-0.01}%2C${widget.latitude-0.01}%2C${widget.longitude+0.01}%2C${widget.latitude+0.01}&layer=mapnik&marker=${widget.latitude}%2C${widget.longitude}";
  }

  String _getAlternativeMapUrl() {
    // Alternative: Use Google Maps with simple search (no API key needed for basic display)
    final query = "${widget.hospitalName} ${widget.address}".trim();
    if (query.isNotEmpty) {
      return "https://maps.google.com/maps?q=${Uri.encodeComponent(query)}&output=embed";
    } else {
      return "https://maps.google.com/maps?q=${widget.latitude},${widget.longitude}&output=embed";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // WebView
        WebViewWidget(controller: _controller),

        // Loading Indicator
        if (isLoading)
          Container(
            color: Colors.white,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    "Loading map...",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

        // Error Message
        if (hasError && !isLoading)
          Container(
            color: Colors.grey[100],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "Map not available",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _initializeWebView,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text("Retry", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),

        // Hospital Info Overlay
        if (!isLoading && !hasError)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.hospitalName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (widget.address.isNotEmpty)
                    Text(
                      widget.address,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}