import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hosta/presentation/screens/blood/donate.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:hosta/presentation/screens/blood/widgets/donor-section.dart';
import 'package:hosta/presentation/screens/blood/widgets/location-section.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/api_service.dart';

class Blood extends StatefulWidget {
  const Blood({super.key});

  @override
  State<Blood> createState() => _BloodState();
}

class _BloodState extends State<Blood> {
  List<dynamic> donors = [];
  bool isLoading = false;
  String searchQuery = '';
  String selectedCountry = '';
  String selectedState = '';
  String selectedDistrict = '';
  String selectedPlace = '';
  String selectedBloodGroup = '';

  final List<String> bloodGroups = [
    "All",
    "A+",
    "A-",
    "B+",
    "B-",
    "O+",
    "O-",
    "AB+",
    "AB-",
  ];

  List<String> countries = [];
  List<String> states = [];
  List<String> districts = [];
  List<String> places = [];
  String? bloodId;
  String? userId;
bool _hasDonated = false;   
bool _isLoading = true;      
  final ApiService _apiService = ApiService();
late Box cacheBox;
bool isOffline = false;
Timer? _debounce;
List<dynamic> allDonors = [];
final Map<String, List<String>> compatibilityMap = {
  "A+": ["A+", "A-", "O+", "O-"],
  "A-": ["A-", "O-"],
  "B+": ["B+", "B-", "O+", "O-"],
  "B-": ["B-", "O-"],
  "O+": ["O+", "O-"],
  "O-": ["O-"],
  "AB+": ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"],
  "AB-": ["AB-", "A-", "B-", "O-"],
};
StreamSubscription? _connectivitySubscription;
@override
void dispose() {
  _debounce?.cancel();
  _connectivitySubscription?.cancel();
  super.dispose();
}
@override
void initState() {
  super.initState();

  cacheBox = Hive.box('blood_cache');
_initializeConnectivity();
  _bootstrap();

  _loadDonationStatus();

// _connectivitySubscription =
//     Connectivity().onConnectivityChanged.listen((result) {
//   final offline = result == ConnectivityResult.none;

//   if (!mounted) return;

//   setState(()  {
//     isOffline = offline;
//        _fetchDonors();
//   });
// });
}
Future<void> _initializeConnectivity() async {

  // ✅ Initial internet check
final hasInternet = await _checkInternet();

setState(() {
  isOffline = !hasInternet;
});

  print("INITIAL OFFLINE => $isOffline");

  // ✅ Listen for realtime changes
  _connectivitySubscription =
      Connectivity().onConnectivityChanged.listen((result) async {

  final hasInternet = await _checkInternet();

final offline = !hasInternet;

    if (!mounted) return;

    setState(() {
      isOffline = offline;
    });

    print("CHANGED OFFLINE => $isOffline");

    await _fetchDonors();
  });
}
Future<bool> _checkInternet() async {
  try {

    final result = await InternetAddress.lookup('google.com');

    return result.isNotEmpty &&
        result[0].rawAddress.isNotEmpty;

  } on SocketException catch (_) {

    return false;
  }
}
Future<void> _loadDonationStatus() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _hasDonated = prefs.getBool('hasDonated') ?? false;
    _isLoading = false;
  });
}
Future<void> _bootstrap() async {
  await _loadUserData();
  await _fetchDonors();
}
  // void initState() {
  //   super.initState();
  //   _loadUserData();
  //   _fetchDonors();
  //   _init();
  // }
Future<void> _loadUserData() async {
  final prefs = await SharedPreferences.getInstance();

  final storedBloodId = prefs.getString('bloodId');
  final storedUserId = prefs.getString('userId');

  if (!mounted) return;

  setState(() {
    bloodId = storedBloodId;
    userId = storedUserId;
  });

  print("🩸 UPDATED bloodId: $bloodId");
}
  // Future<void> _loadUserData() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final storedBloodId = prefs.getString('bloodId');
  //     final storedUserId = prefs.getString('userId');

  //     setState(() {
  //       bloodId = storedBloodId;
  //       userId = storedUserId;
  //     });
  //   } catch (e) {
  //     print("Error loading user data: $e");
  //   }
  // }
