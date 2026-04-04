// import 'package:flutter/material.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:io' show Platform;
// import '../services/api_service.dart';
// import '../components/hospitaltypes.dart';
// import '../components/ambulance.dart';
// import '../components/blood.dart';
// import '../components/specialties.dart';
// import '../components/doctors.dart';

// class Home extends StatefulWidget {
//   const Home({super.key});

//   @override
//   State<Home> createState() => _HomeState();
// }

// class _HomeState extends State<Home> {
//   final List<Map<String, dynamic>> products = [
//     {"name": "Hospitals", "icon": Icons.local_hospital, "page": const HospitalTypes()},
//     {"name": "Doctors", "icon": Icons.medical_services_outlined, "page": const Doctors( hospitalId: "",
//           specialty: "",
//           )},
//     {"name": "Specialties", "icon": Icons.category_outlined, "page": const Specialties()},
//     {"name": "Ambulance", "icon": Icons.local_taxi_outlined, "page": const Ambulance()},
//     {"name": "Blood", "icon": Icons.bloodtype_outlined, "page": const Blood()},
//   ];

//   List<String> carouselImages = [];
//   bool isLoading = true;
//   Position? _currentPosition;
//   bool _locationDenied = false;

//   @override
//   void initState() {
//     super.initState();
//     _checkLocationAndFetchAds();
//   }

//   Future<void> _checkLocationAndFetchAds() async {
//     setState(() => isLoading = true);

//     try {
//       // Check if location service is enabled
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         // If location services are disabled, fetch ads without location
//         await _fetchCarouselImages();
//         return;
//       }

//       // Check location permission
//       LocationPermission permission = await Geolocator.checkPermission();
      
//       if (permission == LocationPermission.denied) {
//         // Check if we've already asked for permission before
//         final prefs = await SharedPreferences.getInstance();
//         bool hasAskedBefore = prefs.getBool('location_permission_asked') ?? false;
        
//         if (!hasAskedBefore) {
//           // First time - ask for permission
//           await prefs.setBool('location_permission_asked', true);
//           permission = await Geolocator.requestPermission();
          
//           if (permission == LocationPermission.denied) {
//             // User denied first time - fetch without location
//             setState(() => _locationDenied = true);
//             await _fetchCarouselImages();
//             return;
//           }
//         } else {
//           // Already asked before and denied - fetch without location
//           setState(() => _locationDenied = true);
//           await _fetchCarouselImages();
//           return;
//         }
//       }

//       if (permission == LocationPermission.deniedForever) {
//         // User permanently denied - fetch without location
//         setState(() => _locationDenied = true);
//         await _fetchCarouselImages();
//         return;
//       }

//       // We have permission - get location and fetch ads
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.medium,
//       );

//       setState(() {
//         _currentPosition = position;
//       });

//       // Fetch carousel images with location
//       await _fetchCarouselImages(
//         latitude: position.latitude,
//         longitude: position.longitude,
//       );

//     } catch (e) {
//       print("Error in location process: $e");
//       // If any error occurs, fetch ads without location
//       await _fetchCarouselImages();
//     }
//   }

//   Future<void> _fetchCarouselImages({double? latitude, double? longitude}) async {
//     try {
//       final response = await ApiService().getAllCarousel(
//         latitude: latitude,
//         longitude: longitude,
//       );

