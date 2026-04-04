import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api_service.dart';

class Donate extends StatefulWidget {
  const Donate({super.key});

  @override
  State<Donate> createState() => _DonateState();
}

class _DonateState extends State<Donate> {
  final _phoneController = TextEditingController();
  final _placeController = TextEditingController();
  final _pincodeController = TextEditingController();

  final _dobController = TextEditingController();
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();

  String? dateOfBirth;
  String? bloodGroup;

  Map<String, dynamic>? selectedCountry;
  Map<String, dynamic>? selectedState;
  Map<String, dynamic>? selectedDistrict;

  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> states = [];
  List<Map<String, dynamic>> districts = [];
  List<dynamic> jsonData = [];

  final List<String> bloodGroups = ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"];

  @override
  void initState() {
    super.initState();
    _loadJson();
    _loadUserPhone();
  }

  Future<void> _loadJson() async {
    try {
      final String response = await rootBundle.loadString('assets/countries+states+cities.json');
      final data = await json.decode(response);
      setState(() {
        jsonData = data;
        countries = data
            .map<Map<String, dynamic>>(
                (c) => {'id': c['iso3'], 'name': c['name'], 'states': c['states']})
            .toList();
      });
    } catch (e) {
      print("Error loading JSON: $e");
    }
  }

  Future<void> _loadUserPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserPhone = prefs.getString('userPhone');
      if (storedUserPhone != null) {
        setState(() {
          _phoneController.text = storedUserPhone;
        });
      }
    } catch (e) {
      print("Error loading user phone: $e");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth != null
          ? DateFormat('yyyy-MM-dd').parse(dateOfBirth!)
          : DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dateOfBirth = DateFormat('yyyy-MM-dd').format(picked);
        _dobController.text = dateOfBirth!;
      });
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
        return StatefulBuilder(builder: (context, setModalState) {
          filtered = data
              .where((item) => item['name'].toString().toLowerCase().contains(searchQuery.toLowerCase()))
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
                        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    TextField(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: "Search...",
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          searchQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text("No results found"))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return ListTile(
                                  title: Text(item['name'].toString()),
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
        });
      },
    );
  }

  void _onCountrySelected(Map<String, dynamic> country) {
    setState(() {
      selectedCountry = country;
      _countryController.text = country['name'].toString();
      selectedState = null;
      selectedDistrict = null;
      _stateController.clear();
      _districtController.clear();
      states = (country['states'] as List)
          .map((s) => {'id': s['state_code'], 'name': s['name'], 'cities': s['cities']})
          .toList();
      districts = [];
    });
  }

  void _onStateSelected(Map<String, dynamic> state) {
    setState(() {
      selectedState = state;
      _stateController.text = state['name'].toString();
      selectedDistrict = null;
      _districtController.clear();
      districts = (state['cities'] as List)
          .map((d) => {'id': d['id'].toString(), 'name': d['name']})
          .toList();
    });
  }

  void _onDistrictSelected(Map<String, dynamic> district) {
    setState(() {
      selectedDistrict = district;
      _districtController.text = district['name'].toString();
    });
  }

  Future<void> _submit() async {
    if (_phoneController.text.isEmpty ||
        dateOfBirth == null ||
        bloodGroup == null ||
        selectedCountry == null ||
        _placeController.text.isEmpty ||
        _pincodeController.text.isEmpty) {
      
      showTopSnackBar(context, "Please fill all required fields", isError: true);  

      return;
    }


try {
  final prefs = await SharedPreferences.getInstance();
  final storedUserId = prefs.getString('userId');
  
  if (storedUserId == null) {
    showTopSnackBar(context, "User not logged in", isError: true);  
    return;
  }

  final payload = {
    "phone": _phoneController.text,
    "dateOfBirth": dateOfBirth,
    "bloodGroup": bloodGroup,
    "address": {
      "country": selectedCountry!['name'].toString(),
      "state": selectedState!['name'].toString(),
      "district": selectedDistrict!['name'].toString(),
      "place": _placeController.text,
      "pincode": _pincodeController.text,
    },
    "userId": storedUserId,
  };

  final response = await ApiService().createADonor(payload);

  if (response.statusCode == 201) {
    final bloodId = response.data["donor"]["_id"];
    await prefs.setString('bloodId', bloodId);

    showTopSnackBar(context, "Donor Created Successfully");
    Navigator.pop(context);
  } else {
    showTopSnackBar(
      context,
      response.data['message'] ?? 'Donate failed',
      isError: true,
    );
  }

} on DioException catch (dioError) {

  String errorMessage = "Something went wrong";

  if (dioError.response != null) {
    try {
      errorMessage = dioError.response?.data['message'] ?? errorMessage;
    } catch (_) {}
  }

  showTopSnackBar(context, errorMessage, isError: true);

} catch (e) {
  showTopSnackBar(context, "Error: $e", isError: true);
}



  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        title: const Text(
          "Register Blood Donor", 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
         centerTitle: true,
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), // Back button color changed to white
          onPressed: () => Navigator.pop(context),
        ),
      ),
      
      
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _phoneController,
                    readOnly: true,
                    decoration: const InputDecoration(
                        labelText: "Phone", prefixIcon: Icon(Icons.phone)),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _dobController,
                        decoration: const InputDecoration(
                          labelText: "Date of Birth",
                          prefixIcon: Icon(Icons.calendar_today),
                          hintText: "Select DOB",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: bloodGroup,
                    items: bloodGroups
                        .map((bg) => DropdownMenuItem<String>(
                              value: bg,
                              child: Text(bg),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => bloodGroup = val),
                    decoration: const InputDecoration(
                      labelText: "Blood Group",
                      prefixIcon: Icon(Icons.bloodtype),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _openSearchModal(
                        title: "Select Country", data: countries, onSelected: _onCountrySelected),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _countryController,
                        decoration: const InputDecoration(
                          labelText: "Country",
                          prefixIcon: Icon(Icons.public),
                          hintText: "Select Country",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (states.isNotEmpty)
                    GestureDetector(
                      onTap: () => _openSearchModal(
                          title: "Select State", data: states, onSelected: _onStateSelected),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            labelText: "State",
                            prefixIcon: Icon(Icons.map),
                            hintText: "Select State",
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
                          onSelected: _onDistrictSelected),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _districtController,
                          decoration: const InputDecoration(
                            labelText: "District",
                            prefixIcon: Icon(Icons.location_city),
                            hintText: "Select District",
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _placeController,
                    decoration: const InputDecoration(
                      labelText: "Place (local)",
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: "Pincode",
                      prefixIcon: Icon(Icons.pin_drop),
                    ),
                  ),
                  const SizedBox(height: 24),
                 ElevatedButton(
  onPressed: _submit,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
  ),
  child: const Text(
    "Create Donor",
    style: TextStyle(
      color: Colors.white,   // text color
      fontSize: 16,
    ),
  ),
)

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}