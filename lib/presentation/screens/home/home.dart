import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hosta/presentation/screens/reminder/medicine_reminder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_service.dart';
import '../hospital/hospitaltypes.dart';
import '../ambulance/ambulance.dart';
import '../blood/blood.dart';
import '../speciality/specialties.dart';
import '../doctor/doctors.dart';

// ============= PROVIDER SECTION =============

// Products list provider (static)
final productsProvider = Provider<List<Map<String, dynamic>>>(
  (ref) => [
    {
      "name": "Hospitals",
      "icon": Icons.local_hospital,
      "page": const HospitalTypes(),
    },
    {
      "name": "Doctors",
      "icon": Icons.medical_services_outlined,
      "page": const Doctors(hospitalId: "", specialty: ""),
    },
    {
      "name": "Specialties",
      "icon": Icons.category_outlined,
      "page": const Specialties(),
    },
    {
      "name": "Ambulance",
      "icon": Icons.local_taxi_outlined,
      "page": const Ambulance(),
    },
    {"name": "Blood", "icon": Icons.bloodtype_outlined, "page": const Blood()},
    {
      "name": "Medicine",
      "icon": Icons.local_pharmacy,
      "page": const ReminderScreen(),
    },
  ],
);

// Home state
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

// Home notifier
class HomeNotifier extends StateNotifier<HomeState> {
  Timer? _refreshTimer;
 bool _isInitialized = false;
  HomeNotifier() : super(HomeState());

  // void init() {
  //   _checkLocationStatus();
  //   _getLocationAndFetchData();
  //   _startAutoRefresh();

  // }
  Future<void> init() async {  // ← async ചേർത്തു
  if (_isInitialized) return;  // ← ഈ line add ചെയ്യുക
  _isInitialized = true;  // ← ഈ line add ചെയ്യുക
  
  await _checkLocationStatus();  // ← await ചേർത്തു
  await _getLocationAndFetchData();  // ← await ചേർത്തു
  _startAutoRefresh();
}

  void dispose() {
    if (_refreshTimer != null) {
      _refreshTimer!.cancel();
    }
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
      locationIssue:
          !serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever,
      hasLocationPermission:
          serviceEnabled &&
          permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever,
    );

    print(
      "📍 Updated Location Status → Service: $serviceEnabled, Permission: $permission",
    );
  }

  Future<void> _refreshLocationAndData() async {
    try {
      print("📍 Auto-refresh: Checking location services...");
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      state = state.copyWith(
        locationIssue:
            !serviceEnabled ||
            permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever,
        hasLocationPermission:
            serviceEnabled &&
            permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever,
      );

      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print(
          "⚠️ Auto-refresh: Location not available - refreshing without location",
        );
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
        locationIssue:
            !serviceEnabled ||
            permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever,
        hasLocationPermission:
            serviceEnabled &&
            permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever,
      );

      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print(
          "⚠️ Initial load: Location not available - fetching without location",
        );
        await _fetchCarouselImages(null, null);
        return;
      }

      if (permission == LocationPermission.denied) {
        print("📍 Initial load: Requesting location permission...");
        permission = await Geolocator.requestPermission();

        state = state.copyWith(
          locationIssue:
              permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever,
          hasLocationPermission:
              permission != LocationPermission.denied &&
              permission != LocationPermission.deniedForever,
        );

        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          print(
            "⚠️ Initial load: Permission denied - fetching without location",
          );
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
      if (lat != null && lng != null) {
        print("🌐 Calling API WITH location: lat=$lat, lng=$lng");
      } else {
        print("🌐 Calling API WITHOUT location");
      }

      final apiService = ApiService();
      final response = await apiService.getAllCarousel(
        latitude: lat,
        longitude: lng,
      );

      print("📡 API Response Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        if (response.data != null && response.data["data"] != null) {
          final data = response.data["data"] as List;
          print("📸 Found ${data.length} carousel items");

          final images = data
              .where(
                (item) => item["isActive"] == true && item["imageUrl"] != null,
              )
              .map<String>((item) => item["imageUrl"].toString())
              .toList();

          state = state.copyWith(carouselImages: images, isLoading: false);

          print(
            "✅ Successfully loaded ${images.length} active carousel images",
          );
        } else {
          print("⚠️ No data in response");
          state = state.copyWith(carouselImages: [], isLoading: false);
        }
      } else {
        print("❌ API returned error status: ${response.statusCode}");
        state = state.copyWith(carouselImages: [], isLoading: false);
      }
    } catch (e) {
      print("❌ ERROR fetching carousel images: $e");
      state = state.copyWith(carouselImages: [], isLoading: false);
    }
  }

  Future<void> openSettings() async {
    await Geolocator.openLocationSettings();
  }
}

// Home provider
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
});

