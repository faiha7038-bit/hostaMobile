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
    "All", "A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"
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
  try {
    setState(() => isLoading = true);

    final response = await _apiService.getAllDonors();

    if (response.statusCode == 200 && response.data != null) {
      List donorList = [];

      if (response.data is Map && response.data['donors'] != null) {
        donorList = response.data['donors'];
      } else if (response.data is List) {
        donorList = response.data;
      }

      // ✅ SAVE TO LOCAL
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_donors', jsonEncode(donorList));

      setState(() {
        donors = donorList;
      });
    }
  } catch (e) {
    print("❌ API failed, loading from cache");

    // ✅ LOAD FROM LOCAL IF INTERNET FAILS
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cached_donors');

    if (cachedData != null) {
      setState(() {
        donors = jsonDecode(cachedData);
      });
    } else {
      setState(() {
        donors = [];
      });
    }
  } finally {
    setState(() => isLoading = false);
  }
}

  List<String> _extractUniqueValues(List<dynamic> donorList, String field) {
    final values = <String>[];
    
    for (final donor in donorList) {
      final address = donor['address'] ?? {};
      final value = address[field]?.toString().trim() ?? '';
      
      if (value.isNotEmpty && !values.contains(value)) {
        values.add(value);
      }
    }
    
    values.sort();
    return values;
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
      print("Error calculating age for $dateOfBirth: $e");
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
    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          "Blood Donor",
          style: TextStyle(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndDonate(),
            LocationSection(
              selectedCountry: selectedCountry,
              selectedState: selectedState,
              selectedDistrict: selectedDistrict,
              selectedPlace: selectedPlace,
              countries: countries,
              states: states,
              districts: districts,
              places: places,
              donors: donors,
              onLocationSelected: (country, state, district, place) {
                setState(() {
                  selectedCountry = country;
                  selectedState = state;
                  selectedDistrict = district;
                  selectedPlace = place;
                });
              },
              onClear: () {
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
            _buildBloodGroupChips(),
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

  Widget _buildSearchAndDonate() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search by name...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (bloodId == null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _handleDonateNavigation,
              child: const Text("Donate", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildBloodGroupChips() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: bloodGroups.length,
        itemBuilder: (context, index) {
          final bg = bloodGroups[index];
          final isSelected = selectedBloodGroup == bg;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(bg),
              selected: isSelected,
              selectedColor: Colors.red,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
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