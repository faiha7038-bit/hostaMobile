import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:hosta/presentation/screens/reminder/medicine_reminder.dart';
import 'package:hosta/providers/home_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../hospital/hospitaltypes.dart';
import '../ambulance/ambulance.dart';
import '../blood/blood.dart';
import '../speciality/specialties.dart';
import '../doctor/doctors.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> with WidgetsBindingObserver {
  final List<Map<String, dynamic>> products = [
    {
      "name": "Hospitals",
      "icon": Icons.local_hospital,
      "page": const HospitalTypes()
    },
    {
      "name": "Doctors",
      "icon": Icons.medical_services_outlined,
      "page": const Doctors(hospitalId: "", specialty: "")
    },
    {
      "name": "Specialties",
      "icon": Icons.category_outlined,
      "page": const Specialties()
    },
    {
      "name": "Ambulance",
      "icon": Icons.local_taxi_outlined,
      "page": const Ambulance()
    },
    {"name": "Blood", "icon": Icons.bloodtype_outlined, "page": const Blood()},
    {
      "name": "Medicine Reminder",
      "icon": Icons.local_pharmacy,
      "page": ReminderScreen()
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(homeProvider.notifier).init();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Doctors(hospitalId: finalHospitalId, specialty: ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isAndroid = Platform.isAndroid;

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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF28A745)),
                      ),
                      SizedBox(height: 10),
                      Text("Loading healthcare services...",
                          style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical:
                      isAndroid ? screenHeight * 0.025 : screenHeight * 0.012,
                ),
                child: homeState.carouselImages.isEmpty
                    ? SizedBox(
                        height: carouselHeight,
                        child: const Center(
                          child: Text("No Ads Available",
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey)),
                        ),
                      )
                    :
                 CarouselSlider(
  options: CarouselOptions(
    height: carouselHeight,
    viewportFraction: 1.0,
    enlargeCenterPage: false,
    autoPlay: homeState.carouselImages.length > 1,
    enableInfiniteScroll: homeState.carouselImages.length > 1,
    autoPlayInterval: const Duration(seconds: 3),
    autoPlayAnimationDuration: const Duration(milliseconds: 800),
    autoPlayCurve: Curves.fastOutSlowIn,
  ),
  items: homeState.carouselImages.map((img) {
    return Builder(
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              img,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;

                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                
                return Container(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }).toList(),
)
              ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  const Text("Find Nearby",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6C757D))),
                  const Text("Healthcare Services",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50))),
                  SizedBox(height: screenHeight * 0.015),
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
                          Icon(Icons.location_off,
                              color: Colors.orange.shade700,
                              size: screenWidth * 0.05),
                          SizedBox(width: screenWidth * 0.025),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Location is turned off",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFFE67E22))),
                                Text("Enable location for better results",
                                    style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: screenWidth * 0.028)),
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
                                  vertical: screenHeight * 0.01),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              minimumSize:
                                  Size(screenWidth * 0.18, screenHeight * 0.04),
                            ),
                            child: Text("Enable",
                                style: TextStyle(
                                    fontSize: screenWidth * 0.032,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.015),

            // Grid
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCard(products[0], cardWidth, cardHeight,
                              context, screenWidth),
                          _buildCard(products[1], cardWidth, cardHeight,
                              context, screenWidth),
                        ],
                      ),
                      SizedBox(height: cardSpacing),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCard(products[2], cardWidth, cardHeight,
                              context, screenWidth),
                          _buildCard(products[3], cardWidth, cardHeight,
                              context, screenWidth),
                        ],
                      ),
                      SizedBox(height: cardSpacing),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildCard(products[4], cardWidth, cardHeight,
                              context, screenWidth),
                          _buildCard(products[5], cardWidth, cardHeight,
                              context, screenWidth),
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
    final double iconSize = (width * 0.22).clamp(24.0, 60.0);
    final double fontSize = (width * 0.09).clamp(12.0, 18.0);
    final double padding = (width * 0.07).clamp(8.0, 20.0);
    final double topSpacing =
        (height * 0.06).clamp(4.0, 12.0); // space between icon and text
    final double bottomSpacing =
        (height * 0.04).clamp(2.0, 8.0); // space below text (before line)

    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => item["page"])),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Colors.white, const Color(0xFFF8F9FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // centers the whole group
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: const Color(0xFF28A745).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item["icon"],
                  size: iconSize, color: const Color(0xFF28A745)),
            ),
            SizedBox(height: topSpacing),
            // Name
            Flexible(
              child: Text(
                item["name"],
                style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E50)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: bottomSpacing),
            // Decorative line
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
