import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';

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
      hasLocationPermission:
          hasLocationPermission ?? this.hasLocationPermission,
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

  void dispose() {
    _refreshTimer?.cancel();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _refreshLocationAndData();
    });
  }
Future<void> refreshAds() async {
  await _fetchCarouselImages(state.lastLat, state.lastLng);
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
  }

  Future<void> _refreshLocationAndData() async {
    try {
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
        await _fetchCarouselImages(null, null);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double newLat = position.latitude;
      double newLng = position.longitude;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_lat', newLat);
      await prefs.setDouble('last_lng', newLng);

      state = state.copyWith(lastLat: newLat, lastLng: newLng);
      await _fetchCarouselImages(newLat, newLng);
    } catch (e) {
      await _fetchCarouselImages(null, null);
    }
  }

  Future<void> refreshOnResume() async {
    await _checkLocationStatus();
    await _refreshLocationAndData();
  }

  Future<void> _getLocationAndFetchData() async {
    state = state.copyWith(isLoading: true);

    try {
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
        await _fetchCarouselImages(null, null);
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        state = state.copyWith(
          locationIssue: permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever,
          hasLocationPermission: permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever,
        );

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          await _fetchCarouselImages(null, null);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double lastLat = position.latitude;
      double lastLng = position.longitude;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_lat', lastLat);
      await prefs.setDouble('last_lng', lastLng);

      state = state.copyWith(lastLat: lastLat, lastLng: lastLng);
      await _fetchCarouselImages(lastLat, lastLng);
    } catch (e) {
      await _fetchCarouselImages(null, null);
    }
  }

  Future<void> _fetchCarouselImages(double? lat, double? lng) async {
    try {
      final bool hasLocation = lat != null && lng != null;

      final apiService = ApiService();
      final response = await apiService.getAllCarousel(
        latitude: lat,
        longitude: lng,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData != null &&
            responseData is Map<String, dynamic> &&
            responseData["ads"] != null) {
          final List ads = responseData["ads"] as List;

         
          const String s3BaseUrl =
              "https://hostahealthcare.s3.eu-north-1.amazonaws.com/";

          final List<String> images = ads
              .where((item) =>
                  item["isActive"] == true &&
                  (item["imageUrl"]?.toString().trim() ?? "").isNotEmpty)
              .map((item) {
            final image = item["imageUrl"].toString().trim();

         

            if (image.startsWith("http://") || image.startsWith("https://")) {
              return image;
            }

           
            return "$s3BaseUrl$image";
            
          }).toList();

          if (images.isNotEmpty) {
            state = state.copyWith(
              carouselImages: images,
              isLoading: false,
            );
            _fallbackAttempted = false;
            return;
          }

          if (hasLocation && !_fallbackAttempted) {
            _fallbackAttempted = true;
            await _fetchCarouselImages(null, null);
            return;
          }

          state = state.copyWith(
            carouselImages: [],
            isLoading: false,
          );
          _fallbackAttempted = false;
        } else {
          state = state.copyWith(
            carouselImages: [],
            isLoading: false,
          );
          _fallbackAttempted = false;
        }
      } else {
        state = state.copyWith(
          carouselImages: [],
          isLoading: false,
        );
        _fallbackAttempted = false;
      }
    } catch (e, stackTrace) {
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

final productsProvider = Provider<List<Map<String, dynamic>>>((ref) => [
      {"name": "Hospitals", "icon": Icons.local_hospital, "page": null},
      {
        "name": "Doctors",
        "icon": Icons.medical_services_outlined,
        "page": null
      },
      {"name": "Specialties", "icon": Icons.category_outlined, "page": null},
      {"name": "Ambulance", "icon": Icons.local_taxi_outlined, "page": null},
      {"name": "Blood", "icon": Icons.bloodtype_outlined, "page": null},
      {"name": "Medicine", "icon": Icons.local_pharmacy, "page": null},
    ]);
