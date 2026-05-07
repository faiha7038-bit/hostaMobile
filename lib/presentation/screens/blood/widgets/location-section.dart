import 'package:flutter/material.dart';

class LocationSection extends StatelessWidget {
  final String selectedCountry;
  final String selectedState;
  final String selectedDistrict;
  final String selectedPlace;
  final List<String> countries;
  final List<String> states;
  final List<String> districts;
  final List<String> places;
  final List<dynamic> donors;
  final Function(String, String, String, String) onLocationSelected;
  final VoidCallback onClear;

  const LocationSection({
    super.key,
    required this.selectedCountry,
    required this.selectedState,
    required this.selectedDistrict,
    required this.selectedPlace,
    required this.countries,
    required this.states,
    required this.districts,
    required this.places,
    required this.donors,
    required this.onLocationSelected,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            onPressed: onClear,
            icon: const Icon(Icons.clear, color: Colors.red),
            label: const Text("Clear", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Get filtered locations based on current TEMPORARY selections
            List<String> filteredStates = _getFilteredStates(tempCountry);
            List<String> filteredDistricts = _getFilteredDistricts(tempCountry, tempState);
            List<String> filteredPlaces = _getFilteredPlaces(tempCountry, tempState, tempDistrict);

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
                    
                    // Country Dropdown
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
                    
                    // State Dropdown
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
                    
                    // District Dropdown
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
                    
                    // Place Dropdown
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
                        onLocationSelected(tempCountry, tempState, tempDistrict, tempPlace);
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
          },
        );
      },
    );
  }

  List<String> _getFilteredStates(String country) {
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

  List<String> _getFilteredDistricts(String country, String state) {
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

  List<String> _getFilteredPlaces(String country, String state, String district) {
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
}