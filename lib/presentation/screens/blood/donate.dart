import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/providers/blood-donateprovider.dart';
import 'package:hosta/providers/blood_details_provider.dart';
import 'package:hosta/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:hosta/common/top_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Donate extends ConsumerStatefulWidget {
  final Map<String, dynamic>? editData; 

  const Donate({super.key, this.editData}); 

  @override
  ConsumerState<Donate> createState() => _DonateState();
}

class _DonateState extends ConsumerState<Donate> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _placeController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _dobController = TextEditingController();
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> bloodGroups = [
    "A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    if (widget.editData != null) {
        Future(() {
    _fillEditData();
  });
    }
  }

  void _fillEditData() {
    final data = widget.editData!;
    _nameController.text = data['name'] ?? '';
    _phoneController.text = data['phone'] ?? '';

    final address = data['address'] ?? {};
    _placeController.text = address['place'] ?? '';
    _pincodeController.text = (address['pincode'] ?? '').toString();
    _countryController.text = address['country'] ?? '';
    _stateController.text = address['state'] ?? '';
    _districtController.text = address['district'] ?? '';

    final bloodGroup = data['bloodGroup'];
    if (bloodGroup != null) {
      ref.read(donorFormProvider.notifier).updateBloodGroup(bloodGroup);
    }

    final dob = data['dateOfBirth'];
    if (dob != null) {
      final formatted = dob.toString().split('T').first;
      ref.read(donorFormProvider.notifier).updateDateOfBirth(formatted);
      _dobController.text = formatted;
    }

    // Hydrate country/state/district after JSON loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hydrateSelectionsFromSavedData();
    });
  }

  Future<void> _hydrateSelectionsFromSavedData() async {
    final locationAsync = ref.read(locationDataProvider);
    if (locationAsync.value == null) return;

    final savedCountry = _countryController.text;
    final savedState = _stateController.text;
    final savedDistrict = _districtController.text;
    if (savedCountry.isEmpty) return;

    final countries = locationAsync.value!;
    final country = countries.firstWhere(
      (c) => c['name'] == savedCountry,
      orElse: () => {},
    );
    if (country.isEmpty) return;

    // Update provider with selected country
    ref.read(donorFormProvider.notifier).updateSelectedCountry(country);
    final states = (country['states'] as List)
        .map((s) => {'id': s['state_code'], 'name': s['name'], 'cities': s['cities']})
        .toList();
    ref.read(donorFormProvider.notifier).updateStates(states);

    if (savedState.isEmpty) return;
    final state = states.firstWhere((s) => s['name'] == savedState, orElse: () => {});
    if (state.isEmpty) return;
    ref.read(donorFormProvider.notifier).updateSelectedState(state);
    final districts = (state['cities'] as List).map((d) => {'id': d['id'], 'name': d['name']}).toList();
    ref.read(donorFormProvider.notifier).updateDistricts(districts);

    if (savedDistrict.isEmpty) return;
    final district = districts.firstWhere((d) => d['name'] == savedDistrict, orElse: () => {});
    if (district.isNotEmpty) {
      ref.read(donorFormProvider.notifier).updateSelectedDistrict(district);
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
        _nameController.text = user['name'] ?? '';

        _phoneController.text =
            user['mobileNumber']?.toString() ??
            user['phone']?.toString() ??
            '';

        // backend address undenkil
        if (user['address'] != null) {
          final address = user['address'];

          _placeController.text =
              address['place']?.toString() ?? '';

          _pincodeController.text =
              address['pincode']?.toString() ?? '';

          _countryController.text =
              address['country']?.toString() ?? '';

          _stateController.text =
              address['state']?.toString() ?? '';

          _districtController.text =
              address['district']?.toString() ?? '';
        }
      });
    }
  } catch (e) {
    print("LOAD USER ERROR => $e");
  }
}

  Future<void> _selectDate(BuildContext context) async {
    final dateOfBirth = ref.read(donorFormProvider).dateOfBirth;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateOfBirth != null
          ? DateFormat('yyyy-MM-dd').parse(dateOfBirth)
          : DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
      ref.read(donorFormProvider.notifier).updateDateOfBirth(formattedDate);
      _dobController.text = formattedDate;
    }
  }

  Future<void> _openSearchModal({
    required String title,
    required List<Map<String, dynamic>> data,
    required Function(Map<String, dynamic>) onSelected,
  }) async {
    String searchQuery = "";
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
                  width: screenWidth * 0.9,
                  height: screenHeight * 0.6,
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: screenWidth * 0.06),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, size: screenWidth * 0.06),
                          hintText: "Search...",
                          hintStyle: TextStyle(fontSize: screenWidth * 0.035),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.025),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.0125,
                          ),
                        ),
                        onChanged: (val) {
                          setModalState(() => searchQuery = val);
                        },
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  "No results found",
                                  style: TextStyle(fontSize: screenWidth * 0.04),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return ListTile(
                                    title: Text(
                                      item['name'].toString(),
                                      style: TextStyle(fontSize: screenWidth * 0.04),
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
    ref.read(donorFormProvider.notifier).updateSelectedCountry(country);
    _countryController.text = country['name'].toString();
    _stateController.clear();
    _districtController.clear();
  }

  void _onStateSelected(Map<String, dynamic> state) {
    ref.read(donorFormProvider.notifier).updateSelectedState(state);
    _stateController.text = state['name'].toString();
    _districtController.clear();
  }

  void _onDistrictSelected(Map<String, dynamic> district) {
    ref.read(donorFormProvider.notifier).updateSelectedDistrict(district);
    _districtController.text = district['name'].toString();
  }


Future<void> _submit() async {
  final formState = ref.read(donorFormProvider);

  final name = _nameController.text.trim();
  final phone = _phoneController.text.trim();
  final place = _placeController.text.trim();
  final pincode = _pincodeController.text.trim();

  final isEdit = widget.editData != null;

  // ----------------------------
  // ✅ BASIC VALIDATION (always)
  // ----------------------------
  if (name.isEmpty || phone.isEmpty || place.isEmpty || pincode.isEmpty) {
    showTopSnackBar(context, "Please fill all required fields", isError: true);
    return;
  }

  // Phone validation (optional safety)
  if (phone.length != 10) {
    showTopSnackBar(context, "Enter valid 10 digit phone number", isError: true);
    return;
  }

  // ----------------------------
  // ✅ CREATE MODE VALIDATION ONLY
  // ----------------------------
  if (!isEdit) {
    if (formState.dateOfBirth == null ||
        formState.bloodGroup == null ||
        formState.selectedCountry == null ) {
      showTopSnackBar(context, "Please fill all required fields", isError: true);
      return;
    }
 if (formState.states.isNotEmpty &&
      formState.selectedState == null) {
    showTopSnackBar(context, "Please select state", isError: true);
    return;
  }
    if (formState.districts.isNotEmpty &&
        formState.selectedDistrict == null) {
      showTopSnackBar(context, "Please select district", isError: true);
      return;
    }
  }

  // ----------------------------
  // ✅ USER CHECK
  // ----------------------------
  final userId = await ref.read(userIdProvider.future);
  if (userId == null) {
    showTopSnackBar(context, "User not logged in", isError: true);
    return;
  }

  // ----------------------------
  // ✅ DISTRICT HANDLING (IMPORTANT FIX)
  // ----------------------------
  final districtValue = formState.districts.isEmpty
      ? null
      : (formState.selectedDistrict?['name'] ??
          (_districtController.text.trim().isNotEmpty
              ? _districtController.text.trim()
              : null));

  // ----------------------------
  // ✅ PAYLOAD
  // ----------------------------
  final parsedPin = int.tryParse(pincode);
if (parsedPin == null) {
  showTopSnackBar(context, "Invalid pincode", isError: true);
  return;
}

final country = _countryController.text.trim();
final state = _stateController.text.trim();
final district = _districtController.text.trim();

if (country.isEmpty) {
  showTopSnackBar(context, "Country is required", isError: true);
  return;
}

final address = {
  "place": place,
  "country": country,
  "pincode": parsedPin,
};

if (state.isNotEmpty) {
  address["state"] = state;
}

if (district.isNotEmpty) {
  address["district"] = district;
}

final payload = {
  "name": name,
  "phone": phone,
  "dateOfBirth": formState.dateOfBirth,
  "bloodGroup": formState.bloodGroup,
  "address": address,
  "userId": userId,
};
  // final payload = {
  //   "name": name,
  //   "phone": phone,
  //   "dateOfBirth": formState.dateOfBirth,
  //   "bloodGroup": formState.bloodGroup,
  //   "address": {
  //     "country":
  //         formState.selectedCountry?['name'] ?? _countryController.text,
  //     "state": formState.selectedState?['name'] ?? _stateController.text,
  //     "district": districtValue,
  //     "place": place,
  //     "pincode": int.tryParse(pincode),
  //   },
  //   "userId": userId,
  // };

  log("📦 Payload: $payload");

  // ----------------------------
  // ✅ LOADING START
  // ----------------------------
  ref.read(donorFormProvider.notifier).setLoading(true);

  try {
    bool success;

    // ----------------------------
    // CREATE
    // ----------------------------
    if (!isEdit) {
      success =
          await ref.read(donorCreationProvider(payload).future);
    }

    // ----------------------------
    // UPDATE
    // ----------------------------
    else {
      final donorId = widget.editData!['id']?.toString();

      if (donorId == null) {
        showTopSnackBar(context, "Donor ID missing", isError: true);
        return;
      }

      success = await ref
          .read(bloodProvider.notifier)
          .updateDonor(donorId, payload);
    }

    // ----------------------------
    // SUCCESS
    // ----------------------------
    if (success) {
        final prefs = await SharedPreferences.getInstance();
  await prefs.setString('donorId', "true"); // or actual id
      showTopSnackBar(
        context,
        isEdit
            ? "Donor Updated Successfully"
            : "Donor Registered Successfully",
      );

      final uid = userId.toString();
      await ref.read(bloodProvider.notifier).fetchDonor(uid);

      Navigator.pop(context, true);
    }

    // ----------------------------
    // FAIL
    // ----------------------------
    else {
      showTopSnackBar(context, "Something went wrong", isError: true);
    }
  } catch (e) {
   // showTopSnackBar(context, e.toString(), isError: true);
  } finally {
    ref.read(donorFormProvider.notifier).setLoading(false);
  }
}

  @override
  Widget build(BuildContext context) {
    // same as your existing build method (unchanged)
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final locationAsync = ref.watch(locationDataProvider);
    final formState = ref.watch(donorFormProvider);
    final isLoading = formState.isLoading;
    final bloodGroup = formState.bloodGroup;
    final countries = locationAsync.value ?? [];
    final states = formState.states;
    final districts = formState.districts;

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        title: Text(
          widget.editData == null ? "Register Blood Donor" : "Edit Blood Donor",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: screenWidth * 0.05,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: screenWidth * 0.055),
          onPressed: () => Navigator.pop(context),
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
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.025),
                        ),
                        labelText: "Full Name",
                        labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                        prefixIcon: Icon(Icons.person, size: screenWidth * 0.055),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.015,
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? "Name is required" : null,
                    ),
                    SizedBox(height: screenHeight * 0.015),

                    // Phone field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return "Phone number is required";
                        if (value.trim().length != 10) return "Phone number must be 10 digits";
                        return null;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.025),
                        ),
                        labelText: "Phone",
                        labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                        prefixIcon: Icon(Icons.phone, size: screenWidth * 0.055),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.015,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),

                    // DOB
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _dobController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.025),
                            ),
                            labelText: "Date of Birth",
                            labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                            prefixIcon: Icon(Icons.calendar_today, size: screenWidth * 0.055),
                            hintText: "Select DOB",
                            hintStyle: TextStyle(fontSize: screenWidth * 0.035),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03,
                              vertical: screenHeight * 0.015,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),

                    // Blood Group
                    DropdownButtonFormField<String>(
                      value: bloodGroup,
                      items: bloodGroups
                          .map(
                            (bg) => DropdownMenuItem<String>(
                              value: bg,
                              child: Text(bg, style: TextStyle(fontSize: screenWidth * 0.04)),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(donorFormProvider.notifier).updateBloodGroup(val);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: "Blood Group",
                        labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                        prefixIcon: Icon(Icons.bloodtype, size: screenWidth * 0.055),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.025),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.015,
                        ),
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
                    TextField(
                      controller: _placeController,
                      decoration: InputDecoration(
                        labelText: "Place (local)",
                        labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                        prefixIcon: Icon(Icons.location_on, size: screenWidth * 0.055),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.025),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.015,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.015),

                    // Pincode
                    TextField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: "Pincode",
                        labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                        prefixIcon: Icon(Icons.pin_drop, size: screenWidth * 0.055),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.025),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.015,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),

                    // Submit button
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.08,
                          vertical: screenHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.025),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: screenWidth * 0.05,
                              width: screenWidth * 0.05,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: screenWidth * 0.005,
                              ),
                            )
                          : Text(
                              widget.editData == null ? "Create Donor" : "Update Donor",
                              style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.04),
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _placeController.dispose();
    _pincodeController.dispose();
    _dobController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    super.dispose();
  }
}