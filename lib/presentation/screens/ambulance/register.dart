import 'dart:convert';
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

  // Helper to clamp responsive values between safe limits
  double _clamp(double value, double min, double max) =>
      value.clamp(min, max) as double;

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
    _serviceNameController.text = data['serviceName']?.toString() ?? '';
    vehicleType = data['vehicleType'];

    final address = data['address'] ?? {};
    _placeController.text = address['place'] ?? '';
    _pincodeController.text = (address['pincode'] ?? '').toString();
    _countryController.text = address['country'] ?? '';
    _stateController.text = address['state'] ?? '';
    _districtController.text = address['district'] ?? '';

    _hydrateSelectionsFromSavedData();
  }

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

      if (response.data != null) {
        final user = response.data['data'] ?? response.data;

        setState(() {
          _phoneController.text = user['mobileNumber']?.toString() ??
              user['phone']?.toString() ??
              '';

          _placeController.text = user['address']?['place']?.toString() ?? '';
        });
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _openSearchModal({
    required String title,
    required List<Map<String, dynamic>> data,
    required Function(Map<String, dynamic>) onSelected,
    required double screenWidth,
    required double screenHeight,
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
                  width: _clamp(screenWidth * 0.9, 300, 600),
                  height: _clamp(screenHeight * 0.6, 400, 700),
                  padding: EdgeInsets.all(_clamp(screenWidth * 0.04, 12, 24)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                        _clamp(screenWidth * 0.03, 8, 20)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: _clamp(screenWidth * 0.045, 16, 28),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: _clamp(screenWidth * 0.06, 24, 40),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.search,
                            size: _clamp(screenWidth * 0.06, 20, 32),
                          ),
                          hintText: "Search...",
                          hintStyle: TextStyle(
                            fontSize: _clamp(screenWidth * 0.035, 12, 20),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                _clamp(screenWidth * 0.05, 20, 40)),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: _clamp(screenHeight * 0.0125, 8, 20),
                          ),
                        ),
                        onChanged: (val) {
                          setModalState(() => searchQuery = val);
                        },
                      ),
                      SizedBox(
                        height: _clamp(screenHeight * 0.015, 8, 24),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  "No results",
                                  style: TextStyle(
                                    fontSize:
                                        _clamp(screenWidth * 0.04, 14, 24),
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
                                            _clamp(screenWidth * 0.04, 14, 24),
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

    if (_countryController.text.trim().isEmpty) {
      showTopSnackBar(context, "Please select a country", isError: true);
      return;
    }
    if (states.isNotEmpty && _stateController.text.trim().isEmpty) {
      showTopSnackBar(context, "Please select a state", isError: true);
      return;
    }
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

      if (state.isNotEmpty) {
        address["state"] = state;
      }

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
          widget.editData == null
              ? "Registered Successfully"
              : "Updated Successfully",
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
      showTopSnackBar(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive clamped values for frequent use
    final double titleSize = _clamp(screenWidth * 0.05, 16, 28);
    final double backIconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double labelSize = _clamp(screenWidth * 0.035, 12, 18);
    final double fieldRadius = _clamp(screenWidth * 0.025, 8, 16);
    final double fieldPaddingH = screenWidth * 0.03;
    final double fieldPaddingV = screenHeight * 0.015;
    final double spacingSmall = screenHeight * 0.012;
    final double spacingMedium = screenHeight * 0.015;
    final double spacingLarge = screenHeight * 0.02;
    final double spacingXLarge = screenHeight * 0.025;
    final double buttonPaddingH = screenWidth * 0.08;
    final double buttonPaddingV = screenHeight * 0.015;
    final double buttonRadius = _clamp(screenWidth * 0.025, 8, 16);
    final double buttonFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double iconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double dropdownFontSize = _clamp(screenWidth * 0.04, 14, 22);

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        title: Text(
          widget.editData == null ? "Register Ambulance" : "Edit Ambulance",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: titleSize,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: backIconSize),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth > 600
                    ? _clamp(screenWidth * 0.6, 350, 500)
                    : double.infinity,
              ),
              child: Padding(
                padding: EdgeInsets.all(_clamp(screenWidth * 0.04, 12, 24)),
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
                        labelStyle: TextStyle(fontSize: labelSize),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fieldRadius)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: fieldPaddingH, vertical: fieldPaddingV),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return "Phone number is required";
                        if (value.trim().length != 10)
                          return "Phone number must be 10 digits";
                        return null;
                      },
                    ),
                    SizedBox(height: spacingMedium),

                    TextFormField(
                      controller: _serviceNameController,
                      decoration: InputDecoration(
                        labelText: "Service Name",
                        hintText: "e.g., City Care Ambulance",
                        labelStyle: TextStyle(fontSize: labelSize),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fieldRadius)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: fieldPaddingH, vertical: fieldPaddingV),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? "Service name is required"
                              : null,
                    ),
                    SizedBox(height: spacingSmall),

                    DropdownButtonFormField<String>(
                      value: vehicleType,
                      validator: (value) => (value == null || value.isEmpty)
                          ? "Select vehicle type"
                          : null,
                      items: vehicleTypes
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e,
                                    style:
                                        TextStyle(fontSize: dropdownFontSize)),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => vehicleType = val),
                      decoration: InputDecoration(
                        labelText: "Vehicle Type",
                        labelStyle: TextStyle(fontSize: labelSize),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fieldRadius)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: fieldPaddingH, vertical: fieldPaddingV),
                      ),
                    ),
                    SizedBox(height: spacingLarge),

                    GestureDetector(
                      onTap: () => _openSearchModal(
                        title: "Select Country",
                        data: countries,
                        onSelected: _onCountrySelected,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                      ),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _countryController,
                          decoration: InputDecoration(
                            labelText: "Country",
                            labelStyle: TextStyle(fontSize: labelSize),
                            prefixIcon: Icon(Icons.public, size: iconSize),
                            hintText: "Select Country",
                            hintStyle: TextStyle(fontSize: labelSize),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(fieldRadius)),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: fieldPaddingH,
                                vertical: fieldPaddingV),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: spacingSmall),

                    if (states.isNotEmpty)
                      GestureDetector(
                        onTap: () => _openSearchModal(
                          title: "Select State",
                          data: states,
                          onSelected: _onStateSelected,
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                        ),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _stateController,
                            decoration: InputDecoration(
                              labelText: "State",
                              labelStyle: TextStyle(fontSize: labelSize),
                              prefixIcon: Icon(Icons.map, size: iconSize),
                              hintText: "Select State",
                              hintStyle: TextStyle(fontSize: labelSize),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fieldRadius)),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: fieldPaddingH,
                                  vertical: fieldPaddingV),
                            ),
                          ),
                        ),
                      ),
                    if (states.isNotEmpty) SizedBox(height: spacingSmall),

                    if (districts.isNotEmpty)
                      GestureDetector(
                        onTap: () => _openSearchModal(
                          title: "Select District",
                          data: districts,
                          onSelected: _onDistrictSelected,
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                        ),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _districtController,
                            decoration: InputDecoration(
                              labelText: "District",
                              labelStyle: TextStyle(fontSize: labelSize),
                              prefixIcon:
                                  Icon(Icons.location_city, size: iconSize),
                              hintText: "Select District",
                              hintStyle: TextStyle(fontSize: labelSize),
                              border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(fieldRadius)),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: fieldPaddingH,
                                  vertical: fieldPaddingV),
                            ),
                          ),
                        ),
                      ),
                    if (districts.isNotEmpty) SizedBox(height: spacingSmall),

                    // Place
                    TextFormField(
                      controller: _placeController,
                      decoration: InputDecoration(
                        labelText: "Place",
                        labelStyle: TextStyle(fontSize: labelSize),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fieldRadius)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: fieldPaddingH, vertical: fieldPaddingV),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Place is required";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: spacingSmall),

                    // Pincode
                    TextFormField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: "Pincode",
                        labelStyle: TextStyle(fontSize: labelSize),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fieldRadius)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: fieldPaddingH, vertical: fieldPaddingV),
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
                    SizedBox(height: spacingXLarge),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(
                            horizontal: buttonPaddingH,
                            vertical: buttonPaddingV),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(buttonRadius)),
                      ),
                      onPressed: _submit,
                      child: isLoading
                          ? CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: _clamp(screenWidth * 0.008, 2, 6),
                            )
                          : Text(
                              widget.editData == null
                                  ? "Register Ambulance"
                                  : "Update Ambulance",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: buttonFontSize),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
