import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/presentation/screens/ambulance/register.dart';
import 'package:hosta/providers/ambulance-provider.dart';
import 'package:url_launcher/url_launcher.dart';

class Ambulance extends ConsumerStatefulWidget {
  const Ambulance({super.key});

  @override
  ConsumerState<Ambulance> createState() => _AmbulanceState();
}

class _AmbulanceState extends ConsumerState<Ambulance> {
@override
@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;

    ref.read(isLoadingProvider.notifier).state = true;
    _fetchAmbulances();   
  });
}

  Future<void> _fetchAmbulances() async {
    try {
      await ref.read(ambulanceListProvider.notifier).fetchAmbulances();
      ref.read(isLoadingProvider.notifier).state = false;
    } catch (e) {
      ref.read(isLoadingProvider.notifier).state = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _handleAmbulanceRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AmbulanceRegister(),
      ),
    ).then((_) {
      _fetchAmbulances();
    });
  }

  Future<void> _callNumber(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch dialer')),
      );
    }
  }

  Future<void> _openMap(double lat, double lon) async {
    final Uri uri =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open map')),
      );
    }
  }
  String _normalize(String? value) {
  if (value == null || value.trim().isEmpty) return '';
  final trimmed = value.trim();
  return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
}

List<String> getFilteredCountries() {
  final ambulanceList = ref.read(ambulanceListProvider);
  final countries = <String>{};
  for (final ambulance in ambulanceList) {
    final address = ambulance['address'] ?? {};
    final rawCountry = address['country']?.toString().trim() ?? '';
    final country = _normalize(rawCountry);
    if (country.isNotEmpty) countries.add(country);
  }
  return countries.toList()..sort();
}

List<String> getFilteredStates(String country) {
  if (country.isEmpty) return [];
  final normalizedCountry = _normalize(country);
  final ambulanceList = ref.read(ambulanceListProvider);
  final filteredStates = <String>{};
  for (final ambulance in ambulanceList) {
    final address = ambulance['address'] ?? {};
    final rawCountry = address['country']?.toString().trim() ?? '';
    final ambulanceCountry = _normalize(rawCountry);
    final rawState = address['state']?.toString().trim() ?? '';
    final state = _normalize(rawState);
    if (ambulanceCountry == normalizedCountry && state.isNotEmpty) {
      filteredStates.add(state);
    }
  }
  return filteredStates.toList()..sort();
}

List<String> getFilteredDistricts(String country, String state) {
  if (country.isEmpty || state.isEmpty) return [];
  final normalizedCountry = _normalize(country);
  final normalizedState = _normalize(state);
  final ambulanceList = ref.read(ambulanceListProvider);
  final filteredDistricts = <String>{};
  for (final ambulance in ambulanceList) {
    final address = ambulance['address'] ?? {};
    final rawCountry = address['country']?.toString().trim() ?? '';
    final ambulanceCountry = _normalize(rawCountry);
    final rawState = address['state']?.toString().trim() ?? '';
    final ambulanceState = _normalize(rawState);
    final rawDistrict = address['district']?.toString().trim() ?? '';
    final district = _normalize(rawDistrict);
    if (ambulanceCountry == normalizedCountry &&
        ambulanceState == normalizedState &&
        district.isNotEmpty) {
      filteredDistricts.add(district);
    }
  }
  return filteredDistricts.toList()..sort();
}