// ============= UI SECTION =============

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> with WidgetsBindingObserver {
 // late final HomeNotifier _homeNotifier;  // Store the notifier reference
  final List<Map<String, dynamic>> products = [
    {
      "name": "Hospitals",
      "icon": Icons.local_hospital,
      "page": const HospitalTypes(),
    },
    {
      "name": "Doctors",
      "icon": Icons.medical_services_outlined,
      "page": const Doctors(hospitalId: "", specialty: ""),
    },
    {
      "name": "Specialties",
      "icon": Icons.category_outlined,
      "page": const Specialties(),
    },
    {
      "name": "Ambulance",
      "icon": Icons.local_taxi_outlined,
      "page": const Ambulance(),
    },
    {"name": "Blood", "icon": Icons.bloodtype_outlined, "page": const Blood()},
    {
      "name": "Medicine",
      "icon": Icons.local_pharmacy,
      "page": ReminderScreen()
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Store the notifier reference here
   // _homeNotifier = ref.read(homeProvider.notifier);
   // _homeNotifier.init();
 WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      ref.read(homeProvider.notifier).init();
    }
  });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Use the stored reference, NOT ref.read()
    //_homeNotifier.dispose();
     //ref.read(homeProvider.notifier).dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(homeProvider.notifier).refreshOnResume();
      }
    });  
    }
  }
  

  Future<void> _navigateToDoctors(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    String? hospitalId = prefs.getString('selected_hospital_id');

     String finalHospitalId = hospitalId ?? '4';

    if (hospitalId == null || hospitalId.isEmpty) {
      hospitalId = '4';
    }
    
    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Doctors(
          hospitalId: finalHospitalId,
          specialty: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isAndroid = Platform.isAndroid;

    // Responsive calculations
    final double carouselHeight = screenHeight * 0.22;
    final double cardHeight = screenHeight * 0.14;
    final double horizontalPadding = screenWidth * 0.04;
    final double cardSpacing = screenWidth * 0.035;
    final double cardWidth =
        (screenWidth - (horizontalPadding * 2) - cardSpacing) / 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Carousel
            if (homeState.isLoading)
              SizedBox(
                height: carouselHeight,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF28A745),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Loading healthcare services...",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isAndroid
                      ? screenHeight * 0.025
                      : screenHeight * 0.012,
                ),
                child: homeState.carouselImages.isEmpty
                    ? SizedBox(
                        height: carouselHeight,
                        child: const Center(
                          child: Text(
                            "No Ads Available",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      )
                    : CarouselSlider(
                        options: CarouselOptions(
                          height: carouselHeight,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          viewportFraction: 0.9,
                          autoPlayCurve: Curves.fastOutSlowIn,
                          autoPlayAnimationDuration: const Duration(seconds: 2),
                        ),
                        items: homeState.carouselImages.map((img) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              img,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(
                                      Icons.error,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                          );
                        }).toList(),
                      ),
              ),

            // Header Text
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  const Text(
                    "Find Nearby",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                  const Text(
                    "Healthcare Services",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),

                  // Location Warning Banner - Now updates correctly
                  if (homeState.locationIssue)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_off,
                            color: Colors.orange.shade700,
                            size: screenWidth * 0.05,
                          ),
                          SizedBox(width: screenWidth * 0.025),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Location is turned off",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFFE67E22),
                                  ),
                                ),
                                Text(
                                  "Enable location for better results",
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: screenWidth * 0.028,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                ref.read(homeProvider.notifier).openSettings(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                                vertical: screenHeight * 0.01,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: Size(
                                screenWidth * 0.18,
                                screenHeight * 0.04,
                              ),
                            ),
                            child: Text(
                              "Enable",
                              style: TextStyle(
                                fontSize: screenWidth * 0.032,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.015),

            // Grid Layout
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // First row: 2 items
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCard(
                            products[0],
                            cardWidth,
                            cardHeight,
                            context,
                            screenWidth,
                          ),
                          _buildCard(
                            products[1],
                            cardWidth,
                            cardHeight,
                            context,
                            screenWidth,
                          ),
                        ],
                      ),
                      SizedBox(height: cardSpacing),
                      // Second row: 2 items
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCard(
                            products[2],
                            cardWidth,
                            cardHeight,
                            context,
                            screenWidth,
                          ),
                          _buildCard(
                            products[3],
                            cardWidth,
                            cardHeight,
                            context,
                            screenWidth,
                          ),
                        ],
                      ),
                      SizedBox(height: cardSpacing),
                      // Third row: 2 items
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCard(
                            products[4],
                            cardWidth,
                            cardHeight,
                            context,
                            screenWidth,
                          ),
                          _buildCard(
                            products[5],
                            cardWidth,
                            cardHeight,
                            context,
                            screenWidth,
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.025),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    Map<String, dynamic> item,
    double width,
    double height,
    BuildContext context,
    double screenWidth,
  ) {
    // Responsive icon size
    final double iconSize = width * 0.22;
    final double fontSize = width * 0.09 > 15 ? 15 : width * 0.09;
    final double padding = width * 0.07;
    final double topSpacing = height * 0.08;
    final double bottomSpacing = height * 0.045;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => item["page"]),
        );
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, const Color(0xFFF8F9FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: const Color(0xFF28A745).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item["icon"],
                size: iconSize,
                color: const Color(0xFF28A745),
              ),
            ),
            SizedBox(height: topSpacing),
            Text(
              item["name"],
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: bottomSpacing),
            Container(
              height: 3,
              width: screenWidth * 0.08,
              decoration: BoxDecoration(
                color: const Color(0xFF28A745).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
