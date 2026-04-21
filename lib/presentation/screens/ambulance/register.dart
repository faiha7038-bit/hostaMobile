import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/top_snackbar.dart';

class AmbulanceRegister extends StatefulWidget {
  const AmbulanceRegister({super.key});

  @override
  State<AmbulanceRegister> createState() => _AmbulanceRegisterState();
}

class _AmbulanceRegisterState extends State<AmbulanceRegister> {
  final _phoneController = TextEditingController();
  final _driverNameController = TextEditingController();
  final _vehicleNumberController = TextEditingController();

  final _placeController = TextEditingController();
  final _pincodeController = TextEditingController();

  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();

  String? vehicleType;
  bool isAvailable = true;

  Map<String, dynamic>? selectedCountry;
  Map<String, dynamic>? selectedState;
  Map<String, dynamic>? selectedDistrict;

  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> districts = [];
  List<dynamic> jsonData = [];

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
    _loadJson();
    _loadUserPhone();
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
  }

  Future<void> _loadUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('userPhone');

    if (phone != null) {
      _phoneController.text = phone;
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
        List<Map<String, dynamic>> filtered = data;

        return StatefulBuilder(
          builder: (context, setModalState) {
            filtered = data
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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: "Search...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onChanged: (val) {
                          setModalState(() => searchQuery = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(child: Text("No results"))
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (_, i) {
                                  final item = filtered[i];
                                  return ListTile(
                                    title: Text(item['name']),
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
    });
  }

  void _onDistrictSelected(Map<String, dynamic> district) {
    setState(() {
      selectedDistrict = district;
      _districtController.text = district['name'];
    });
  }

  Future<void> _submit() async {
    print("Country: $selectedCountry");
    print("State: $selectedState");
    print("District: $selectedDistrict");

    if (_driverNameController.text.isEmpty ||
        _vehicleNumberController.text.isEmpty ||
        vehicleType == null ||
        selectedCountry == null ||
        _placeController.text.isEmpty ||
        _pincodeController.text.isEmpty) {
      showTopSnackBar(
        context,
        "Please fill all required fields",
        isError: true,
      );
      return;
    }

    if (states.isNotEmpty && selectedState == null) {
      showTopSnackBar(context, "Please select state", isError: true);
      return;
    }

    if (districts.isNotEmpty && selectedDistrict == null) {
      showTopSnackBar(context, "Please select district", isError: true);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      final payload = {
        "phone": _phoneController.text,
        "driverName": _driverNameController.text,
        "vehicleNumber": _vehicleNumberController.text,
        "vehicleType": vehicleType,
        "isAvailable": isAvailable,
        "address": {
          "country": selectedCountry?['name'],
          "state": selectedState?['name'],
          "district": selectedDistrict?['name'],
          "place": _placeController.text,
          "pincode": _pincodeController.text,
        },
        "userId": userId,
      };

      // final response = await ApiService().createAmbulance(payload);

      // if (response.statusCode == 201) {
      //   showTopSnackBar(context, "Ambulance Registered Successfully");
      //   Navigator.pop(context);
      // } else {
      //   showTopSnackBar(context, "Registration Failed", isError: true);
      // }
    } on DioException catch (e) {
      showTopSnackBar(
        context,
        e.response?.data['message'] ?? "Something went wrong",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        title: const Text(
          "Register Ambulance",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Phone",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _driverNameController,
              decoration: InputDecoration(
                labelText: "Driver Name",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _vehicleNumberController,
              decoration: InputDecoration(
                labelText: "Vehicle Number",
                prefixIcon: Icon(Icons.directions_car),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: vehicleType,
              items: vehicleTypes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => vehicleType = val),
              decoration: InputDecoration(
                labelText: "Vehicle Type",
                prefixIcon: Icon(Icons.local_shipping),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            SwitchListTile(
              title: const Text("Available"),
              value: isAvailable,
              onChanged: (val) => setState(() => isAvailable = val),
            ),

            const SizedBox(height: 12),

            // COUNTRY
            GestureDetector(
              onTap: () => _openSearchModal(
                title: "Select Country",
                data: countries,
                onSelected: _onCountrySelected,
              ),
              child: AbsorbPointer(
                child: TextField(
                  controller: _countryController,
                  decoration: InputDecoration(
                    labelText: "Country",
                    prefixIcon: Icon(Icons.public),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (states.isNotEmpty)
              GestureDetector(
                onTap: () => _openSearchModal(
                  title: "Select State",
                  data: states,
                  onSelected: _onStateSelected,
                ),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _stateController,
                    decoration: InputDecoration(
                      labelText: "State",
                      prefixIcon: Icon(Icons.map),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            if (districts.isNotEmpty)
              GestureDetector(
                onTap: () => _openSearchModal(
                  title: "Select District",
                  data: districts,
                  onSelected: _onDistrictSelected,
                ),
                child: AbsorbPointer(
                  child: TextField(
                    controller: _districtController,
                    decoration: InputDecoration(
                      labelText: "District",
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            TextField(
              controller: _placeController,
              decoration: InputDecoration(
                labelText: "Place",
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Pincode",
                prefixIcon: Icon(Icons.pin_drop),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text(
                "Register Ambulance",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
