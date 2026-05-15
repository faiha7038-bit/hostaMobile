import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hosta/presentation/screens/hospital/hospital_details.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/api_service.dart';

class Hospitals extends StatefulWidget {
  final String type;
  const Hospitals({super.key, required this.type});

  @override
  State<Hospitals> createState() => _HospitalsState();
}

class _HospitalsState extends State<Hospitals> {
  bool isLoading = true;
  List<dynamic> hospitals = [];

  String searchQuery = '';
  bool filterNearest = false;
  bool filterOpenNow = false;
  Position? userPosition;

  @override
  void initState() {
    super.initState();
    _fetchHospitals();
  }

  Future<void> _fetchHospitals() async {
    try {
      setState(() => isLoading = true);

      // Fetch ALL hospitals (no type filter)
      final response = await ApiService().getAllHospitals();

      setState(() {
        List allHospitals = [];
        if (response.data is Map && response.data['data'] is List) {
          allHospitals = response.data['data'];
        } else if (response.data is List) {
          allHospitals = response.data;
        }

        // Filter by type on client side
        hospitals = allHospitals.where((hospital) {
          final hospitalType = hospital['type']?.toString().toLowerCase() ?? '';
          return hospitalType == widget.type.toLowerCase();
        }).toList();

        print(
            "✅ Total: ${allHospitals.length}, Filtered (${widget.type}): ${hospitals.length}");
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error: $e");
      setState(() => isLoading = false);
    }
  }

  // 👇 Helper method (kept as is, not used now but harmless)
  String _mapTypeToBackend(String frontendType) {
    if (frontendType.toLowerCase() == 'allopathy') {
      return 'alopathy';
    }
    return frontendType;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _ensureLocationEnabled() async {
    final screenWidth = MediaQuery.of(context).size.width;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationDialog("Please enable your location services.", screenWidth);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationDialog("Location permission denied.", screenWidth);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationDialog(
          "Location permission permanently denied. Enable it from app settings.",
          screenWidth);
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() => userPosition = pos);
  }

  void _showLocationDialog(String message, double screenWidth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Location Required",
          style: TextStyle(fontSize: screenWidth * 0.045),
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: screenWidth * 0.04),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(fontSize: screenWidth * 0.04),
            ),
          ),
        ],
      ),
    );
  }

  bool _isOpenNow(Map<String, dynamic> hospital) {
    final workingHoursClinic = hospital["working_hours_clinic"] as List<dynamic>?;
    if (workingHoursClinic != null && workingHoursClinic.isNotEmpty) {
      return _isOpenNowNewFormat(hospital);
    }

    final workingHours = hospital["working_hours"] as List<dynamic>?;
    if (workingHours == null || workingHours.isEmpty) return false;

    final now = DateTime.now();
    final today = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ][now.weekday - 1];

    final todayHours = workingHours.firstWhere(
      (day) => day["day"] == today,
      orElse: () => null,
    );

    if (todayHours == null || todayHours["is_holiday"] == true) return false;

    final open = todayHours["opening_time"];
    final close = todayHours["closing_time"];
    if (open == null || close == null) return false;

    try {
      int nowMinutes = now.hour * 60 + now.minute;
      final openParts = open.split(":");
      int openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);

      final closeParts = close.split(":");
      int closeMinutes = int.parse(closeParts[0]) * 60 +
          int.parse(closeParts[1]);

      if (closeMinutes < openMinutes) {
        return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
      } else {
        return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
      }
    } catch (_) {
      return false;
    }
  }

  bool _isOpenNowNewFormat(Map<String, dynamic> hospital) {
    final workingHoursClinic = hospital["working_hours_clinic"] as List<dynamic>?;
    if (workingHoursClinic == null || workingHoursClinic.isEmpty) return false;

    final now = DateTime.now();
    final today = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday"
    ][now.weekday - 1];

    final todayHours = workingHoursClinic.firstWhere(
      (day) => day["day"] == today,
      orElse: () => null,
    );

    if (todayHours == null || todayHours["is_holiday"] == true) return false;

    final morningSession = todayHours["morning_session"];
    final eveningSession = todayHours["evening_session"];

    try {
      int nowMinutes = now.hour * 60 + now.minute;

      if (morningSession != null &&
          morningSession["open"] != null &&
          morningSession["open"]!.isNotEmpty) {
        final morningOpen = morningSession["open"].split(":");
        final morningClose = morningSession["close"].split(":");

        int morningOpenMinutes = int.parse(morningOpen[0]) * 60 +
            int.parse(morningOpen[1]);
        int morningCloseMinutes = int.parse(morningClose[0]) * 60 +
            int.parse(morningClose[1]);

        if (nowMinutes >= morningOpenMinutes &&
            nowMinutes <= morningCloseMinutes) {
          return true;
        }
      }

      if (eveningSession != null &&
          eveningSession["open"] != null &&
          eveningSession["open"]!.isNotEmpty) {
        final eveningOpen = eveningSession["open"].split(":");
        final eveningClose = eveningSession["close"].split(":");

        int eveningOpenMinutes = int.parse(eveningOpen[0]) * 60 +
            int.parse(eveningOpen[1]);
        int eveningCloseMinutes = int.parse(eveningClose[0]) * 60 +
            int.parse(eveningClose[1]);

        if (nowMinutes >= eveningOpenMinutes &&
            nowMinutes <= eveningCloseMinutes) {
          return true;
        }
      }
    } catch (_) {
      return false;
    }

    return false;
  }

  String _formatTime(String time24) {
    try {
      final parts = time24.split(":");
      int hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final suffix = hour >= 12 ? "PM" : "AM";
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return "$hour:${minute.toString().padLeft(2, '0')} $suffix";
    } catch (_) {
      return time24;
    }
  }

  double? _calculateDistance(double lat, double lon) {
    if (userPosition == null) return null;
    return Geolocator.distanceBetween(
          userPosition!.latitude,
          userPosition!.longitude,
          lat,
          lon,
        ) /
        1000;
  }

  void _navigateToHospitalDetails(  hospital) {
    log("$hospital");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospitalDetailsPage(
          hospitalId: hospital["id"].toString()
          //hospital: hospital,
        ),
      ),
    );
  }

  // ========== FIXED SEARCH LOGIC - HANDLES ADDRESS MAP ==========
  bool _matchesSearchQuery(Map<String, dynamic> hospital) {
    if (searchQuery.isEmpty) return true;

    final cleanQuery = searchQuery.replaceAll(' ', '').toLowerCase();
    final hospitalName = (hospital["name"] ?? '')
        .toString()
        .replaceAll(' ', '')
        .toLowerCase();

    // Convert address (Map or String) to plain string for searching
    String getAddressString(dynamic addr) {
      if (addr == null) return '';
      if (addr is String) return addr;
      if (addr is Map) {
        final parts = <String>[];
        if (addr['place'] != null) parts.add(addr['place'].toString());
        if (addr['district'] != null) parts.add(addr['district'].toString());
        if (addr['state'] != null) parts.add(addr['state'].toString());
        return parts.join(' ');
      }
      return '';
    }

    final rawAddress = getAddressString(hospital["address"]);
    final hospitalAddress = rawAddress.replaceAll(' ', '').toLowerCase();

    return hospitalName.contains(cleanQuery) ||
        hospitalAddress.contains(cleanQuery);
  }

  // ========== BUILD METHODS ==========

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFECFDF5),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.green,
            strokeWidth: screenWidth * 0.008,
          ),
        ),
      );
    }

    List<dynamic> filteredHospitals = hospitals.where((hospital) {
      final matchesSearch = _matchesSearchQuery(hospital);
      final matchesOpen = !filterOpenNow || _isOpenNow(hospital);
      return matchesSearch && matchesOpen;
    }).toList();

    if (filterNearest && userPosition != null) {
      filteredHospitals.sort((a, b) {
        final aDist = _calculateDistance(
              (a["latitude"] ?? 0).toDouble(),
              (a["longitude"] ?? 0).toDouble(),
            ) ??
            double.infinity;
        final bDist = _calculateDistance(
              (b["latitude"] ?? 0).toDouble(),
              (b["longitude"] ?? 0).toDouble(),
            ) ??
            double.infinity;
        return aDist.compareTo(bDist);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "${widget.type} Hospitals",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: screenWidth * 0.05,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: screenWidth * 0.055,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Box
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.015,
              ),
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Search hospitals...",
                  hintStyle: TextStyle(fontSize: screenWidth * 0.035),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: screenWidth * 0.06,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: screenHeight * 0.0125),
                ),
              ),
            ),
            // Filter Chips
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.01,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FilterChip(
                    label: Text(
                      "Nearest",
                      style: TextStyle(fontSize: screenWidth * 0.035),
                    ),
                    selected: filterNearest,
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                        color: filterNearest ? Colors.white : Colors.black,
                        fontSize: screenWidth * 0.035),
                    onSelected: (val) async {
                      if (val) {
                        await _ensureLocationEnabled();
                        setState(() => filterNearest = true);
                      } else {
                        setState(() => filterNearest = false);
                      }
                    },
                  ),
                  FilterChip(
                    label: Text(
                      "Open Now",
                      style: TextStyle(fontSize: screenWidth * 0.035),
                    ),
                    selected: filterOpenNow,
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                        color: filterOpenNow ? Colors.white : Colors.black,
                        fontSize: screenWidth * 0.035),
                    onSelected: (val) =>
                        setState(() => filterOpenNow = val),
                  ),
                ],
              ),
            ),
            // Results Count
            if (searchQuery.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Row(
                  children: [
                    Text(
                      "${filteredHospitals.length} result${filteredHospitals.length == 1 ? '' : 's'} for \"$searchQuery\"",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ],
                ),
              ),
            // List
            Expanded(
              child: filteredHospitals.isEmpty
                  ? _buildEmptyState(screenWidth, screenHeight)
                  : ListView.builder(
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      itemCount: filteredHospitals.length,
                      itemBuilder: (context, index) => InkWell(
                        onTap: () => _navigateToHospitalDetails(
                            filteredHospitals[index]),
                        child: _buildHospitalCard(filteredHospitals[index],
                            screenWidth, screenHeight),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: screenWidth * 0.16, color: Colors.grey),
          SizedBox(height: screenHeight * 0.02),
          Text(
            "No hospitals found",
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            searchQuery.isEmpty
                ? "Try adjusting your filters"
                : "No results for \"$searchQuery\"",
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (searchQuery.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.02),
              child: TextButton(
                onPressed: () => setState(() => searchQuery = ''),
                child: Text(
                  "Clear search",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: screenWidth * 0.035,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ========== FIXED HOSPITAL CARD - HANDLES ADDRESS MAP ==========
  Widget _buildHospitalCard(dynamic hospital, double screenWidth,
      double screenHeight) {
    final imageUrl = hospital["image"]?["imageUrl"] ?? "";
    final name = hospital["name"] ?? "Unknown Hospital";

    // Convert address (Map or String) to readable String
    String getAddress(dynamic addr) {
      if (addr == null) return "";
      if (addr is String) return addr;
      if (addr is Map) {
        final parts = <String>[];
        if (addr['place'] != null && addr['place'].toString().isNotEmpty)
          parts.add(addr['place']);
        if (addr['district'] != null && addr['district'].toString().isNotEmpty)
          parts.add(addr['district']);
        if (addr['state'] != null && addr['state'].toString().isNotEmpty)
          parts.add(addr['state']);
        return parts.join(', ');
      }
      return "";
    }

    final address = getAddress(hospital["address"]);
    final phone = hospital["phone"] ?? "";
    final lat = (hospital["latitude"] ?? 0).toDouble();
    final lon = (hospital["longitude"] ?? 0).toDouble();
    final distance = _calculateDistance(lat, lon);
    final isOpen = _isOpenNow(hospital);

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(screenWidth * 0.035)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: screenHeight * 0.22,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'images/hospital.jpg',
                        height: screenHeight * 0.22,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    'images/hospital.jpg',
                    height: screenHeight * 0.22,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (distance != null)
                  Text(
                    "${distance.toStringAsFixed(1)} km away",
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.blueGrey,
                    ),
                  ),
                SizedBox(height: screenHeight * 0.0075),
                Text(
                  address,
                  style: TextStyle(fontSize: screenWidth * 0.035),
                ),
                SizedBox(height: screenHeight * 0.0075),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: isOpen ? Colors.green : Colors.red,
                      size: screenWidth * 0.025,
                    ),
                    SizedBox(width: screenWidth * 0.015),
                    Text(
                      isOpen ? "Open Now" : "Closed",
                      style: TextStyle(
                        color: isOpen ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.01),
              ],
            ),
          ),
        ],
      ),
    );
  }
}