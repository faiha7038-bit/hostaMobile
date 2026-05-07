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

  List<String> getFilteredCountries() {
    final ambulanceList = ref.read(ambulanceListProvider);
    final countries = <String>[];
    for (final ambulance in ambulanceList) {
      final address = ambulance['address'] ?? {};
      final country = address['country']?.toString().trim() ?? '';
      
      if (country.isNotEmpty && !countries.contains(country)) {
        countries.add(country);
      }
    }
    countries.sort();
    return countries;
  }

  List<String> getFilteredStates(String country) {
    if (country.isEmpty) return [];
    
    final ambulanceList = ref.read(ambulanceListProvider);
    final filteredStates = <String>[];
    for (final ambulance in ambulanceList) {
      final address = ambulance['address'] ?? {};
      final ambulanceCountry = address['country']?.toString().trim() ?? '';
      final state = address['state']?.toString().trim() ?? '';
      
      if (ambulanceCountry == country && 
          state.isNotEmpty && 
          !filteredStates.contains(state)) {
        filteredStates.add(state);
      }
    }
    filteredStates.sort();
    return filteredStates;
  }

  List<String> getFilteredDistricts(String country, String state) {
    if (country.isEmpty || state.isEmpty) return [];
    
    final ambulanceList = ref.read(ambulanceListProvider);
    final filteredDistricts = <String>[];
    for (final ambulance in ambulanceList) {
      final address = ambulance['address'] ?? {};
      final ambulanceCountry = address['country']?.toString().trim() ?? '';
      final ambulanceState = address['state']?.toString().trim() ?? '';
      final district = address['district']?.toString().trim() ?? '';
      
      if (ambulanceCountry == country && 
          ambulanceState == state && 
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
    
    final ambulanceList = ref.read(ambulanceListProvider);
    final filteredPlaces = <String>[];
    for (final ambulance in ambulanceList) {
      final address = ambulance['address'] ?? {};
      final ambulanceCountry = address['country']?.toString().trim() ?? '';
      final ambulanceState = address['state']?.toString().trim() ?? '';
      final ambulanceDistrict = address['district']?.toString().trim() ?? '';
      final place = address['place']?.toString().trim() ?? '';
      
      if (ambulanceCountry == country && 
          ambulanceState == state && 
          ambulanceDistrict == district && 
          place.isNotEmpty && 
          !filteredPlaces.contains(place)) {
        filteredPlaces.add(place);
      }
    }
    filteredPlaces.sort();
    return filteredPlaces;
  }

  void _refreshData() {
    ref.read(isLoadingProvider.notifier).state = true;
    _fetchAmbulances();
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          "Ambulances",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
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
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            ref.read(searchQueryProvider.notifier).state = value;
                          },
                          decoration: InputDecoration(
                            hintText: "Search ambulance service...",
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
                      if(ambulanceId == null)...{
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _handleAmbulanceRegister,
                          child: const Text("Register", style: TextStyle(color: Colors.white)),
                        ),
                      }else...{
                        const SizedBox.shrink()
                      }
                    ],
                  ),
                ),
                _buildLocationAndClearButton(context),
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                ambulanceList.isEmpty ? Icons.error_outline : Icons.search_off,
                                size: 60,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                ambulanceList.isEmpty 
                                  ? "No ambulances available" 
                                  : "No ambulances found",
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ambulanceList.isEmpty 
                                  ? "Check your connection or try again later"
                                  : "Try adjusting your filters",
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              if (ambulanceList.isEmpty) ...[
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _refreshData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
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
                        )
                      : ListView.builder(
                          itemCount: filteredList.length,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemBuilder: (context, index) {
                            final amb = filteredList[index];
                            final address = amb['address'] ?? {};

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: const Icon(
                                        Icons.local_hospital,
                                        color: Colors.green,
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            amb["serviceName"] ?? "Unknown",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${address["place"] ?? ""}",
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "${address["district"] ?? ""}, ${address["state"] ?? ""}, ${address["country"] ?? ""}",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black45),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${amb["vehicleType"] ?? "N/A"}",
                                            style: const TextStyle(
                                                fontSize: 13,
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
                                          icon: const Icon(
                                            Icons.call,
                                            color: Colors.green,
                                            size: 28,
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
                                            icon: const Icon(
                                              Icons.location_on,
                                              color: Colors.red,
                                              size: 28,
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
                    ref.watch(selectedCountryProvider).isEmpty
                        ? "Select Location"
                        : "${ref.watch(selectedCountryProvider)} > ${ref.watch(selectedStateProvider)} > ${ref.watch(selectedDistrictProvider)} > ${ref.watch(selectedPlaceProvider)}",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
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
              icon: const Icon(Icons.clear, color: Colors.red),
              label: const Text("Clear", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

  void _openLocationFilter(BuildContext context) {
    String tempCountry = ref.read(selectedCountryProvider);
    String tempState = ref.read(selectedStateProvider);
    String tempDistrict = ref.read(selectedDistrictProvider);
    String tempPlace = ref.read(selectedPlaceProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          final countries = getFilteredCountries();
          final filteredStates = getFilteredStates(tempCountry);
          final filteredDistricts = getFilteredDistricts(tempCountry, tempState);
          final filteredPlaces = getFilteredPlaces(tempCountry, tempState, tempDistrict);

          return Padding(
            padding: const EdgeInsets.all(16),
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
                  if (tempCountry.isNotEmpty && tempState.isNotEmpty && tempDistrict.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
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