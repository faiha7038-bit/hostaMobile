import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:hosta/presentation/screens/doctor/doctors.dart';
import 'package:hosta/presentation/screens/hospital/hospital_details.dart';
import 'package:hosta/presentation/screens/hospital/widgets/specialities.dart';
import 'package:hosta/services/socket-service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final ScrollController _scrollController = ScrollController();

int currentPage = 1;
bool hasNextPage = true;
bool isLoadingMore = false;

  bool isLoading = true;
  bool isSearching=true;
  List<dynamic> hospitals = [];
  Timer? _debounce;

  String searchQuery = '';
  bool filterNearest = false;
  bool filterOpenNow = false;
  Position? userPosition;

 @override
void initState() {
  super.initState();

  _fetchHospitals();
SocketService().addListener(
  [
    'HOSPITAL_REGISTERED',
    'HOSPITAL_UPDATED',
    'HOSPITAL_BLACKLISTED',
  ],
  (_) {
    log("🔄 Refetch Hospitals");
    setState(() {
      hospitals.clear();
      currentPage = 1;
      hasNextPage = true;
    });

    _fetchHospitals();
  },
);
  _scrollController.addListener(() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore &&
        hasNextPage) {
      _loadMoreHospitals();
    }
  });
}
@override
void dispose() {
  _scrollController.dispose();
  _debounce?.cancel();
  super.dispose();
}
Future<void> _loadMoreHospitals() async {
  if (isLoadingMore || !hasNextPage) return;

  setState(() => isLoadingMore = true);

  await _fetchHospitals(
    query: searchQuery,
    page: currentPage + 1,
    loadMore: true,
  );

  setState(() => isLoadingMore = false);
}
Future<void> _fetchHospitals({
  String query = '',
  int page = 1,
  bool loadMore = false,
}) async {
  try {
    if (!loadMore) {
      if (query.isEmpty) {
        setState(() => isLoading = true);
      } else {
        setState(() => isSearching = true);
      }
    }

    final response = await ApiService().getAllHospitals(
      query,
      page: page,
      limit: 10,
    );

    List allHospitals = [];

    if (response.data is Map &&
        response.data['data'] is List) {
      allHospitals = response.data['data'];
    }

    final pagination = response.data['pagination'];

    final filtered = allHospitals.where((hospital) {
      final hospitalType =
          hospital['type']?.toString().toLowerCase() ?? '';

      return hospitalType ==
          widget.type.toLowerCase();
    }).toList();

    setState(() {
      hospitals = loadMore
          ? [...hospitals, ...filtered]
          : filtered;

      currentPage = pagination['currentPage'];
      hasNextPage = pagination['hasNextPage'];

      isLoading = false;
      isSearching = false;
    });
  } catch (e) {
    setState(() {
      isLoading = false;
      isSearching = false;
      isLoadingMore = false;
    });
  }
}
// Future<void> _fetchHospitals({String query = '',  int page = 1,
//   bool loadMore = false,}) async {
//   try {
//     if (query.isEmpty) {
//       setState(() => isLoading = true);
//     } else {
//       setState(() => isSearching = true); // 👈 only small loading
//     }

//     final response = await ApiService().getAllHospitals(query);

//     List allHospitals = [];

//     if (response.data is Map && response.data['data'] is List) {
//       allHospitals = response.data['data'];
//     } else if (response.data is List) {
//       allHospitals = response.data;
//     }

//     setState(() {
//       hospitals = allHospitals.where((hospital) {
//         final hospitalType =
//             hospital['type']?.toString().toLowerCase() ?? '';
//         return hospitalType == widget.type.toLowerCase();
//       }).toList();