Future<void> _fetchDonors() async {
  try {
    setState(() {
      isLoading = true;
    });

    final hasInternet = await _checkInternet();

    // =========================
    // OFFLINE MODE
    // =========================
    if (!hasInternet) {
      setState(() {
        isOffline = true;
      });

      final cachedData = cacheBox.get('all_donors');

      if (cachedData != null) {
        allDonors = List<dynamic>.from(jsonDecode(cachedData));
        _applyFiltersOffline();
      } else {
        setState(() {
          donors = [];
        });
      }

      return;
    }

    // =========================
    // ONLINE MODE
    // =========================
    setState(() {
      isOffline = false;
    });

    final response = await _apiService.getAllDonors(
      bloodGroup: selectedBloodGroup.isEmpty ? null : selectedBloodGroup,
      country: selectedCountry.isEmpty ? null : selectedCountry,
      state: selectedState.isEmpty ? null : selectedState,
      district: selectedDistrict.isEmpty ? null : selectedDistrict,
      place: selectedPlace.isEmpty ? null : selectedPlace,
      searchQuery: searchQuery.trim().isEmpty ? null : searchQuery.trim(),
    );

    if (response.statusCode == 200 && response.data != null) {
      final donorList = response.data is List
          ? response.data
          : response.data['data'] ?? [];

      // cache
      await cacheBox.put('all_donors', jsonEncode(donorList));

      allDonors = donorList;

      setState(() {
        donors = donorList;
      });

      _extractLocationData(donorList);
    }
  } catch (e) {
    print("ERROR => $e");

    final cachedData = cacheBox.get('all_donors');

    if (cachedData != null) {
      allDonors = List<dynamic>.from(jsonDecode(cachedData));
      _applyFiltersOffline();
    }
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
}

  // Future<void> _fetchDonors() async {
  //   print("🔵 _fetchDonors called with filters");
  //   print("🔵 _fetchDonors called, searchQuery = '$searchQuery'");
  //   try {
  //     setState(() => isLoading = true);

  //     // ✅ Build query parameters from current state
  //     final response = await _apiService.getAllDonors(
  //       bloodGroup: selectedBloodGroup.isEmpty ? null : selectedBloodGroup,
  //       country: selectedCountry.isEmpty ? null : selectedCountry,
  //       state: selectedState.isEmpty ? null : selectedState,
  //       district: selectedDistrict.isEmpty ? null : selectedDistrict,
  //       place: selectedPlace.isEmpty ? null : selectedPlace,
  //       searchQuery: searchQuery.isEmpty ? null : searchQuery,
  //       // pincode: null,  // if needed later
  //       // userId: null,
  //     );

  //     print("📡 Status: ${response.statusCode}");
  //     print("📦 Raw data: ${response.data}");

  //     if (response.statusCode == 200 && response.data != null) {
  //       List donorList = [];

  //       if (response.data is Map && response.data['data'] != null) {
  //         donorList = response.data['data'];
  //       } else if (response.data is Map && response.data['donors'] != null) {
  //         donorList = response.data['donors'];
  //       } else if (response.data is List) {
  //         donorList = response.data;
  //       }

  //       print("✅ Donors found: ${donorList.length}");

  //       // Cache the *filtered* result (optional)
  //       final prefs = await SharedPreferences.getInstance();
  //       await prefs.setString('cached_donors', jsonEncode(donorList));

  //       setState(() {
  //         donors = donorList;
  //         _extractLocationData(
  //           donorList,
  //         ); // update location dropdowns based on filtered list
  //       });
  //     } else {
  //       setState(() => donors = []);
  //     }
  //   } catch (e, stack) {
  //     print("❌ API error: $e");
  //     print(stack);
  //     // Fallback to cache (but cache might be outdated)
  //     final prefs = await SharedPreferences.getInstance();
  //     final cachedData = prefs.getString('cached_donors');
  //     if (cachedData != null) {
  //       final donorList = jsonDecode(cachedData);
  //       setState(() {
  //         donors = donorList;
  //         _extractLocationData(donorList);
  //       });
  //     } else {
  //       setState(() {
  //         donors = [];
  //         countries = [];
  //         states = [];
  //         districts = [];
  //         places = [];
  //       });
  //     }
  //   } finally {
  //     setState(() => isLoading = false);
  //   }
  // }
void _applyFiltersOffline() {
  List filtered = allDonors.where((donor) {
    final address = donor['address'] ?? {};

   final donorName =
    (
      donor['fullName'] ??
      donor['name'] ??
      donor['userName'] ??
      ''
    )
    .toString()
    .toLowerCase();
    log("DONOR NAME => $donorName");
log("SEARCH => $searchQuery");

    final bloodGroup =
        (donor['bloodGroup'] ?? '')
            .toString()
            .toLowerCase();

    final country =
        (address['country'] ?? '')
            .toString()
            .toLowerCase();

    final state =
        (address['state'] ?? '')
            .toString()
            .toLowerCase();

    final district =
        (address['district'] ?? '')
            .toString()
            .toLowerCase();

    final place =
        (address['place'] ?? '')
            .toString()
            .toLowerCase();

    final matchesSearch =
        searchQuery.isEmpty ||
        donorName.contains(searchQuery.toLowerCase());

final compatibleGroups =
    compatibilityMap[selectedBloodGroup] ?? [];

final matchesBlood =
    selectedBloodGroup.isEmpty ||
    compatibleGroups
        .map((e) => e.toLowerCase())
        .contains(bloodGroup);

    final matchesCountry =
        selectedCountry.isEmpty ||
        country == selectedCountry.toLowerCase();

    final matchesState =
        selectedState.isEmpty ||
        state == selectedState.toLowerCase();

    final matchesDistrict =
        selectedDistrict.isEmpty ||          
        district == selectedDistrict.toLowerCase();

    final matchesPlace =
        selectedPlace.isEmpty ||
        place == selectedPlace.toLowerCase();

    return matchesSearch &&
        matchesBlood &&
        matchesCountry &&
        matchesState &&
        matchesDistrict &&
        matchesPlace;
  }).toList();

  setState(() {
    donors = filtered;
    _extractLocationData(allDonors);
  });
  log("SEARCH => $searchQuery");
  log("TOTAL => ${allDonors.length}");
}
  void _extractLocationData(List<dynamic> donorList) {
    final uniqueCountries = <String>{};
    final uniqueStates = <String>{};
    final uniqueDistricts = <String>{};
    final uniquePlaces = <String>{};

    for (final donor in donorList) {
      final address = donor['address'] ?? {};

      // ✅ Normalize: trim, toLowerCase, then capitalize first letter (optional)
      String normalize(String? value) {
        if (value == null) return '';
        final trimmed = value.toString().trim();
        if (trimmed.isEmpty || trimmed == 'null') return '';
        // Capitalize first letter, rest lower (e.g., "india" -> "India")
        return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
      }

      final country = normalize(address['country']);
      final state = normalize(address['state']);
      final district = normalize(address['district']);
      final place = normalize(address['place']);

      if (country.isNotEmpty) uniqueCountries.add(country);
      if (state.isNotEmpty) uniqueStates.add(state);
      if (district.isNotEmpty) uniqueDistricts.add(district);
      if (place.isNotEmpty) uniquePlaces.add(place);
    }

    setState(() {
      countries = uniqueCountries.toList()..sort();
      states = uniqueStates.toList()..sort();
      districts = uniqueDistricts.toList()..sort();
      places = uniquePlaces.toList()..sort();
    });
  }

  int _calculateAge(String dateOfBirth) {
    try {
      DateTime birthDate;
      if (dateOfBirth.contains('T')) {
        birthDate = DateTime.parse(dateOfBirth);
      } else {
        birthDate = DateTime.parse('${dateOfBirth}T00:00:00.000Z');
      }

      final now = DateTime.now();
      int age = now.year - birthDate.year;

      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      return age;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse("tel:$phoneNumber");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _handleDonateNavigation() {
    if (userId == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Signin()),
      ).then((_) {
         //_init();
        _loadUserData();

      });
    } else if (bloodId == null) {
 Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const Donate()),
).then((value) async {
  await _loadUserData();   // 🔥 reload bloodId AFTER return
  await _fetchDonors();   // optional refresh list
});
    }
  }

