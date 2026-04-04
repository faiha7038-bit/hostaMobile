import 'package:flutter/material.dart';
import 'package:hosta/presentation/screens/hospital_details/hospital_details.dart';
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
      final response = await ApiService().getFilter(widget.type);
      setState(() {
        hospitals = response.data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching hospitals: $e");
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _ensureLocationEnabled() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationDialog("Please enable your location services.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationDialog("Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationDialog(
          "Location permission permanently denied. Enable it from app settings.");
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() => userPosition = pos);
  }

  void _showLocationDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Location Required"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  bool _isOpenNow(Map<String, dynamic> hospital) {
    // Check for working_hours_clinic first (new format)
    final workingHoursClinic = hospital["working_hours_clinic"] as List<dynamic>?;
    if (workingHoursClinic != null && workingHoursClinic.isNotEmpty) {
      return _isOpenNowNewFormat(hospital);
    }

    // Fall back to working_hours (old format)
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
      int closeMinutes = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);

      // Handle overnight shifts
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

    // Check if current time falls within morning or evening session
    try {
      int nowMinutes = now.hour * 60 + now.minute;

      // Check morning session
      if (morningSession != null && morningSession["open"] != null && morningSession["open"]!.isNotEmpty) {
        final morningOpen = morningSession["open"].split(":");
        final morningClose = morningSession["close"].split(":");
        
        int morningOpenMinutes = int.parse(morningOpen[0]) * 60 + int.parse(morningOpen[1]);
        int morningCloseMinutes = int.parse(morningClose[0]) * 60 + int.parse(morningClose[1]);

        if (nowMinutes >= morningOpenMinutes && nowMinutes <= morningCloseMinutes) {
          return true;
        }
      }

      // Check evening session
      if (eveningSession != null && eveningSession["open"] != null && eveningSession["open"]!.isNotEmpty) {
        final eveningOpen = eveningSession["open"].split(":");
        final eveningClose = eveningSession["close"].split(":");
        
        int eveningOpenMinutes = int.parse(eveningOpen[0]) * 60 + int.parse(eveningOpen[1]);
        int eveningCloseMinutes = int.parse(eveningClose[0]) * 60 + int.parse(eveningClose[1]);

        if (nowMinutes >= eveningOpenMinutes && nowMinutes <= eveningCloseMinutes) {
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

  void _navigateToHospitalDetails(dynamic hospital) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospitalDetailsPage(
          hospitalId: hospital["_id"], // Pass the hospital ID
          hospital: hospital, // Pass the entire hospital data
        ),
      ),
    );
  }

  // ========== FIXED SEARCH LOGIC - REMOVE ALL SPACES ==========
  
  bool _matchesSearchQuery(Map<String, dynamic> hospital) {
    if (searchQuery.isEmpty) return true;
    
    // Remove ALL spaces from search query and convert to lowercase
    final cleanQuery = searchQuery.replaceAll(' ', '').toLowerCase();
    
    // Remove ALL spaces from hospital name and address and convert to lowercase
    final hospitalName = (hospital["name"] ?? '').toString().replaceAll(' ', '').toLowerCase();
    final hospitalAddress = (hospital["address"] ?? '').toString().replaceAll(' ', '').toLowerCase();
    
    // Check if clean query exists in clean hospital name OR address
    return hospitalName.contains(cleanQuery) || hospitalAddress.contains(cleanQuery);
  }

  // ========== BUILD METHODS ==========

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFECFDF5),
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
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
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- Search Box ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Search hospitals...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ),

            // --- Filter Chips ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FilterChip(
                    label: const Text("Nearest"),
                    selected: filterNearest,
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                        color: filterNearest ? Colors.white : Colors.black),
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
                    label: const Text("Open Now"),
                    selected: filterOpenNow,
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                        color: filterOpenNow ? Colors.white : Colors.black),
                    onSelected: (val) =>
                        setState(() => filterOpenNow = val),
                  ),
                ],
              ),
            ),

            // --- Results Count ---
            if (searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      "${filteredHospitals.length} result${filteredHospitals.length == 1 ? '' : 's'} for \"$searchQuery\"",
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

            // --- List ---
            Expanded(
              child: filteredHospitals.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredHospitals.length,
                      itemBuilder: (context, index) => InkWell(
                        onTap: () => _navigateToHospitalDetails(filteredHospitals[index]),
                        child: _buildHospitalCard(filteredHospitals[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "No hospitals found",
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? "Try adjusting your filters"
                : "No results for \"$searchQuery\"",
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextButton(
                onPressed: () => setState(() => searchQuery = ''),
                child: const Text(
                  "Clear search",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHospitalCard(dynamic hospital) {
    final imageUrl = hospital["image"]?["imageUrl"] ?? "";
    final name = hospital["name"] ?? "Unknown Hospital";
    final address = hospital["address"] ?? "";
    final phone = hospital["phone"] ?? "";
    final lat = (hospital["latitude"] ?? 0).toDouble();
    final lon = (hospital["longitude"] ?? 0).toDouble();
    final distance = _calculateDistance(lat, lon);
    final isOpen = _isOpenNow(hospital);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'images/hospital.jpg',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    'images/hospital.jpg',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                if (distance != null)
                  Text("${distance.toStringAsFixed(1)} km away",
                      style: const TextStyle(color: Colors.blueGrey)),
                const SizedBox(height: 6),
                Text(address),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.circle,
                        color: isOpen ? Colors.green : Colors.red, size: 10),
                    const SizedBox(width: 6),
                    Text(
                      isOpen ? "Open Now" : "Closed",
                      style: TextStyle(
                          color: isOpen ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}