//       isLoading = false;
//       isSearching = false;
//     });
//   } catch (e) {
//     setState(() {
//       isLoading = false;
//       isSearching = false;
//     });
//   }
// }
  // Future<void> _fetchHospitals() async {
  //   try {
  //     setState(() => isLoading = true);

  //     // Fetch ALL hospitals (no type filter)
  //     final response = await ApiService().getAllHospitals(query);

  //     setState(() {
  //       List allHospitals = [];
  //       if (response.data is Map && response.data['data'] is List) {
  //         allHospitals = response.data['data'];
  //       } else if (response.data is List) {
  //         allHospitals = response.data;
  //       }

  //       // Filter by type on client side
  //       hospitals = allHospitals.where((hospital) {
  //         final hospitalType = hospital['type']?.toString().toLowerCase() ?? '';
  //         return hospitalType == widget.type.toLowerCase();
  //       }).toList();

  //       print(
  //           "✅ Total: ${allHospitals.length}, Filtered (${widget.type}): ${hospitals.length}");
  //       isLoading = false;
  //     });
  //   } catch (e) {
  //     print("❌ Error: $e");
  //     setState(() => isLoading = false);
  //   }
  // }

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
  // 1. working_hours_clinic (morning/evening sessions)
  if (hospital["working_hours_clinic"] is List && (hospital["working_hours_clinic"] as List).isNotEmpty) {
    return _isOpenNowNewFormat(hospital);
  }
  // 2. working_hours_clinic_nobreak (simple open/close)
  if (hospital["working_hours_clinic_nobreak"] is List && (hospital["working_hours_clinic_nobreak"] as List).isNotEmpty) {
    return _isOpenNowNoBreak(hospital);
  }
  // 3. working_hours_general
  if (hospital["working_hours_general"] is List && (hospital["working_hours_general"] as List).isNotEmpty) {
    return _isOpenNowGeneral(hospital);
  }
  return false;
}

  // bool _isOpenNow(Map<String, dynamic> hospital) {
  //   final workingHoursClinic = hospital["working_hours_clinic"] as List<dynamic>?;
  //   if (workingHoursClinic != null && workingHoursClinic.isNotEmpty) {
  //     return _isOpenNowNewFormat(hospital);
  //   }

  //   final workingHours = hospital["working_hours"] as List<dynamic>?;
  //   if (workingHours == null || workingHours.isEmpty) return false;

  //   final now = DateTime.now();
  //   final today = [
  //     "Monday",
  //     "Tuesday",
  //     "Wednesday",
  //     "Thursday",
  //     "Friday",
  //     "Saturday",
  //     "Sunday"
  //   ][now.weekday - 1];

  //   final todayHours = workingHours.firstWhere(
  //     (day) => day["day"] == today,
  //     orElse: () => null,
  //   );

  //   if (todayHours == null || todayHours["is_holiday"] == true) return false;

  //   final open = todayHours["opening_time"];
  //   final close = todayHours["closing_time"];
  //   if (open == null || close == null) return false;

  //   try {
  //     int nowMinutes = now.hour * 60 + now.minute;
  //     final openParts = open.split(":");
  //     int openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);

  //     final closeParts = close.split(":");
  //     int closeMinutes = int.parse(closeParts[0]) * 60 +
  //         int.parse(closeParts[1]);

  //     if (closeMinutes < openMinutes) {
  //       return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
  //     } else {
  //       return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
  //     }
  //   } catch (_) {
  //     return false;
  //   }
  // }

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
bool _isOpenNowGeneral(Map<String, dynamic> hospital) {
  final hours = hospital["working_hours_general"] as List<dynamic>?;
  if (hours == null || hours.isEmpty) return false;

  final now = DateTime.now();
  final today = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"][now.weekday - 1];

  final todayEntry = hours.firstWhere(
    (entry) => entry["day"].toString().toLowerCase() == today.toLowerCase(),
    orElse: () => null,
  );
  if (todayEntry == null || todayEntry["is_holiday"] == true) return false;

  String open = todayEntry["opening_time"] ?? "";
  String close = todayEntry["closing_time"] ?? "";
  if (open.isEmpty || close.isEmpty) return false;

  int nowMinutes = now.hour * 60 + now.minute;
  int openMinutes = _parseTimeToMinutes(open);
  int closeMinutes = _parseTimeToMinutes(close);

  if (closeMinutes < openMinutes) {
    return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
  } else {
    return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
  }
}
bool _isOpenNowNoBreak(Map<String, dynamic> hospital) {
  final hours = hospital["working_hours_clinic_nobreak"] as List<dynamic>?;
  if (hours == null || hours.isEmpty) return false;

  final now = DateTime.now();
  final today = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"][now.weekday - 1];

  final todayEntry = hours.firstWhere(
    (entry) => entry["day"].toString().toLowerCase() == today.toLowerCase(),
    orElse: () => null,
  );
  if (todayEntry == null || todayEntry["is_holiday"] == true) return false;

  String open = todayEntry["opening_time"] ?? "";
  String close = todayEntry["closing_time"] ?? "";
  if (open.isEmpty || close.isEmpty) return false;

  int nowMinutes = now.hour * 60 + now.minute;
  int openMinutes = _parseTimeToMinutes(open);
  int closeMinutes = _parseTimeToMinutes(close);

  if (closeMinutes < openMinutes) {
    return nowMinutes >= openMinutes || nowMinutes <= closeMinutes;
  } else {
    return nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
  }
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
  int _parseTimeToMinutes(String time) {
  try {
    String t = time.trim().toUpperCase();
    bool isPM = t.contains("PM");
    t = t.replaceAll(RegExp(r'[AP]M'), '').trim();
    var parts = t.split(":");
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;
    return hour * 60 + minute;
  } catch (_) {
    return 0;
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
  final matchesOpen = !filterOpenNow || _isOpenNow(hospital);
  return matchesOpen;
}).toList();
    // List<dynamic> filteredHospitals = hospitals.where((hospital) {
    //   final matchesSearch = _matchesSearchQuery(hospital);
    //   final matchesOpen = !filterOpenNow || _isOpenNow(hospital);
    //   return matchesSearch && matchesOpen;
    // }).toList();
if (filterNearest && userPosition != null) {
  filteredHospitals.sort((a, b) {

    final aLat =
        double.tryParse(a["latitude"].toString()) ?? 0.0;
    final aLon =
        double.tryParse(a["longitude"].toString()) ?? 0.0;

    final bLat =
        double.tryParse(b["latitude"].toString()) ?? 0.0;
    final bLon =
        double.tryParse(b["longitude"].toString()) ?? 0.0;

    final aDist =
        _calculateDistance(aLat, aLon) ?? double.infinity;

    final bDist =
        _calculateDistance(bLat, bLon) ?? double.infinity;

    return aDist.compareTo(bDist);
  });
}
    // if (filterNearest && userPosition != null) {
    //   filteredHospitals.sort((a, b) {
    //     final aDist = _calculateDistance(
    //           (a["latitude"] ?? 0).toDouble(),
    //           (a["longitude"] ?? 0).toDouble(),
    //         ) ??
    //         double.infinity;
    //     final bDist = _calculateDistance(
    //           (b["latitude"] ?? 0).toDouble(),
    //           (b["longitude"] ?? 0).toDouble(),
    //         ) ??
    //         double.infinity;
    //     return aDist.compareTo(bDist);
    //   });
    // }

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
                onChanged: (value) {
  setState(() {
    searchQuery = value;
  });

  if (_debounce?.isActive ?? false) {
    _debounce!.cancel();
  }

  _debounce = Timer(
    const Duration(milliseconds: 500),
    () {
      _fetchHospitals(query: value);
    },
  );
},
//                 onChanged: (value) async {
//   setState(() {
//     searchQuery = value;
//   });

//   await _fetchHospitals(query: value);
// },
                // onChanged: (value) => setState(() => searchQuery = value),
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
                    controller: _scrollController,
                      padding: EdgeInsets.all(screenWidth * 0.03),
                      itemCount: filteredHospitals.length +
    (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {

  if (index == filteredHospitals.length) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.green,
        ),
      ),
    );
  }

  return InkWell(
                        onTap: () => _navigateToHospitalDetails(
                            filteredHospitals[index]),
                        child: _buildHospitalCard(filteredHospitals[index],
                            screenWidth, screenHeight),
                      
                      );
                      }
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
                ? ""
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
                onPressed: () async {
  setState(() {
    searchQuery = '';
  });

  await _fetchHospitals();
},
              //  onPressed: () => setState(() => searchQuery = ''),
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
    log("LAT: ${hospital["latitude"]}");
