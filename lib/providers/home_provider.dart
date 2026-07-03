import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';

// ============= STATE MODEL =============
class HomeState {
  final List<String> carouselImages;
  final bool isLoading;
  final bool locationIssue;
  final bool hasLocationPermission;
  final double? lastLat;
  final double? lastLng;

  HomeState({
    this.carouselImages = const [],
    this.isLoading = true,
    this.locationIssue = false,
    this.hasLocationPermission = false,
    this.lastLat,
    this.lastLng,
  });

  HomeState copyWith({
    List<String>? carouselImages,
    bool? isLoading,
    bool? locationIssue,
    bool? hasLocationPermission,
    double? lastLat,
    double? lastLng,
  }) {
    return HomeState(
      carouselImages: carouselImages ?? this.carouselImages,
      isLoading: isLoading ?? this.isLoading,
      locationIssue: locationIssue ?? this.locationIssue,
      hasLocationPermission: hasLocationPermission ?? this.hasLocationPermission,
      lastLat: lastLat ?? this.lastLat,
      lastLng: lastLng ?? this.lastLng,
    );
  }
}

// ============= NOTIFIER =============
class HomeNotifier extends StateNotifier<HomeState> {
  Timer? _refreshTimer;
  bool _isInitialized = false;
bool _fallbackAttempted = false;
  HomeNotifier() : super(HomeState());

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _checkLocationStatus();
    await _getLocationAndFetchData();
    _startAutoRefresh();
  }

  // This method will be called via ref.onDispose
  void dispose() {
    _refreshTimer?.cancel();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      print("🔄 ===== AUTO REFRESH EVERY 5 MINUTES =====");
      await _refreshLocationAndData();
    });
  }

  Future<void> _checkLocationStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    state = state.copyWith(
      locationIssue: !serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever,
      hasLocationPermission: serviceEnabled &&
          permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever,
    );

    print("📍 Updated Location Status → Service: $serviceEnabled, Permission: $permission");
  }

  Future<void> _refreshLocationAndData() async {
    try {
      print("📍 Auto-refresh: Checking location services...");
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      state = state.copyWith(
        locationIssue: !serviceEnabled ||
            permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever,
        hasLocationPermission: serviceEnabled &&
            permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever,
      );

      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("⚠️ Auto-refresh: Location not available - refreshing without location");
        await _fetchCarouselImages(null, null);
        return;
      }

      print("📍 Auto-refresh: Getting current position...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double newLat = position.latitude;
      double newLng = position.longitude;

      print("📍 Auto-refresh: New location - lat=$newLat, lng=$newLng");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_lat', newLat);
      await prefs.setDouble('last_lng', newLng);

      state = state.copyWith(lastLat: newLat, lastLng: newLng);
      await _fetchCarouselImages(newLat, newLng);
    } catch (e) {
      print("❌ Auto-refresh error: $e");
      await _fetchCarouselImages(null, null);
    }
  }

  Future<void> refreshOnResume() async {
    print("🔄 App resumed - checking location and refreshing data");
    await _checkLocationStatus();
    await _refreshLocationAndData();
  }

  Future<void> _getLocationAndFetchData() async {
    state = state.copyWith(isLoading: true);

    try {
      print("📍 Initial load: Checking location services...");
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      state = state.copyWith(
        locationIssue: !serviceEnabled ||
            permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever,
        hasLocationPermission: serviceEnabled &&
            permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever,
      );

      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("⚠️ Initial load: Location not available - fetching without location");
        await _fetchCarouselImages(null, null);
        return;
      }

      if (permission == LocationPermission.denied) {
        print("📍 Initial load: Requesting location permission...");
        permission = await Geolocator.requestPermission();

        state = state.copyWith(
          locationIssue: permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever,
          hasLocationPermission: permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever,
        );

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          print("⚠️ Initial load: Permission denied - fetching without location");
          await _fetchCarouselImages(null, null);
          return;
        }
      }

      print("📍 Initial load: Getting current position...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double lastLat = position.latitude;
      double lastLng = position.longitude;

      print("📍 Initial load: Location obtained - lat=$lastLat, lng=$lastLng");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_lat', lastLat);
      await prefs.setDouble('last_lng', lastLng);

      state = state.copyWith(lastLat: lastLat, lastLng: lastLng);
      await _fetchCarouselImages(lastLat, lastLng);
    } catch (e) {
      print("❌ Initial load error: $e - fetching without location");
      await _fetchCarouselImages(null, null);
    }
  }



