import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/providers/blood-donateprovider.dart';
import 'package:intl/intl.dart';
import 'package:hosta/common/top_snackbar.dart';

class Donate extends ConsumerStatefulWidget {
  const Donate({super.key});

  @override
  ConsumerState<Donate> createState() => _DonateState();
}

class _DonateState extends ConsumerState<Donate> {
  final _phoneController = TextEditingController();
  final _placeController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _dobController = TextEditingController();
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();

  final List<String> bloodGroups = [
    "A+",
    "A-",
    "B+",
    "B-",
    "O+",
    "O-",
    "AB+",
    "AB-",
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  Future<void> _loadUserPhone() async {
    final phoneAsync = await ref.read(userPhoneProvider.future);
    if (phoneAsync != null) {
      _phoneController.text = phoneAsync;
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
    final phone = _phoneController.text;
    final place = _placeController.text;
    final pincode = _pincodeController.text;

    if (phone.isEmpty ||
        formState.dateOfBirth == null ||
        formState.bloodGroup == null ||
        formState.selectedCountry == null ||
        place.isEmpty ||
        pincode.isEmpty) {
      showTopSnackBar(
        context,
        "Please fill all required fields",
        isError: true,
      );
      return;
    }

    final userId = await ref.read(userIdProvider.future);
    if (userId == null) {
      showTopSnackBar(context, "User not logged in", isError: true);
      return;
    }

    final payload = {
      "phone": phone,
      "dateOfBirth": formState.dateOfBirth,
      "bloodGroup": formState.bloodGroup,
      "address": {
        "country": formState.selectedCountry!['name'].toString(),
        "state": formState.selectedState!['name'].toString(),
        "district": formState.selectedDistrict!['name'].toString(),
        "place": place,
        "pincode": pincode,
      },
      "userId": userId,
    };

    ref.read(donorFormProvider.notifier).setLoading(true);
    
    final result = await ref.read(donorCreationProvider(payload).future);
    
    ref.read(donorFormProvider.notifier).setLoading(false);
    
    if (result) {
      showTopSnackBar(context, "Donor Created Successfully");
      Navigator.pop(context);
    } else {
      final error = ref.read(donorFormProvider).error;
      showTopSnackBar(
        context,
        error ?? 'Donate failed',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          "Register Blood Donor",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
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
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelText: "Phone",
                      prefixIcon: const Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _dobController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                        .map(
                          (bg) => DropdownMenuItem<String>(
                            value: bg,
                            child: Text(bg),
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
                      prefixIcon: Icon(Icons.bloodtype),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  if (locationAsync.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (locationAsync.hasError)
                    const Center(child: Text("Error loading countries"))
                  else
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
                            hintText: "Select Country",
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
                            hintText: "Select State",
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
                            hintText: "Select District",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _placeController,
                    decoration: InputDecoration(
                      labelText: "Place (local)",
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: "Pincode",
                      prefixIcon: Icon(Icons.pin_drop),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Create Donor",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
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