import 'dart:convert';
import 'package:flutter/material.dart';
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

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchDonors();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedBloodId = prefs.getString('bloodId');
      final storedUserId = prefs.getString('userId');

      setState(() {
        bloodId = storedBloodId;
        userId = storedUserId;
      });
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

Future<void> _fetchDonors() async {
  print("🔵 _fetchDonors called");
  try {
    setState(() => isLoading = true);

    final response = await _apiService.getAllDonors();
    print("📡 Status: ${response.statusCode}");
    print("📦 Raw data: ${response.data}");

    if (response.statusCode == 200 && response.data != null) {
      List donorList = [];

      // ✅ Backend response ൽ 'data' ആണ് key
      if (response.data is Map && response.data['data'] != null) {
        donorList = response.data['data'];
      }
      // Fallback (old format)
      else if (response.data is Map && response.data['donors'] != null) {
        donorList = response.data['donors'];
      }
      else if (response.data is List) {
        donorList = response.data;
      }

      print("✅ Donors found: ${donorList.length}");

      if (donorList.isNotEmpty) {
        // Cache ൽ save ചെയ്യുക
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_donors', jsonEncode(donorList));

        setState(() {
          donors = donorList;
          _extractLocationData(donorList);
        });
      } else {
        setState(() => donors = []);
      }
    } else {
      // Response not OK
      setState(() => donors = []);
    }
  } catch (e, stack) {
    print("❌ API error: $e");
    print(stack);
    // Cache ൽ നിന്ന് load ചെയ്യുക
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_donors');
    if (cachedData != null) {
      final donorList = jsonDecode(cachedData);
      setState(() {
        donors = donorList;
        _extractLocationData(donorList);
      });
    } else {
      // No cache, empty list (UI will show "Check network")
      setState(() {
        donors = [];
        countries = [];
        states = [];
        districts = [];
        places = [];
      });
    }
  } finally {
    setState(() => isLoading = false);
  }
}

  void _extractLocationData(List<dynamic> donorList) {
    final uniqueCountries = <String>{};
    final uniqueStates = <String>{};
    final uniqueDistricts = <String>{};
    final uniquePlaces = <String>{};

    for (final donor in donorList) {
      final address = donor['address'] ?? {};

      final country = address['country']?.toString().trim() ?? '';
      final state = address['state']?.toString().trim() ?? '';
      final district = address['district']?.toString().trim() ?? '';
      final place = address['place']?.toString().trim() ?? '';

      if (country.isNotEmpty && country != 'null') uniqueCountries.add(country);
      if (state.isNotEmpty && state != 'null') uniqueStates.add(state);
      if (district.isNotEmpty && district != 'null')
        uniqueDistricts.add(district);
      if (place.isNotEmpty && place != 'null') uniquePlaces.add(place);
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
        _loadUserData();
      });
    } else if (bloodId == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Donate()),
      ).then((_) {
        _loadUserData();
      });
    }
  }

  void _refreshData() {
    _fetchDonors();
    _loadUserData();
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
              },
            ),
            _buildBloodGroupChips(screenWidth, screenHeight),
            Expanded(
              child: DonorSection(
                isLoading: isLoading,
                donors: donors,
                searchQuery: searchQuery,
                selectedCountry: selectedCountry,
                selectedState: selectedState,
                selectedDistrict: selectedDistrict,
                selectedPlace: selectedPlace,
                selectedBloodGroup: selectedBloodGroup,
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
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.015,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
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
          if (bloodId == null)
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
              onPressed: _handleDonateNavigation,
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
              },
            ),
          );
        },
      ),
    );
  }
}