//       final data = response.data["data"] as List;
//       setState(() {
//         carouselImages = data
//             .where((item) => item["isActive"] == true && item["imageUrl"] != null)
//             .map<String>((item) => item["imageUrl"].toString())
//             .toList();
//       });
//     } catch (e) {
//       print("Error fetching carousel images: $e");
//       setState(() => carouselImages = []);
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   void _openLocationSettings() async {
//     await Geolocator.openLocationSettings();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenHeight = MediaQuery.of(context).size.height;
//     final screenWidth = MediaQuery.of(context).size.width;

//     // Platform-specific adjustments
//     final bool isAndroid = Platform.isAndroid;
//     final double carouselTopPadding = isAndroid ? 20.0 : 10.0;
//     final double carouselBottomPadding = isAndroid ? 15.0 : 10.0;

//     return Scaffold(
//       backgroundColor: const Color(0xFFECFDF5),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // ===== Carousel =====
//             if (isLoading)
//               SizedBox(
//                 height: screenHeight * 0.2,
//                 child: const Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       CircularProgressIndicator(),
//                       SizedBox(height: 10),
//                       Text(
//                         "Loading healthcare services...",
//                         style: TextStyle(fontSize: 14),
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//             else if (carouselImages.isEmpty)
//               SizedBox(
//                 height: screenHeight * 0.2,
//                 child: const Center(
//                   child: Text(
//                     "No Ads Available",
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                 ),
//               )
//             else
//               Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: 16.0, 
//                   vertical: carouselTopPadding,
//                 ),
//                 child: CarouselSlider(
//                   options: CarouselOptions(
//                     height: screenHeight * 0.20,
//                     autoPlay: true,
//                     enlargeCenterPage: true,
//                     viewportFraction: 0.9,
//                     autoPlayCurve: Curves.fastOutSlowIn,
//                     autoPlayAnimationDuration: const Duration(seconds: 2),
//                   ),
//                   items: carouselImages.map((imgUrl) {
//                     return ClipRRect(
//                       borderRadius: BorderRadius.circular(20),
//                       child: Image.network(
//                         imgUrl,
//                         fit: BoxFit.cover,
//                         width: double.infinity,
//                         loadingBuilder: (context, child, loadingProgress) {
//                           if (loadingProgress == null) return child;
//                           return const Center(child: CircularProgressIndicator());
//                         },
//                         errorBuilder: (context, error, stackTrace) =>
//                             const Center(child: Icon(Icons.error)),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),

//             SizedBox(height: isAndroid ? 12 : 6),

