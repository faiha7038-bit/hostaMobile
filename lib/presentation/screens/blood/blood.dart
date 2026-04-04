import 'package:flutter/material.dart';
import 'package:hosta/presentation/screens/donate/donate.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart'; // Import ApiService directly

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

  final ApiService _apiService = ApiService(); // Create instance directly

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
        // Handle different response formats
        dynamic donorData;
        
        if (response.data is Map) {
          // If response is a map, check for common keys
          if (response.data['donors'] != null) {
            donorData = response.data['donors'];
          } else if (response.data['data'] != null) {
            donorData = response.data['data'];
          } else {
            // If no specific key, use the entire response as list
            donorData = response.data is List ? response.data : [];
          }
        } else if (response.data is List) {
          donorData = response.data;
        } else {
          donorData = [];
        }
        
        final donorList = donorData is List ? donorData : [];
        
        print("📊 Raw donor data length: ${donorList.length}");
        
        setState(() {
          donors = donorList;

          // Extract unique values from all donors
          countries = _extractUniqueValues(donorList, 'country');
          states = _extractUniqueValues(donorList, 'state');
          districts = _extractUniqueValues(donorList, 'district');
          places = _extractUniqueValues(donorList, 'place');
        });

    
      } else {
        setState(() {
          donors = [];
        });
      }
    } catch (e) {
      print("❌ Error loading donors: $e");
      print("❌ Error type: ${e.runtimeType}");
      setState(() {
        donors = [];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Helper method to extract unique values from address field
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

  // Calculate age from date of birth
  int _calculateAge(String dateOfBirth) {
    try {
      // Handle both formats: "1990-01-01T00:00:00.000Z" and "1990-01-01"
      DateTime birthDate;
      if (dateOfBirth.contains('T')) {
        birthDate = DateTime.parse(dateOfBirth);
      } else {
        birthDate = DateTime.parse('${dateOfBirth}T00:00:00.000Z');
      }
      
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      
      // Check if birthday hasn't occurred this year yet
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

  // Helper methods to get filtered locations based on TEMPORARY selections
  List<String> getFilteredStates(String country) {
    if (country.isEmpty) return [];
    
    final filteredStates = <String>[];
    for (final donor in donors) {
      final address = donor['address'] ?? {};
      final donorCountry = address['country']?.toString().trim() ?? '';
      final state = address['state']?.toString().trim() ?? '';
      
      if (donorCountry == country && state.isNotEmpty && !filteredStates.contains(state)) {
        filteredStates.add(state);
      }
    }
    
    filteredStates.sort();
    return filteredStates;
  }

  List<String> getFilteredDistricts(String country, String state) {
    if (country.isEmpty || state.isEmpty) return [];
    
    final filteredDistricts = <String>[];
    for (final donor in donors) {
      final address = donor['address'] ?? {};
      final donorCountry = address['country']?.toString().trim() ?? '';
      final donorState = address['state']?.toString().trim() ?? '';
      final district = address['district']?.toString().trim() ?? '';
      
      if (donorCountry == country && 
          donorState == state && 
          district.isNotEmpty && 
          !filteredDistricts.contains(district)) {
        filteredDistricts.add(district);
      }
    }
    
    filteredDistricts.sort();
    return filteredDistricts;
  }

  List<String> getFilteredPlaces(String country, String state, String district) {
    if (country.isEmpty || state.isEmpty || district.isEmpty) return [];
    
    final filteredPlaces = <String>[];
    for (final donor in donors) {
      final address = donor['address'] ?? {};
      final donorCountry = address['country']?.toString().trim() ?? '';
      final donorState = address['state']?.toString().trim() ?? '';
      final donorDistrict = address['district']?.toString().trim() ?? '';
      final place = address['place']?.toString().trim() ?? '';
      
      if (donorCountry == country && 
          donorState == state && 
          donorDistrict == district && 
          place.isNotEmpty && 
          !filteredPlaces.contains(place)) {
        filteredPlaces.add(place);
      }
    }
    
    filteredPlaces.sort();
    return filteredPlaces;
  }

  void _handleDonateNavigation() {
    if (userId == null) {
      // Navigate to Signin page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Signin()),
      ).then((_) {
        // Reload user data after returning from Signin page
        _loadUserData();
      });
    } else if (bloodId == null) {
      // Navigate to Donate page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Donate()),
      ).then((_) {
        // Reload bloodId after returning from Donate page
        _loadUserData();
      });
    }
    // If bloodId exists, do nothing (no button shown)
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
            _buildLocationAndClearButton(context),
            _buildBloodGroupChips(),
            Expanded(
              child: _buildDonorList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonorList() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text(
              "Loading donors...",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // ✅ Apply all filters
    final filteredDonors = donors.where((donor) {
      final user = donor['userId'] ?? {};
      final address = donor['address'] ?? {};

      final name = (user['name'] ?? '').toLowerCase();
      final bloodGroup = (donor['bloodGroup'] ?? '');
      final country = (address['country'] ?? '');
      final state = (address['state'] ?? '');
      final district = (address['district'] ?? '');
      final place = (address['place'] ?? '');

      final matchesSearch = name.contains(searchQuery.toLowerCase());
      final matchesCountry = selectedCountry.isEmpty || country == selectedCountry;
      final matchesState = selectedState.isEmpty || state == selectedState;
      final matchesDistrict = selectedDistrict.isEmpty || district == selectedDistrict;
      final matchesPlace = selectedPlace.isEmpty || place == selectedPlace;
      final matchesBlood = selectedBloodGroup.isEmpty ||
          selectedBloodGroup == "All" ||
          bloodGroup == selectedBloodGroup;

      return matchesSearch &&
          matchesCountry &&
          matchesState &&
          matchesDistrict &&
          matchesPlace &&
          matchesBlood;
    }).toList();

    if (filteredDonors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              donors.isEmpty ? Icons.error_outline : Icons.search_off,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              donors.isEmpty ? "No donors available" : "No donors found",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              donors.isEmpty 
                ? "Check your connection or try again later"
                : "Try adjusting your filters",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (donors.isEmpty) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _refreshData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  "Try Again",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filteredDonors.length,
      itemBuilder: (context, index) {
        return _buildDonorCard(filteredDonors[index]);
      },
    );
  }

  // --- Search and Donate ---
  Widget _buildSearchAndDonate() => Padding(
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
            // Show Donate button ONLY if bloodId doesn't exist
            if (bloodId == null) ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _handleDonateNavigation,
                child: const Text("Donate", style: TextStyle(color: Colors.white)),
              ),
            ] else ...[
              // Show registered status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text("Registered", style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

  // --- Location and Clear Button ---
  Widget _buildLocationAndClearButton(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _openLocationFilter(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    selectedCountry.isEmpty
                        ? "Select Location"
                        : "$selectedCountry > $selectedState > $selectedDistrict > $selectedPlace",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  selectedCountry = '';
                  selectedState = '';
                  selectedDistrict = '';
                  selectedPlace = '';
                  selectedBloodGroup = '';
                  searchQuery = '';
                });
              },
              icon: const Icon(Icons.clear, color: Colors.red),
              label: const Text("Clear", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

  // --- Blood Group Chips ---
  Widget _buildBloodGroupChips() => SizedBox(
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

  // --- Donor Card ---
  Widget _buildDonorCard(Map<String, dynamic> donor) {
    final user = donor['userId'] ?? {};
    final address = donor['address'] ?? {};
    final bloodColor = Colors.red.shade700;
    
    // Calculate age from date of birth
    final dateOfBirth = donor['dateOfBirth']?.toString() ?? '';
    final age = dateOfBirth.isNotEmpty ? _calculateAge(dateOfBirth) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
      ),
      child: Row(
        children: [
          // Blood Group Circle
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(color: bloodColor, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              donor["bloodGroup"] ?? "",
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 16, 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  user["name"] ?? "Unknown",
                  style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Age
                if (age > 0)
                  Text(
                    "$age years",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  address["place"] ?? "", 
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  "${address["district"] ?? ""}, ${address["state"] ?? ""}, ${address["country"] ?? ""}",
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _makePhoneCall(user["phone"] ?? ""),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.call, size: 18, color: Colors.white),
            label: const Text("Call", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- Location Filter Dialog ---
  void _openLocationFilter(BuildContext context) {
    String tempCountry = selectedCountry;
    String tempState = selectedState;
    String tempDistrict = selectedDistrict;
    String tempPlace = selectedPlace;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          
          // Get filtered locations based on current TEMPORARY selections
          List<String> filteredStates = getFilteredStates(tempCountry);
          List<String> filteredDistricts = getFilteredDistricts(tempCountry, tempState);
          List<String> filteredPlaces = getFilteredPlaces(tempCountry, tempState, tempDistrict);

          return Padding(
           padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: Text(
                      "Select Location",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
          
                  // Country Dropdown (Always shown)
                  DropdownButtonFormField<String>(
                    value: tempCountry.isEmpty ? null : tempCountry,
                    decoration: const InputDecoration(
                      labelText: "Country *",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text("Select Country", style: TextStyle(color: Colors.grey)),
                      ),
                      ...countries.map((country) {
                        return DropdownMenuItem(
                          value: country,
                          child: Text(country),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        tempCountry = value ?? '';
                        tempState = '';
                        tempDistrict = '';
                        tempPlace = '';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
          
                  // State Dropdown (Only shown when country is selected)
                  if (tempCountry.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: tempState.isEmpty ? null : tempState,
                      decoration: const InputDecoration(
                        labelText: "State *",
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text("Select State", style: TextStyle(color: Colors.grey)),
                        ),
                        ...filteredStates.map((state) {
                          return DropdownMenuItem(
                            value: state,
                            child: Text(state),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempState = value ?? '';
                          tempDistrict = '';
                          tempPlace = '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
          
                  // District Dropdown (Only shown when state is selected)
                  if (tempCountry.isNotEmpty && tempState.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: tempDistrict.isEmpty ? null : tempDistrict,
                      decoration: const InputDecoration(
                        labelText: "District *",
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text("Select District", style: TextStyle(color: Colors.grey)),
                        ),
                        ...filteredDistricts.map((district) {
                          return DropdownMenuItem(
                            value: district,
                            child: Text(district),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempDistrict = value ?? '';
                          tempPlace = '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
          
                  // Place Dropdown (Only shown when district is selected)
                  if (tempCountry.isNotEmpty && tempState.isNotEmpty && tempDistrict.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                    isExpanded: true,
                      value: tempPlace.isEmpty ? null : tempPlace,
                      decoration: const InputDecoration(
                        labelText: "Place",
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text("Select Place", style: TextStyle(color: Colors.grey)),
                        ),
                        ...filteredPlaces.map((place) {
                          return DropdownMenuItem(
                            value: place,
                            
                            child: Text(place),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempPlace = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
          
                  const SizedBox(height: 24),
          
                  // Apply Filter Button
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedCountry = tempCountry;
                        selectedState = tempState;
                        selectedDistrict = tempDistrict;
                        selectedPlace = tempPlace;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Apply Filter",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        });
      }, 
    );
  }
}