List<String> getFilteredPlaces(String country, String state, String district) {
  if (country.isEmpty || state.isEmpty || district.isEmpty) return [];
  final normalizedCountry = _normalize(country);
  final normalizedState = _normalize(state);
  final normalizedDistrict = _normalize(district);
  final ambulanceList = ref.read(ambulanceListProvider);
  final filteredPlaces = <String>{};
  for (final ambulance in ambulanceList) {
    final address = ambulance['address'] ?? {};
    final rawCountry = address['country']?.toString().trim() ?? '';
    final ambulanceCountry = _normalize(rawCountry);
    final rawState = address['state']?.toString().trim() ?? '';
    final ambulanceState = _normalize(rawState);
    final rawDistrict = address['district']?.toString().trim() ?? '';
    final ambulanceDistrict = _normalize(rawDistrict);
    final rawPlace = address['place']?.toString().trim() ?? '';
    final place = _normalize(rawPlace);
    if (ambulanceCountry == normalizedCountry &&
        ambulanceState == normalizedState &&
        ambulanceDistrict == normalizedDistrict &&
        place.isNotEmpty) {
      filteredPlaces.add(place);
    }
  }
  return filteredPlaces.toList()..sort();
}

  void _refreshData() {
    ref.read(isLoadingProvider.notifier).state = true;
    _fetchAmbulances();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLoading = ref.watch(isLoadingProvider);
    final filteredList = ref.watch(filteredAmbulanceListProvider);
    final ambulanceList = ref.watch(ambulanceListProvider);
    final ambulanceId = ref.watch(ambulanceIdProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCountry = ref.watch(selectedCountryProvider);
    final selectedState = ref.watch(selectedStateProvider);
    final selectedDistrict = ref.watch(selectedDistrictProvider);
    final selectedPlace = ref.watch(selectedPlaceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        title: Text(
          "Ambulances",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: screenWidth * 0.05,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
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
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.green,
                strokeWidth: screenWidth * 0.008,
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.0125,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            ref.read(searchQueryProvider.notifier).state = value;
                          },
                          decoration: InputDecoration(
                            hintText: "Search ambulance service...",
                            hintStyle: TextStyle(fontSize: screenWidth * 0.035),
                            prefixIcon: Icon(Icons.search, color: Colors.grey, size: screenWidth * 0.06),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.03),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.0125),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      if(ambulanceId == null)...{
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.015,
                            ),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(screenWidth * 0.025)),
                          ),
                          onPressed: _handleAmbulanceRegister,
                          child: Text(
                            "Register",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                        ),
                      }else...{
                        const SizedBox.shrink()
                      }
                    ],
                  ),
                ),
                _buildLocationAndClearButton(context, screenWidth, screenHeight),
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                ambulanceList.isEmpty ? Icons.error_outline : Icons.search_off,
                                size: screenWidth * 0.15,
                                color: Colors.grey,
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Text(
                                ambulanceList.isEmpty 
                                  ? "No ambulances available" 
                                  : "No ambulances found",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                ambulanceList.isEmpty 
                                  ? "Check your connection or try again later"
                                  : "Try adjusting your filters",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (ambulanceList.isEmpty) ...[
                                SizedBox(height: screenHeight * 0.025),
                                ElevatedButton(
                                  onPressed: _refreshData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.06,
                                      vertical: screenHeight * 0.015,
                                    ),
                                  ),
                                  child: Text(
                                    "Try Again",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.035,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredList.length,
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                          itemBuilder: (context, index) {
                            final amb = filteredList[index];
                            final address = amb['address'] ?? {};

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(screenWidth * 0.03)),
                              elevation: screenWidth * 0.0075,
                              child: Padding(
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(screenWidth * 0.03),
                                      child: Icon(
                                        Icons.local_hospital,
                                        color: Colors.green,
                                        size: screenWidth * 0.075,
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            amb["serviceName"] ?? "Unknown",
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.04,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: screenHeight * 0.005),
                                          Text(
                                            "${address["place"] ?? ""}",
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: screenWidth * 0.0325),
                                          ),
                                          SizedBox(height: screenHeight * 0.0025),
                                          Text(
                                            "${address["district"] ?? ""}, ${address["state"] ?? ""}, ${address["country"] ?? ""}",
                                            style: TextStyle(
                                                fontSize: screenWidth * 0.03,
                                                color: Colors.black45),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: screenHeight * 0.005),
                                          Text(
                                            "${amb["vehicleType"] ?? "N/A"}",
                                            style: TextStyle(
                                                fontSize: screenWidth * 0.0325,
                                                color: Colors.black87),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            _callNumber(amb["phone"] ?? "");
                                          },
                                          icon: Icon(
                                            Icons.call,
                                            color: Colors.green,
                                            size: screenWidth * 0.07,
                                          ),
                                        ),
                                        if (amb["latitude"] != null && amb["longitude"] != null)
                                          IconButton(
                                            onPressed: () {
                                              double lat = double.tryParse(
                                                      amb["latitude"]
                                                          .toString()) ??
                                                  0;
                                              double lon = double.tryParse(
                                                      amb["longitude"]
                                                          .toString()) ??
                                                  0;
                                              _openMap(lat, lon);
                                            },
                                            icon: Icon(
                                              Icons.location_on,
                                              color: Colors.red,
                                              size: screenWidth * 0.07,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLocationAndClearButton(BuildContext context, double screenWidth, double screenHeight) => Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.005),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _openLocationFilter(context, screenWidth, screenHeight),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenHeight * 0.0125),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300, width: screenWidth * 0.0025),
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                  child: Text(
                    ref.watch(selectedCountryProvider).isEmpty
                        ? "Select Location"
                        : "${ref.watch(selectedCountryProvider)} > ${ref.watch(selectedStateProvider)} > ${ref.watch(selectedDistrictProvider)} > ${ref.watch(selectedPlaceProvider)}",
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                ref.read(selectedCountryProvider.notifier).state = '';
                ref.read(selectedStateProvider.notifier).state = '';
                ref.read(selectedDistrictProvider.notifier).state = '';
                ref.read(selectedPlaceProvider.notifier).state = '';
                ref.read(searchQueryProvider.notifier).state = '';
              },
              icon: Icon(Icons.clear, color: Colors.red, size: screenWidth * 0.05),
              label: Text(
                "Clear",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: screenWidth * 0.035,
                ),
              ),
            ),
          ],
        ),
      );

  void _openLocationFilter(BuildContext context, double screenWidth, double screenHeight) {
    String tempCountry = ref.read(selectedCountryProvider);
    String tempState = ref.read(selectedStateProvider);
    String tempDistrict = ref.read(selectedDistrictProvider);
    String tempPlace = ref.read(selectedPlaceProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(screenWidth * 0.05)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          final countries = getFilteredCountries();
          final filteredStates = getFilteredStates(tempCountry);
          final filteredDistricts = getFilteredDistricts(tempCountry, tempState);
          final filteredPlaces = getFilteredPlaces(tempCountry, tempState, tempDistrict);

          return Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      "Select Location",
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Divider(thickness: screenWidth * 0.0025),
                  DropdownButtonFormField<String>(
                    value: tempCountry.isEmpty ? null : tempCountry,
                    decoration: InputDecoration(
                      labelText: "Country *",
                      labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.025),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.0125,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: '',
                        child: Text(
                          "Select Country",
                          style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.035),
                        ),
                      ),
                      ...countries.map((country) {
                        return DropdownMenuItem(
                          value: country,
                          child: Text(country, style: TextStyle(fontSize: screenWidth * 0.035)),
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
                  SizedBox(height: screenHeight * 0.02),
                  if (tempCountry.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: tempState.isEmpty ? null : tempState,
                      decoration: InputDecoration(
                        labelText: "State *",
                        labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.025),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.0125,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(
                            "Select State",
                            style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.035),
                          ),
                        ),
                        ...filteredStates.map((state) {
                          return DropdownMenuItem(
                            value: state,
                            child: Text(state, style: TextStyle(fontSize: screenWidth * 0.035)),
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
                    SizedBox(height: screenHeight * 0.02),
                  ],
                  if (tempCountry.isNotEmpty && tempState.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: tempDistrict.isEmpty ? null : tempDistrict,
                      decoration: InputDecoration(
                        labelText: "District *",
                        labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.025),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.0125,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(
                            "Select District",
                            style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.035),
                          ),
                        ),
                        ...filteredDistricts.map((district) {
                          return DropdownMenuItem(
                            value: district,
                            child: Text(district, style: TextStyle(fontSize: screenWidth * 0.035)),
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
                    SizedBox(height: screenHeight * 0.02),
                  ],
                  if (tempCountry.isNotEmpty && tempState.isNotEmpty && tempDistrict.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: tempPlace.isEmpty ? null : tempPlace,
                      decoration: InputDecoration(
                        labelText: "Place",
                        labelStyle: TextStyle(fontSize: screenWidth * 0.035),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.025),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.0125,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(
                            "Select Place",
                            style: TextStyle(color: Colors.grey, fontSize: screenWidth * 0.035),
                          ),
                        ),
                        ...filteredPlaces.map((place) {
                          return DropdownMenuItem(
                            value: place,
                            child: Text(place, style: TextStyle(fontSize: screenWidth * 0.035)),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempPlace = value ?? '';
                        });
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                  SizedBox(height: screenHeight * 0.03),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(selectedCountryProvider.notifier).state = tempCountry;
                      ref.read(selectedStateProvider.notifier).state = tempState;
                      ref.read(selectedDistrictProvider.notifier).state = tempDistrict;
                      ref.read(selectedPlaceProvider.notifier).state = tempPlace;
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                    ),
                    child: Text(
                      "Apply Filter",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}