//             // Header Text
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Column(
//                 children: [
//                   const Text(
//                     "Find Nearby",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
//                   ),
//                   const Text(
//                     "Healthcare Services",
//                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: isAndroid ? 12 : 8),
                  
//                   // Location Warning Banner
//                   if (_locationDenied)
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.orange[50],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.orange),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(Icons.location_off, color: Colors.orange[800], size: 20),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               "Location disabled. Please enable Location.",
//                               style: TextStyle(
//                                 color: Colors.orange[800],
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                           TextButton(
//                             onPressed: _openLocationSettings,
//                             style: TextButton.styleFrom(
//                               padding: const EdgeInsets.symmetric(horizontal: 8),
//                               minimumSize: Size.zero,
//                               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                             ),
//                             child: Text(
//                               "Enable",
//                               style: TextStyle(
//                                 color: Colors.orange[800],
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//             SizedBox(height: isAndroid ? 12 : 8),

//             // ===== 2-column Grid =====
//             Expanded(
//               child: SingleChildScrollView(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // First row: 2 items
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           _buildCard(products[0], (screenWidth - 48) / 2, screenHeight * 0.14, context),
//                           _buildCard(products[1], (screenWidth - 48) / 2, screenHeight * 0.14, context),
//                         ],
//                       ),
//                       SizedBox(height: isAndroid ? 12 : 8),
//                       // Second row: 2 items
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           _buildCard(products[2], (screenWidth - 48) / 2, screenHeight * 0.14, context),
//                           _buildCard(products[3], (screenWidth - 48) / 2, screenHeight * 0.14, context),
//                         ],
//                       ),
//                       SizedBox(height: isAndroid ? 12 : 8),
//                       // Third row: 1 item (centered)
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           _buildCard(products[4], (screenWidth - 48) / 2, screenHeight * 0.14, context),
//                         ],
//                       ),
//                       SizedBox(height: isAndroid ? 20 : 16), // Extra padding at bottom
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCard(
//       Map<String, dynamic> item, double width, double height, BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(context, MaterialPageRoute(builder: (_) => item["page"]));
//       },
//       child: Container(
//         width: width,
//         height: height,
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           boxShadow: const [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 3,
//               spreadRadius: 1,
//             ),
//           ],
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(item["icon"], size: width * 0.25, color: const Color(0xFF28A745)),
//             const SizedBox(height: 8),
//             Text(
//               item["name"],
//               style: TextStyle(
//                 fontSize: width * 0.11 > 16 ? 16 : width * 0.11, // Limit max font size
//                 fontWeight: FontWeight.w600,
//               ),
//               textAlign: TextAlign.center,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'dart:async';
import '../../../services/api_service.dart';
import '../hospital_types/hospitaltypes.dart';
import '../ambulance/ambulance.dart';
import '../blood/blood.dart';
import '../speciality/specialties.dart';
import '../doctor/doctors.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  final List<Map<String, dynamic>> products = [
    {"name": "Hospitals", "icon": Icons.local_hospital, "page": const HospitalTypes()},
    {"name": "Doctors", "icon": Icons.medical_services_outlined, "page": const Doctors(hospitalId: "", specialty: "")},
    {"name": "Specialties", "icon": Icons.category_outlined, "page": const Specialties()},
    {"name": "Ambulance", "icon": Icons.local_taxi_outlined, "page": const Ambulance()},
    {"name": "Blood", "icon": Icons.bloodtype_outlined, "page": const Blood()},
  ];

  List<String> carouselImages = [];
  bool isLoading = true;
  bool locationIssue = false;
  bool hasLocationPermission = false;
  
  Timer? _refreshTimer;
  double? _lastLat;
  double? _lastLng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationStatus();
    _getLocationAndFetchData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_refreshTimer != null) {
      _refreshTimer!.cancel();
    }
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        print("🔄 ===== AUTO REFRESH EVERY 5 MINUTES =====");
        _refreshLocationAndData();
      }
    });
  }

  Future<void> _checkLocationStatus() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();
    
    setState(() {
      locationIssue = !serviceEnabled || 
                      permission == LocationPermission.denied || 
                      permission == LocationPermission.deniedForever;
      hasLocationPermission = serviceEnabled && 
                              permission != LocationPermission.denied && 
                              permission != LocationPermission.deniedForever;
    });
    
    print("📍 Location Status - Service: $serviceEnabled, Permission: $permission, Issue: $locationIssue");
  }

  Future<void> _refreshLocationAndData() async {
    if (!mounted) return;

    try {
      print("📍 Auto-refresh: Checking location services...");
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      // Update location status
      setState(() {
        locationIssue = !serviceEnabled || 
                        permission == LocationPermission.denied || 
                        permission == LocationPermission.deniedForever;
        hasLocationPermission = serviceEnabled && 
                                permission != LocationPermission.denied && 
                                permission != LocationPermission.deniedForever;
      });

      // If location is disabled or permission denied, fetch without location
      if (!serviceEnabled || 
          permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        print("⚠️ Auto-refresh: Location not available - refreshing without location");
        await _fetchCarouselImages(null, null);
        return;
      }

      // Get current location
      print("📍 Auto-refresh: Getting current position...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double newLat = position.latitude;
      double newLng = position.longitude;
      
      print("📍 Auto-refresh: New location - lat=$newLat, lng=$newLng");
      
      _lastLat = newLat;
      _lastLng = newLng;
      
      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_lat', newLat);
      await prefs.setDouble('last_lng', newLng);
      
      // Fetch with location
      await _fetchCarouselImages(newLat, newLng);
      
    } catch (e) {
      print("❌ Auto-refresh error: $e");
      await _fetchCarouselImages(null, null);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("🔄 App resumed - checking location and refreshing data");
      _checkLocationStatus(); // Check status when app resumes
      _refreshLocationAndData();
    }
  }

  Future<void> _getLocationAndFetchData() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      print("📍 Initial load: Checking location services...");
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      // Update location status
      setState(() {
        locationIssue = !serviceEnabled || 
                        permission == LocationPermission.denied || 
                        permission == LocationPermission.deniedForever;
        hasLocationPermission = serviceEnabled && 
                                permission != LocationPermission.denied && 
                                permission != LocationPermission.deniedForever;
      });

      // If location is disabled or permission denied, fetch without location
      if (!serviceEnabled || 
          permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        print("⚠️ Initial load: Location not available - fetching without location");
        await _fetchCarouselImages(null, null);
        return;
      }

      // Request permission if needed
      if (permission == LocationPermission.denied) {
        print("📍 Initial load: Requesting location permission...");
        permission = await Geolocator.requestPermission();
        
        setState(() {
          locationIssue = permission == LocationPermission.denied || 
                          permission == LocationPermission.deniedForever;
          hasLocationPermission = permission != LocationPermission.denied && 
                                  permission != LocationPermission.deniedForever;
        });
        
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

      _lastLat = position.latitude;
      _lastLng = position.longitude;
      
      print("📍 Initial load: Location obtained - lat=$_lastLat, lng=$_lastLng");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_lat', _lastLat!);
      await prefs.setDouble('last_lng', _lastLng!);

      await _fetchCarouselImages(_lastLat!, _lastLng!);
      
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
          
          if (!mounted) return;

          setState(() {
            carouselImages = data
                .where((item) => item["isActive"] == true && item["imageUrl"] != null)
                .map<String>((item) => item["imageUrl"].toString())
                .toList();
            isLoading = false;
          });
          
          print("✅ Successfully loaded ${carouselImages.length} active carousel images");
        } else {
          print("⚠️ No data in response");
          setState(() {
            carouselImages = [];
            isLoading = false;
          });
        }
      } else {
        print("❌ API returned error status: ${response.statusCode}");
        setState(() {
          carouselImages = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ ERROR fetching carousel images: $e");
      setState(() {
        carouselImages = [];
        isLoading = false;
      });
    }
  }

  void _openSettings() async {
    await Geolocator.openLocationSettings();
    // Wait a bit for settings to close and then recheck location status
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _checkLocationStatus();
        _refreshLocationAndData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isAndroid = Platform.isAndroid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Carousel
            if (isLoading)
              SizedBox(
                height: screenHeight * 0.2,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF28A745)),
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
                  horizontal: 16,
                  vertical: isAndroid ? 20 : 10,
                ),
                child: carouselImages.isEmpty
                    ? SizedBox(
                        height: screenHeight * 0.2,
                        child: const Center(
                          child: Text(
                            "No Ads Available",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ),
                      )
                    : CarouselSlider(
                        options: CarouselOptions(
                          height: screenHeight * 0.2,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          viewportFraction: 0.9,
                          autoPlayCurve: Curves.fastOutSlowIn,
                          autoPlayAnimationDuration: const Duration(seconds: 2),
                        ),
                        items: carouselImages.map((img) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              img,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(child: Icon(Icons.error, color: Colors.grey)),
                            ),
                          );
                        }).toList(),
                      ),
              ),

            // Header Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const Text(
                    "Find Nearby",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF6C757D)),
                  ),
                  const Text(
                    "Healthcare Services",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  ),
                  const SizedBox(height: 12),
                  
                  // Location Warning Banner - Now updates correctly
                  if (locationIssue)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_off, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 10),
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
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _openSettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: const Size(70, 32),
                            ),
                            child: const Text(
                              "Enable",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Grid Layout
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // First row: 2 items
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCard(products[0], (screenWidth - 48) / 2, screenHeight * 0.14, context),
                          _buildCard(products[1], (screenWidth - 48) / 2, screenHeight * 0.14, context),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Second row: 2 items
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCard(products[2], (screenWidth - 48) / 2, screenHeight * 0.14, context),
                          _buildCard(products[3], (screenWidth - 48) / 2, screenHeight * 0.14, context),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Third row: 1 item (centered)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCard(products[4], (screenWidth - 48) / 2, screenHeight * 0.14, context),
                        ],
                      ),
                      const SizedBox(height: 20),
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
      Map<String, dynamic> item, double width, double height, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => item["page"]));
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
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF28A745).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item["icon"], 
                size: width * 0.22, 
                color: const Color(0xFF28A745),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              item["name"],
              style: TextStyle(
                fontSize: width * 0.09 > 15 ? 15 : width * 0.09,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              height: 3,
              width: 30,
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