log("LON: ${hospital["longitude"]}");
log("USER LAT: ${userPosition?.latitude}");
log("USER LNG: ${userPosition?.longitude}");
    final lat =
    double.tryParse(hospital["latitude"].toString()) ?? 0.0;

final lon =
    double.tryParse(hospital["longitude"].toString()) ?? 0.0;
    // final lat = (hospital["latitude"] ?? 0).toDouble();
    // final lon = (hospital["longitude"] ?? 0).toDouble();
    final distance = _calculateDistance(lat, lon);
    final isOpen = _isOpenNow(hospital);
print(_calculateDistance(lat, lon));
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
    distance < 1
        ? "${(distance * 1000).toStringAsFixed(0)} m away"
        : "${distance.toStringAsFixed(2)} km away",
    style: TextStyle(
      fontSize: screenWidth * 0.035,
      color: Colors.blueGrey,
    ),
  ),
                // if (distance != null)
                //   Text(
                //     "${distance.toStringAsFixed(1)} km away",
                //     style: TextStyle(
                //       fontSize: screenWidth * 0.035,
                //       color: Colors.blueGrey,
                //     ),
                //   ),
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
              Align(
  alignment: Alignment.centerRight,
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      padding: EdgeInsets.symmetric(
        vertical: screenHeight * 0.015,
         horizontal: screenWidth * 0.06,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          screenWidth * 0.03,
        ),
      ),
    ),
onPressed: () async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId') ?? '';

  if (userId.isEmpty) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Login Required"),
        content: const Text(
          "Please login to book an appointment.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const Signin(),
                ),
              );
            },
            child: const Text(
              "Login",
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
    return;
  }
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
      ),
    ),
    builder: (context) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [

            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child:
             Row(
  children: [
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hospital["name"] ?? "",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
            ),
          ),

          SizedBox(height: screenHeight * 0.005),

          Text(
            "Choose Specialty",
            style: TextStyle(
              color: Colors.white70,
              fontSize: screenWidth * 0.033,
            ),
          ),
        ],
      ),
    ),

    IconButton(
      onPressed: () => Navigator.pop(context),
      icon: Icon(
        Icons.close,
        color: Colors.white,
        size: screenWidth * 0.06,
      ),
    ),
  ],
)
            ),

            // Specialities
          Expanded(
  child: SpecialtiesTab(
    hospital: hospital,
    onSpecialtyTap: (hospitalId, specialtyName) {

      // close bottomsheet
      Navigator.pop(context);

      // navigate to doctor screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Doctors(
            hospitalId: hospitalId,
            specialty: specialtyName,
          ),
        ),
      );
    },
  ),
),
          ],
        ),
      );
    },
  );
},
    child: Text(
      "Book Now",
      style: TextStyle(
        color: Colors.white,
        fontSize: screenWidth * 0.038,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
