import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/top_snackbar.dart';
import '../auth/signin.dart';
import '../../../providers/amb_detail-provider.dart';

class AmbulanceRegister extends ConsumerStatefulWidget {
  final Map<String, dynamic>? editData;

  const AmbulanceRegister({super.key, this.editData});

  @override
  ConsumerState<AmbulanceRegister> createState() => _AmbulanceRegisterState();
}

class _AmbulanceRegisterState extends ConsumerState<AmbulanceRegister> {
  final _phoneController = TextEditingController();
  final _serviceNameController = TextEditingController(); 
  final _placeController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? vehicleType;
  bool isAvailable = true;

  Map<String, dynamic>? selectedCountry;
  Map<String, dynamic>? selectedState;
  Map<String, dynamic>? selectedDistrict;

  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> districts = [];
  List<dynamic> jsonData = [];
  bool isLoading = false;

  final List<String> vehicleTypes = [
    "Ambulance Van",
    "Suv Ambulance",
    "Motorcycle Ambulance",
    "Air Ambulance",
    "Icu Ambulance",
    "Basic Life Ambulance",
  ];

@override
void initState() {
  super.initState();
  _checkLogin();
  _loadJson();
  if (widget.editData == null) {
       _loadUserData();
  } else {
    _fillEditData();    
  }
}