Future<void> _refreshData() async {
  await _loadUserData();   
  await _fetchDonors();
}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text(
          "Blood Donor",
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
              size: screenWidth * 0.06,
            ),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndDonate(screenWidth, screenHeight),
            LocationSection(
              selectedCountry: selectedCountry,
              selectedState: selectedState,
              selectedDistrict: selectedDistrict,
              selectedPlace: selectedPlace,
              countries: countries,
              states: states, // Pass ALL states, not filtered
              districts: districts, // Pass ALL districts, not filtered
              places: places, // Pass ALL places, not filtered
              donors: donors,
              onLocationSelected: (country, state, district, place) {
                print(
                  "📍 Location selected: $country, $state, $district, $place",
                ); // Debug print
                setState(() {
                  selectedCountry = country;
                  selectedState = state;
                  selectedDistrict = district;
                  selectedPlace = place;
                });
              _fetchDonors();
              },
              onClear: () {
                print("📍 Location cleared"); // Debug print
                setState(() {
                  selectedCountry = '';
                  selectedState = '';
                  selectedDistrict = '';
                  selectedPlace = '';
                  selectedBloodGroup = '';
                 searchQuery = '';
                });
                _fetchDonors();
              },
            ),
            _buildBloodGroupChips(screenWidth, screenHeight),
            Expanded(
              child: DonorSection(
                isLoading: isLoading,
                donors: donors,
                searchQuery: searchQuery,
                // selectedCountry: selectedCountry,
                // selectedState: selectedState,
                // selectedDistrict: selectedDistrict,
                // selectedPlace: selectedPlace,
                // selectedBloodGroup: selectedBloodGroup,
                onRefresh: _refreshData,
                onMakePhoneCall: _makePhoneCall,
                calculateAge: _calculateAge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndDonate(double screenWidth, double screenHeight) {
    log("BUTTON CHECK => $isOffline");
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.015,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
onChanged: (value) {

  if (_debounce?.isActive ?? false) {
    _debounce!.cancel();
  }

  _debounce = Timer(
    const Duration(milliseconds: 500),
    () async {

      setState(() {
        searchQuery = value.trim();
      });

      // ✅ OFFLINE
      if (isOffline) {

        _applyFiltersOffline();

      } else {

        // ✅ ONLINE
        await _fetchDonors();
      }
    },
  );
},
              decoration: InputDecoration(
                hintText: "Search by name...",
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
                contentPadding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.0125,
                ),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
         if (!isOffline && bloodId == null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.015,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
              ),
              onPressed: isOffline
    ? null
    : _handleDonateNavigation,
             // onPressed: _handleDonateNavigation,
              child: Text(
                "Donate",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBloodGroupChips(double screenWidth, double screenHeight) {
    return SizedBox(
      height: screenHeight * 0.056,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenHeight * 0.0075,
        ),
        itemCount: bloodGroups.length,
        itemBuilder: (context, index) {
          final bg = bloodGroups[index];
          final isSelected = selectedBloodGroup == bg;
          return Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.02),
            child: ChoiceChip(
              label: Text(bg, style: TextStyle(fontSize: screenWidth * 0.035)),
              selected: isSelected,
              selectedColor: Colors.red,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: screenWidth * 0.035,
              ),
              onSelected: (_) {
                setState(() {
                  selectedBloodGroup = bg == "All" ? '' : bg;
                });
                 _fetchDonors();
              },
            ),
          );
        },
      ),
    );
  }
}
