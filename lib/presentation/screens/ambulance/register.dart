import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/top_snackbar.dart';
import '../auth/signin.dart'; // 👈 Make sure path is correct

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
    _checkLogin(); // 👈 Protect screen
    _loadJson();
    _loadUserPhone();
  }

  /// 🔐 Check login on screen load
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
    final String response =
        await rootBundle.loadString('assets/countries+states+cities.json');
    final data = json.decode(response);

    setState(() {
      jsonData = data;
      countries = data
          .map<Map<String, dynamic>>((c) => {
                'id': c['iso3'],
                'name': c['name'],
                'states': c['states'],
              })
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
                .where((item) => item['name']
                    .toString()
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
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
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
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
          .map((s) => {
                'id': s['state_code'],
                'name': s['name'],
                'cities': s['cities'],
              })
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

  /// 🚀 Submit with login check
  Future<void> _submit() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) {
      showTopSnackBar(context, "Please login first", isError: true);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Signin()),
      );
      return;
    }

    if (_driverNameController.text.isEmpty ||
        _vehicleNumberController.text.isEmpty ||
        vehicleType == null ||
        selectedCountry == null ||
        _placeController.text.isEmpty ||
        _pincodeController.text.isEmpty) {
      showTopSnackBar(context, "Please fill all required fields",
          isError: true);
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

      print(payload);

      showTopSnackBar(context, "Ambulance Registered Successfully");
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
        title: const Text("Register Ambulance",
            style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
            centerTitle: true,
        backgroundColor: Colors.green,
        leading: IconButton(onPressed: (){
          Navigator.pop(context);
        }, icon: Icon(Icons.arrow_back_ios_new, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              readOnly: true,
              decoration:  InputDecoration(labelText: "Phone",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)
              )
              ),
              
            ),
            SizedBox(height: 5,),
            TextField(
              controller: _driverNameController,
              decoration:  InputDecoration(labelText: "Driver Name",
               border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)
              )
              ),
              
            ),
            SizedBox(height: 5,),
            TextField(
              controller: _vehicleNumberController,
              decoration:  InputDecoration(labelText: "Vehicle Number",
               border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)
              )
              ),
            ),
            SizedBox(height: 5,),
            DropdownButtonFormField<String>(
              value: vehicleType,
              items: vehicleTypes
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => vehicleType = val),
              decoration:  InputDecoration(labelText: "Vehicle Type",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)
              )
              ),
              
            ),
            SwitchListTile(
              title: const Text("Available"),
              value: isAvailable,
              onChanged: (val) => setState(() => isAvailable = val),
            ),
            SizedBox(height: 5,),
            TextField(
              controller: _placeController,
              decoration:  InputDecoration(labelText: "Place",
               border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)
              )
              ),
            ),
            SizedBox(height: 5,),
            TextField(
              controller: _pincodeController,
              decoration:  InputDecoration(labelText: "Pincode",
               border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10)
              )
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green
              ),
              onPressed: _submit,
              child: const Text("Register Ambulance",style: TextStyle(color: Colors.white),),
            )
          ],
        ),
      ),
    );
  }
}