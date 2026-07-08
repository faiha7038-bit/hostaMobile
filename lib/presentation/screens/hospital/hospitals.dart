import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hosta/presentation/screens/doctor/doctors.dart';
import 'package:hosta/presentation/screens/hospital/hospital_details.dart';
import 'package:hosta/presentation/screens/hospital/widgets/specialities.dart';
import 'package:hosta/services/socket-service.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/api_service.dart';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

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
  late Function(dynamic) _onHospitalEvent;
  bool isLoading = true;
  bool isSearching = true;
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
    _setupSocket();
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
    SocketService().removeListener("HOSPITAL_REGISTERED", _onHospitalEvent);
    SocketService().removeListener("HOSPITAL_UPDATED", _onHospitalEvent);
    SocketService().removeListener("HOSPITAL_BLACKLISTED", _onHospitalEvent);
    super.dispose();
  }

  void _setupSocket() {
    _onHospitalEvent = (_) {
      if (!mounted) return;
      setState(() {
        hospitals.clear();
        currentPage = 1;
        hasNextPage = true;
      });
      _fetchHospitals();
    };
    SocketService().addListener(
      [
        'HOSPITAL_REGISTERED',
        'HOSPITAL_UPDATED',
        'HOSPITAL_BLACKLISTED',
      ],
      _onHospitalEvent,
    );
  }

  Future<void> _loadMoreHospitals() async {
    if (isLoadingMore || !hasNextPage) return;
    if (!mounted) return;
    setState(() => isLoadingMore = true);
    await _fetchHospitals(
      query: searchQuery,
      page: currentPage + 1,
      loadMore: true,
    );
    if (!mounted) return;
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
          if (!mounted) return;
          setState(() => isLoading = true);
        } else {
          if (!mounted) return;
          setState(() => isSearching = true);
        }
      }

      final response = await ApiService().getAllHospitals(
        query,
        page: page,
        limit: 10,
      );

      List allHospitals = [];

      if (response.data is Map && response.data['data'] is List) {
        allHospitals = response.data['data'];
      }

      final pagination = response.data['pagination'];

      final filtered = allHospitals.where((hospital) {
        final hospitalType = hospital['type']?.toString().toLowerCase() ?? '';
        return hospitalType == widget.type.toLowerCase();
      }).toList();
      if (!mounted) return;
      setState(() {
        hospitals = loadMore ? [...hospitals, ...filtered] : filtered;
        currentPage = pagination['currentPage'];
        hasNextPage = pagination['hasNextPage'];
        isLoading = false;
        isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        isSearching = false;
        isLoadingMore = false;
      });
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
    final double titleSize = _clamp(screenWidth * 0.045, 16, 24);
    final double contentSize = _clamp(screenWidth * 0.04, 14, 22);
    final double buttonSize = _clamp(screenWidth * 0.04, 14, 22);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Location Required",
          style: TextStyle(fontSize: titleSize),
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: contentSize),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(fontSize: buttonSize),
            ),
          ),
        ],
      ),
    );
  }

  bool _isOpenNow(Map<String, dynamic> hospital) {
    if (hospital["working_hours_clinic"] is List && (hospital["working_hours_clinic"] as List).isNotEmpty) {
      return _isOpenNowNewFormat(hospital);
    }
    if (hospital["working_hours_clinic_nobreak"] is List && (hospital["working_hours_clinic_nobreak"] as List).isNotEmpty) {
      return _isOpenNowNoBreak(hospital);
    }
    if (hospital["working_hours_general"] is List && (hospital["working_hours_general"] as List).isNotEmpty) {
      return _isOpenNowGeneral(hospital);
    }
    return false;
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

  bool _isOpenNowGeneral(Map<String, dynamic> hospital) {
    final hours = hospital["working_hours_general"] as List<dynamic>?;
    if (hours == null || hours.isEmpty) return false;

    final now = DateTime.now();
    final today = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][now.weekday - 1];

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
    final today = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][now.weekday - 1];

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

  void _navigateToHospitalDetails(hospital) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospitalDetailsPage(
          hospitalId: hospital["id"].toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive clamped values
    final double loadingStrokeWidth = _clamp(screenWidth * 0.008, 2, 6);
    final double appBarTitleSize = _clamp(screenWidth * 0.05, 16, 24);
    final double backIconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double searchBoxPaddingHoriz = _clamp(screenWidth * 0.04, 12, 24);
    final double searchBoxPaddingVert = _clamp(screenHeight * 0.015, 8, 20);
    final double searchHintSize = _clamp(screenWidth * 0.035, 12, 18);
    final double searchIconSize = _clamp(screenWidth * 0.06, 20, 32);
    final double searchRadius = _clamp(screenWidth * 0.03, 8, 16);
    final double searchContentPadV = _clamp(screenHeight * 0.0125, 8, 16);
    final double filterChipFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double filterChipLabelSize = _clamp(screenWidth * 0.035, 12, 18);
    final double resultsFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double listPadding = _clamp(screenWidth * 0.03, 8, 16);
    final double cardMarginBottom = _clamp(screenHeight * 0.015, 8, 20);
    final double cardRadius = _clamp(screenWidth * 0.035, 10, 20);
    final double cardShadowBlur = _clamp(screenWidth * 0.0075, 2, 6);
    final double imageHeight = _clamp(screenHeight * 0.22, 120, 280);
    final double cardPadding = _clamp(screenWidth * 0.03, 8, 16);
    final double nameFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double distanceFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double addressFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double statusIconSize = _clamp(screenWidth * 0.025, 10, 16);
    final double statusFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double bookButtonPaddingV = _clamp(screenHeight * 0.015, 8, 16);
    final double bookButtonPaddingH = _clamp(screenWidth * 0.06, 16, 32);
    final double bookButtonRadius = _clamp(screenWidth * 0.03, 8, 16);
    final double bookButtonFontSize = _clamp(screenWidth * 0.038, 12, 20);
    final double emptyIconSize = _clamp(screenWidth * 0.16, 60, 120);
    final double emptyTitleSize = _clamp(screenWidth * 0.045, 16, 24);
    final double emptySubtitleSize = _clamp(screenWidth * 0.035, 12, 18);
    final double clearButtonSize = _clamp(screenWidth * 0.035, 12, 18);
    final double bottomSheetRadius = _clamp(screenWidth * 0.05, 12, 24);
    final double bottomSheetHeaderFontSize = _clamp(screenWidth * 0.045, 16, 24);
    final double bottomSheetSubFontSize = _clamp(screenWidth * 0.033, 12, 18);
    final double closeIconSize = _clamp(screenWidth * 0.06, 24, 40);

    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFECFDF5),
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.green,
            strokeWidth: loadingStrokeWidth,
          ),
        ),
      );
    }

    List<dynamic> filteredHospitals = hospitals.where((hospital) {
      final matchesOpen = !filterOpenNow || _isOpenNow(hospital);
      return matchesOpen;
    }).toList();

    if (filterNearest && userPosition != null) {
      filteredHospitals.sort((a, b) {
        final aLat = double.tryParse(a["latitude"].toString()) ?? 0.0;
        final aLon = double.tryParse(a["longitude"].toString()) ?? 0.0;
        final bLat = double.tryParse(b["latitude"].toString()) ?? 0.0;
        final bLon = double.tryParse(b["longitude"].toString()) ?? 0.0;
        final aDist = _calculateDistance(aLat, aLon) ?? double.infinity;
        final bDist = _calculateDistance(bLat, bLon) ?? double.infinity;
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
            fontSize: appBarTitleSize,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: backIconSize,
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
                horizontal: searchBoxPaddingHoriz,
                vertical: searchBoxPaddingVert,
              ),
              child: TextField(
                onChanged: (value) {
                  if (!mounted) return;
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
                decoration: InputDecoration(
                  hintText: "Search hospitals...",
                  hintStyle: TextStyle(fontSize: searchHintSize),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: searchIconSize,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(searchRadius),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: searchContentPadV),
                ),
              ),
            ),
            // Filter Chips
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: searchBoxPaddingHoriz,
                vertical: _clamp(screenHeight * 0.01, 4, 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FilterChip(
                    label: Text(
                      "Nearest",
                      style: TextStyle(fontSize: filterChipFontSize),
                    ),
                    selected: filterNearest,
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                      color: filterNearest ? Colors.white : Colors.black,
                      fontSize: filterChipLabelSize,
                    ),
                    onSelected: (val) async {
                      if (val) {
                        await _ensureLocationEnabled();
                        if (!mounted) return;
                        setState(() => filterNearest = true);
                      } else {
                        if (!mounted) return;
                        setState(() => filterNearest = false);
                      }
                    },
                  ),
                  FilterChip(
                    label: Text(
                      "Open Now",
                      style: TextStyle(fontSize: filterChipFontSize),
                    ),
                    selected: filterOpenNow,
                    selectedColor: Colors.green,
                    labelStyle: TextStyle(
                      color: filterOpenNow ? Colors.white : Colors.black,
                      fontSize: filterChipLabelSize,
                    ),
                    onSelected: (val) =>
                        setState(() => filterOpenNow = val),
                  ),
                ],
              ),
            ),
            // Results Count
            if (searchQuery.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: searchBoxPaddingHoriz),
                child: Row(
                  children: [
                    Text(
                      "${filteredHospitals.length} result${filteredHospitals.length == 1 ? '' : 's'} for \"$searchQuery\"",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: resultsFontSize,
                      ),
                    ),
                  ],
                ),
              ),
            // List
            Expanded(
              child: filteredHospitals.isEmpty
                  ? _buildEmptyState(
                      screenWidth,
                      screenHeight,
                      emptyIconSize,
                      emptyTitleSize,
                      emptySubtitleSize,
                      clearButtonSize,
                      searchQuery,
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(listPadding),
                      itemCount: filteredHospitals.length + (isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredHospitals.length) {
                          return Padding(
                            padding: EdgeInsets.all(_clamp(screenWidth * 0.04, 8, 16)),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.green,
                                strokeWidth: loadingStrokeWidth,
                              ),
                            ),
                          );
                        }
                        return InkWell(
                          onTap: () => _navigateToHospitalDetails(
                              filteredHospitals[index]),
                          child: _buildHospitalCard(
                            filteredHospitals[index],
                            screenWidth,
                            screenHeight,
                            cardMarginBottom,
                            cardRadius,
                            cardShadowBlur,
                            imageHeight,
                            cardPadding,
                            nameFontSize,
                            distanceFontSize,
                            addressFontSize,
                            statusIconSize,
                            statusFontSize,
                            bookButtonPaddingV,
                            bookButtonPaddingH,
                            bookButtonRadius,
                            bookButtonFontSize,
                            bottomSheetRadius,
                            bottomSheetHeaderFontSize,
                            bottomSheetSubFontSize,
                            closeIconSize,
                            userPosition,
                            _calculateDistance,
                            _isOpenNow,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    double screenWidth,
    double screenHeight,
    double emptyIconSize,
    double emptyTitleSize,
    double emptySubtitleSize,
    double clearButtonSize,
    String searchQuery,
  ) {
    final double spacing = _clamp(screenHeight * 0.02, 12, 24);
    final double spacingSmall = _clamp(screenHeight * 0.01, 6, 16);
    final double spacingLarge = _clamp(screenHeight * 0.02, 12, 24);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: emptyIconSize, color: Colors.grey),
          SizedBox(height: spacing),
          Text(
            "No hospitals found",
            style: TextStyle(
              fontSize: emptyTitleSize,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: spacingSmall),
          Text(
            searchQuery.isEmpty
                ? ""
                : "No results for \"$searchQuery\"",
            style: TextStyle(
              fontSize: emptySubtitleSize,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (searchQuery.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: spacingLarge),
              child: TextButton(
                onPressed: () async {
                  setState(() {
                    searchQuery = '';
                  });
                  await _fetchHospitals();
                },
                child: Text(
                  "Clear search",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: clearButtonSize,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHospitalCard(
    dynamic hospital,
    double screenWidth,
    double screenHeight,
    double cardMarginBottom,
    double cardRadius,
    double cardShadowBlur,
    double imageHeight,
    double cardPadding,
    double nameFontSize,
    double distanceFontSize,
    double addressFontSize,
    double statusIconSize,
    double statusFontSize,
    double bookButtonPaddingV,
    double bookButtonPaddingH,
    double bookButtonRadius,
    double bookButtonFontSize,
    double bottomSheetRadius,
    double bottomSheetHeaderFontSize,
    double bottomSheetSubFontSize,
    double closeIconSize,
    Position? userPosition,
    double? Function(double, double) calculateDistance,
    bool Function(Map<String, dynamic>) isOpenNow,
  ) {
  const s3BaseUrl =
     "https://hostahealthcare.s3.eu-north-1.amazonaws.com/";


final imageUrl = hospital["imageUrl"] != null
    ? "$s3BaseUrl${hospital["imageUrl"]}"
    : "";
    final name = hospital["name"] ?? "Unknown Hospital";

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
    final lat = double.tryParse(hospital["latitude"].toString()) ?? 0.0;
    final lon = double.tryParse(hospital["longitude"].toString()) ?? 0.0;
    final distance = calculateDistance(lat, lon);
    final isOpen = isOpenNow(hospital);

    return Container(
      margin: EdgeInsets.only(bottom: cardMarginBottom),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: cardShadowBlur,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(cardRadius)),
            child: imageUrl.isNotEmpty
                ?
     CachedNetworkImage(
  imageUrl: imageUrl,
  height: imageHeight,
  width: double.infinity,
  fit: BoxFit.cover,
  placeholder: (context, url) => const Center(
    child: CircularProgressIndicator(),
  ),
  errorWidget: (context, url, error) => Container(
    height: imageHeight,
    width: double.infinity,
    color: Colors.grey.shade200,
    child: const Center(
      child: Icon(
        Icons.local_hospital,
        size: 60,
        color: Colors.grey,
      ),
    ),
  ),
)
                : Image.asset(
                    'images/hospital.jpg',
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: nameFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (distance != null)
                  Text(
                    distance < 1
                        ? "${(distance * 1000).toStringAsFixed(0)} m away"
                        : "${distance.toStringAsFixed(2)} km away",
                    style: TextStyle(
                      fontSize: distanceFontSize,
                      color: Colors.blueGrey,
                    ),
                  ),
                SizedBox(height: _clamp(screenHeight * 0.0075, 4, 12)),
                Text(
                  address,
                  style: TextStyle(fontSize: addressFontSize),
                ),
                SizedBox(height: _clamp(screenHeight * 0.0075, 4, 12)),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: isOpen ? Colors.green : Colors.red,
                      size: statusIconSize,
                    ),
                    SizedBox(width: _clamp(screenWidth * 0.015, 4, 12)),
                    Text(
                      isOpen ? "Open Now" : "Closed",
                      style: TextStyle(
                        color: isOpen ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                        fontSize: statusFontSize,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _clamp(screenHeight * 0.01, 4, 12)),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(
                        vertical: bookButtonPaddingV,
                        horizontal: bookButtonPaddingH,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          bookButtonRadius,
                        ),
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(bottomSheetRadius),
                          ),
                        ),
                        builder: (context) {
                          return SizedBox(
                            height: MediaQuery.of(context).size.height * 0.8,
                            child: Column(
                              children: [
                                // Header
                                Container(
                                  padding: EdgeInsets.all(_clamp(screenWidth * 0.04, 12, 24)),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(bottomSheetRadius),
                                    ),
                                  ),
                                  child: Row(
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
                                                fontSize: bottomSheetHeaderFontSize,
                                              ),
                                            ),
                                            SizedBox(height: _clamp(screenHeight * 0.005, 2, 8)),
                                            Text(
                                              "Choose Specialty",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: bottomSheetSubFontSize,
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
                                          size: closeIconSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Specialities
                                Expanded(
                                  child: SpecialtiesTab(
                                    hospital: hospital,
                                    onSpecialtyTap: (hospitalId, specialtyName) {
                                      Navigator.pop(context);
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
                        fontSize: bookButtonFontSize,
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