Future<void> _fetchCarouselImages(double? lat, double? lng) async {
  try {
    // Determine if this is a location-based call
    final bool hasLocation = lat != null && lng != null;
    if (hasLocation) {
      print("🌐 Calling API WITH location: lat=$lat, lng=$lng");
    } else {
      print("🌐 Calling API WITHOUT location (fallback or initial)");
    }

    final apiService = ApiService();
    final response = await apiService.getAllCarousel(
      latitude: lat,
      longitude: lng,
    );

    print("📡 Status Code: ${response.statusCode}");
    print("📡 Response: ${response.data}");

    if (response.statusCode == 200) {
      final responseData = response.data;

      if (responseData != null &&
          responseData is Map<String, dynamic> &&
          responseData["ads"] != null) {

        final List ads = responseData["ads"] as List;
        print("📸 Total Ads: ${ads.length}");

        // Extract valid image URLs (isActive == true and non-empty imageUrl)
        final List<String> images = ads
            .where((item) =>
                item["isActive"] == true &&
                (item["imageUrl"]?.toString().trim() ?? '').isNotEmpty)
            .map((item) => item["imageUrl"].toString())
            .toList();

        print("✅ Valid Images Count: ${images.length}");
        print(images);

        // If we have images, update state and reset fallback flag
        if (images.isNotEmpty) {
          state = state.copyWith(
            carouselImages: images,
            isLoading: false,
          );
          _fallbackAttempted = false; // reset for next time
          return;
        }

        // ----- FALLBACK LOGIC -----
        // If we are currently using location and got zero images,
        // and we haven't tried fallback yet, retry without location.
        if (hasLocation && !_fallbackAttempted) {
          print("🔄 No nearby ads with images – falling back to fetch ALL ads without location");
          _fallbackAttempted = true; // prevent infinite loop
          // Call the same function with null location
          await _fetchCarouselImages(null, null);
          return;
        }

        // If we reached here (either no location or fallback already tried),
        // and still no images, set empty list.
        print("⚠️ No valid carousel images available (fallback exhausted or no location).");
        state = state.copyWith(
          carouselImages: [],
          isLoading: false,
        );
        _fallbackAttempted = false; // reset for next refresh
      } else {
        print("⚠️ 'ads' key not found or invalid response structure.");
        state = state.copyWith(
          carouselImages: [],
          isLoading: false,
        );
        _fallbackAttempted = false;
      }
    } else {
      print("❌ API Error: ${response.statusCode}");
      state = state.copyWith(
        carouselImages: [],
        isLoading: false,
      );
      _fallbackAttempted = false;
    }
  } catch (e, stackTrace) {
    print("❌ Error fetching carousel images");
    print(e);
    print(stackTrace);
    state = state.copyWith(
      carouselImages: [],
      isLoading: false,
    );
    _fallbackAttempted = false;
  }
}

  Future<void> openSettings() async {
    await Geolocator.openLocationSettings();
  }
}

// ============= PROVIDERS =============
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final notifier = HomeNotifier();
  // Automatically dispose the notifier when the provider is removed
  ref.onDispose(notifier.dispose);
  return notifier;
});

// Products list provider (static) – only one definition
final productsProvider = Provider<List<Map<String, dynamic>>>((ref) => [
  {"name": "Hospitals", "icon": Icons.local_hospital, "page": null},
  {"name": "Doctors", "icon": Icons.medical_services_outlined, "page": null},
  {"name": "Specialties", "icon": Icons.category_outlined, "page": null},
  {"name": "Ambulance", "icon": Icons.local_taxi_outlined, "page": null},
  {"name": "Blood", "icon": Icons.bloodtype_outlined, "page": null},
  {"name": "Medicine", "icon": Icons.local_pharmacy, "page": null},
]);