  void _fillEditData() {
    final data = widget.editData!;
    _phoneController.text = data['phone']?.toString() ?? '';
    _serviceNameController.text = data['serviceName']?.toString() ?? ''; // NEW
    vehicleType = data['vehicleType'];

    final address = data['address'] ?? {};
    _placeController.text = address['place'] ?? '';
    _pincodeController.text = (address['pincode'] ?? '').toString();
    _countryController.text = address['country'] ?? '';
    _stateController.text = address['state'] ?? '';
    _districtController.text = address['district'] ?? '';

    _hydrateSelectionsFromSavedData();
  }
// Future<void> _resetAmbulanceFlag() async {
//   final prefs = await SharedPreferences.getInstance();
//   await prefs.remove('ambulanceRegistered');
//   await prefs.remove('ambulanceId');
//   print("🔄 Ambulance flags reset");
// }
  Future<void> _hydrateSelectionsFromSavedData() async {
    if (jsonData.isEmpty) return;

    final savedCountry = _countryController.text;
    final savedState = _stateController.text;
    final savedDistrict = _districtController.text;

    if (savedCountry.isEmpty) return;

    final country = countries.firstWhere(
      (c) => c['name'] == savedCountry,
      orElse: () => {},
    );
    if (country.isEmpty) return;
    setState(() {
      selectedCountry = country;
      states = (country['states'] as List)
          .map(
            (s) => {
              'id': s['state_code'],
              'name': s['name'],
              'cities': s['cities'],
            },
          )
          .toList();
    });

    if (savedState.isEmpty) return;
    final state = states.firstWhere(
      (s) => s['name'] == savedState,
      orElse: () => {},
    );
    if (state.isEmpty) return;
    setState(() {
      selectedState = state;
      districts = (state['cities'] as List)
          .map((d) => {'id': d['id'], 'name': d['name']})
          .toList();
    });

    if (savedDistrict.isEmpty) return;
    final district = districts.firstWhere(
      (d) => d['name'] == savedDistrict,
      orElse: () => {},
    );
    if (district.isNotEmpty) {
      setState(() {
        selectedDistrict = district;
      });
    }
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Signin()),
      );
    }
  }

  Future<void> _loadJson() async {
    final String response = await rootBundle.loadString(
      'assets/countries+states+cities.json',
    );
    final data = json.decode(response);
    setState(() {
      jsonData = data;
      countries = data
          .map<Map<String, dynamic>>(
            (c) => {'id': c['iso3'], 'name': c['name'], 'states': c['states']},
          )
          .toList();
    });
    if (widget.editData != null) {
      _hydrateSelectionsFromSavedData();
    }
  }

 Future<void> _loadUserData() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');

  if (userId == null || userId.isEmpty) return;

  try {
    final apiService = ApiService();

    final response = await apiService.getAUser(userId);

    print("USER RESPONSE => ${response.data}");

    if (response.data != null) {
      final user = response.data['data'] ?? response.data;

      setState(() {
        _phoneController.text =
            user['mobileNumber']?.toString() ??
            user['phone']?.toString() ??
            '';

        // optional
        _placeController.text =
            user['address']?['place']?.toString() ?? '';
      });
    }
  } catch (e) {
    print("LOAD USER ERROR => $e");
  }
}

  Future<void> _openSearchModal({
    required String title,
    required List<Map<String, dynamic>> data,
    required Function(Map<String, dynamic>) onSelected,
  }) async {
    String searchQuery = "";
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = data
                .where(
                  (item) => item['name'].toString().toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ),
                )
                .toList();
            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.6,
                  padding: EdgeInsets.all(
                    MediaQuery.of(context).size.width * 0.04,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      MediaQuery.of(context).size.width * 0.03,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: MediaQuery.of(context).size.width * 0.06,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.search,
                            size: MediaQuery.of(context).size.width * 0.06,
                          ),
                          hintText: "Search...",
                          hintStyle: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.05,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical:
                                MediaQuery.of(context).size.height * 0.0125,
                          ),
                        ),
                        onChanged: (val) {
                          setModalState(() => searchQuery = val);
                        },
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.015,
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  "No results",
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                        0.04,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (_, i) {
                                  final item = filtered[i];
                                  return ListTile(
                                    title: Text(
                                      item['name'],
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                            0.04,
                                      ),
                                    ),
                                    onTap: () {
                                      onSelected(item);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onCountrySelected(Map<String, dynamic> country) {
    setState(() {
      selectedCountry = country;
      _countryController.text = country['name'];
      selectedState = null;
      selectedDistrict = null;
      _stateController.clear();
      _districtController.clear();
      states = (country['states'] as List)
          .map(
            (s) => {
              'id': s['state_code'],
              'name': s['name'],
              'cities': s['cities'],
            },
          )
          .toList();
      districts = [];
    });
  }

void _onStateSelected(Map<String, dynamic> state) {
  setState(() {
    selectedState = state;
    _stateController.text = state['name'];
    selectedDistrict = null;
    _districtController.clear();
    districts = (state['cities'] as List)
        .map((d) => {'id': d['id'], 'name': d['name']})
        .toList();
    // If no districts, clear any previous district data
    if (districts.isEmpty) {
      selectedDistrict = null;
      _districtController.clear();
    }
  });
}
  void _onDistrictSelected(Map<String, dynamic> district) {
    setState(() {
      selectedDistrict = district;
      _districtController.text = district['name'];
    });
  }
Future<void> _submit() async {
  if (isLoading) return;
  if (!_formKey.currentState!.validate()) return;

  // Custom validations
// Custom validations
if (_countryController.text.trim().isEmpty) {
  showTopSnackBar(context, "Please select a country", isError: true);
  return;
}
if (_countryController.text.trim().isEmpty) {
  showTopSnackBar(context, "Please select a country", isError: true);
  return;
}

// Only require state if this country actually has states
if (states.isNotEmpty && _stateController.text.trim().isEmpty) {
  showTopSnackBar(context, "Please select a state", isError: true);
  return;
}

// Only require district if selected state has districts
if (districts.isNotEmpty && _districtController.text.trim().isEmpty) {
  showTopSnackBar(context, "Please select a district", isError: true);
  return;
}

// ✅ Only validate district if there are districts for the selected state
if (districts.isNotEmpty && _districtController.text.trim().isEmpty) {
  showTopSnackBar(context, "Please select a district", isError: true);
  return;
}
  final pincode = _pincodeController.text.trim();
  if (pincode.isEmpty) {
    showTopSnackBar(context, "Pincode is required", isError: true);
    return;
  }
  if (pincode.length != 6) {
    showTopSnackBar(context, "Pincode must be 6 digits", isError: true);
    return;
  }

  setState(() => isLoading = true);

  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) throw Exception("User not logged in");

 final country = _countryController.text.trim();
final state = _stateController.text.trim();
final district = _districtController.text.trim();

final address = {
  "country": country,
  "place": _placeController.text.trim(),
  "pincode": int.parse(pincode),
};

// Add state only if selected
if (state.isNotEmpty) {
  address["state"] = state;
}

// Add district only if selected
if (district.isNotEmpty) {
  address["district"] = district;
}

final payload = {
  "phone": _phoneController.text.trim(),
  "serviceName": _serviceNameController.text.trim(),
  "vehicleType": vehicleType,
  "address": address,
  "userId": int.parse(userId),
};

    final notifier = ref.read(ambulanceListProvider.notifier);
    bool success;

    if (widget.editData == null) {
      success = await notifier.createAmbulance(payload);
    } else {
      final id = widget.editData!['id']?.toString();
      if (id == null) throw Exception("ID missing");
      success = await notifier.editAmbulance(id, payload);
    }

    if (!mounted) return;

    if (success) {
      await prefs.setBool('ambulanceRegistered', true);
      showTopSnackBar(
        context,
        widget.editData == null ? "Registered Successfully" : "Updated Successfully",
      );
      Navigator.pop(context, {"refresh": true});
    } else {
      showTopSnackBar(
        context,
        "This mobile number already registered",
        isError: true,
      );
    }
  } catch (e) {
    log("ERROR => $e");
    showTopSnackBar(context, e.toString(), isError: true);
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        title: Text(
          widget.editData == null ? "Register Ambulance" : "Edit Ambulance",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: screenWidth * 0.055),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Center(
           child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: screenWidth > 600 ? 400 : double.infinity),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
              children: [
                // Phone field
                TextFormField(
                  controller: _phoneController,
                  readOnly: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone",
                    labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.025)),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.015),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return "Phone number is required";
                    if (value.trim().length != 10)
                      return "Phone number must be 10 digits";
                    return null;
                  },
                ),
                SizedBox(height: screenHeight * 0.015),
          
                // NEW: Service Name text field
                TextFormField(
                  controller: _serviceNameController,
                  decoration: InputDecoration(
                    labelText: "Service Name",
                    hintText: "e.g., City Care Ambulance",
                    labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.025)),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.015),
                  ),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? "Service name is required" : null,
                ),
                SizedBox(height: screenHeight * 0.012),
          
                // Vehicle Type dropdown
                DropdownButtonFormField<String>(
                  value: vehicleType,
                  validator: (value) =>
                      (value == null || value.isEmpty) ? "Select vehicle type" : null,
                  items: vehicleTypes
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e, style: TextStyle(fontSize: screenWidth * 0.04)),
                          ))
                      .toList(),
                  onChanged: (val) => setState(() => vehicleType = val),
                  decoration: InputDecoration(
                    labelText: "Vehicle Type",
                    labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.025)),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.015),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),
          
                // Country (searchable)
                GestureDetector(
                  onTap: () => _openSearchModal(
                      title: "Select Country", data: countries, onSelected: _onCountrySelected),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _countryController,
                      decoration: InputDecoration(
                        labelText: "Country",
                        labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                        prefixIcon: Icon(Icons.public, size: screenWidth * 0.055),
                        hintText: "Select Country",
                        hintStyle: TextStyle(fontSize: screenWidth * 0.035),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.025)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03, vertical: screenHeight * 0.015),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.012),
          
                // State (only visible after country selection)
                if (states.isNotEmpty)
                  GestureDetector(
                    onTap: () => _openSearchModal(
                        title: "Select State", data: states, onSelected: _onStateSelected),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _stateController,
                        decoration: InputDecoration(
                          labelText: "State",
                          labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                          prefixIcon: Icon(Icons.map, size: screenWidth * 0.055),
                          hintText: "Select State",
                          hintStyle: TextStyle(fontSize: screenWidth * 0.035),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.025)),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03, vertical: screenHeight * 0.015),
                        ),
                      ),
                    ),
                  ),
                if (states.isNotEmpty) SizedBox(height: screenHeight * 0.012),
          
                // District (only visible after state selection)
                if (districts.isNotEmpty)
                  GestureDetector(
                    onTap: () => _openSearchModal(
                        title: "Select District", data: districts, onSelected: _onDistrictSelected),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _districtController,
                        decoration: InputDecoration(
                          labelText: "District",
                          labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                          prefixIcon: Icon(Icons.location_city, size: screenWidth * 0.055),
                          hintText: "Select District",
                          hintStyle: TextStyle(fontSize: screenWidth * 0.035),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.025)),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03, vertical: screenHeight * 0.015),
                        ),
                      ),
                    ),
                  ),
                if (districts.isNotEmpty) SizedBox(height: screenHeight * 0.012),
          
                // Place
                TextFormField(
                  controller: _placeController,
                  decoration: InputDecoration(
                    labelText: "Place",
                    labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.025)),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03, vertical: screenHeight * 0.015),
                  ),
                    validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Place is required";
              }
              return null;
            },
                ),
                SizedBox(height: screenHeight * 0.012),
          
                // Pincode
                TextFormField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: "Pincode",
                    labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.025)),
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03, vertical: screenHeight * 0.015),
                  ),
                   validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Pincode is required";
              }
              if (value.trim().length != 6) {
                return "Enter valid pincode";
              }
              return null;
            },
                ),
                SizedBox(height: screenHeight * 0.025),
          
                // Submit button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.08, vertical: screenHeight * 0.015),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.025)),
                  ),
                  onPressed: _submit,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.editData == null ? "Register Ambulance" : "Update Ambulance",
                          style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
        ),
    )
    );
  }
}