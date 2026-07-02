import 'dart:async';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/presentation/screens/ambulance/register.dart';
import 'package:hosta/presentation/screens/auth/signin.dart';
import 'package:hosta/providers/ambulance-provider.dart';
import 'package:hosta/services/socket-service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class Ambulance extends ConsumerStatefulWidget {
  const Ambulance({super.key});

  @override
  ConsumerState<Ambulance> createState() => _AmbulanceState();
}


class _AmbulanceState extends ConsumerState<Ambulance> {
  Timer? _debounce;
final TextEditingController _searchController = TextEditingController();
StreamSubscription? _connectivitySubscription;
String? userId;
late Function(dynamic) _onAmbulanceEvent;
List<dynamic> _filterOfflineData(
  List<dynamic> list,
  
) {
  final query = ref
      .read(searchQueryProvider)
      .toLowerCase();

  final country =
      ref.read(selectedCountryProvider);

  final state =
      ref.read(selectedStateProvider);

  final district =
      ref.read(selectedDistrictProvider);

  final place =
      ref.read(selectedPlaceProvider);

  return list.where((amb) {

    final address =
        amb['address'] ?? {};

    final serviceName =
        (amb['serviceName'] ?? '')
            .toString()
            .toLowerCase();

    final vehicleType =
        (amb['vehicleType'] ?? '')
            .toString()
            .toLowerCase();

    final ambCountry =
        (address['country'] ?? '')
            .toString()
            .toLowerCase();

    final ambState =
        (address['state'] ?? '')
            .toString()
            .toLowerCase();

    final ambDistrict =
        (address['district'] ?? '')
            .toString()
            .toLowerCase();

    final ambPlace =
        (address['place'] ?? '')
            .toString()
            .toLowerCase();

    final matchesSearch =
        query.isEmpty ||
        serviceName.contains(query) ||
        vehicleType.contains(query);

    final matchesCountry =
        country.isEmpty ||
        ambCountry ==
            country.toLowerCase();

    final matchesState =
        state.isEmpty ||
        ambState ==
            state.toLowerCase();

    final matchesDistrict =
        district.isEmpty ||
        ambDistrict ==
            district.toLowerCase();

    final matchesPlace =
        place.isEmpty ||
        ambPlace ==
            place.toLowerCase();

    return matchesSearch &&
        matchesCountry &&
        matchesState &&
        matchesDistrict &&
        matchesPlace;

  }).toList();
}
  @override
void dispose() {
  _debounce?.cancel();
  _searchController.dispose();
  _connectivitySubscription?.cancel();
    SocketService().removeListener("AMBULANCE_REGISTERED", _onAmbulanceEvent);
  SocketService().removeListener("AMBULANCE_UPDATED", _onAmbulanceEvent);
  SocketService().removeListener("AMBULANCE_DELETED", _onAmbulanceEvent);
  super.dispose();
}
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
       await _checkInternet();
      _fetchAmbulances();
       _refreshAmbulanceId();
       _loadUser();
       _setupSocketListener();
     

     _connectivitySubscription =
    Connectivity().onConnectivityChanged.listen((results) {

  final hasInternet =
      !results.contains(ConnectivityResult.none);

  ref.read(isOfflineProvider.notifier).state =
      !hasInternet;

  log("Offline Status: ${!hasInternet}");
});

});
  
  }
  void _setupSocketListener() {
  _onAmbulanceEvent = (_) async {
    if (!mounted) return;

    log("🚑 Ambulance Changed - Refetching");

    ref.invalidate(ambulanceListProvider);
    ref.invalidate(allAmbulancesProvider);

    await _fetchAmbulances(showLoader: false);
    await _refreshAmbulanceId();
  };

  SocketService().addListener(
    [
      'AMBULANCE_REGISTERED',
      'AMBULANCE_UPDATED',
      'AMBULANCE_DELETED',
    ],
    _onAmbulanceEvent,
  );
}
  Future<void> _loadUser() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    userId = prefs.getString('userId');
  });
  }
Future<void> _checkInternet() async {
  final results = await Connectivity().checkConnectivity();

  final hasInternet =
      !results.contains(ConnectivityResult.none);

  ref.read(isOfflineProvider.notifier).state =
      !hasInternet;

  log("Initial Offline Status: ${!hasInternet}");
}
// Inside _AmbulanceState

Future<void> _fetchAmbulances({bool showLoader = true}) async {
  try {
    if (showLoader) ref.read(isLoadingProvider.notifier).state = true;
    await ref.read(ambulanceListProvider.notifier).fetchAmbulances();
    await _refreshAmbulanceId();   // <-- Add this line
  } catch (e) {
    // ...
  } finally {
    if (showLoader) ref.read(isLoadingProvider.notifier).state = false;
  }
}

Future<void> _refreshAmbulanceId() async {
  
  final prefs = await SharedPreferences.getInstance();

  String? ambulanceId =
      prefs.getString('ambulanceId');
log("userId => $userId");
log("ambulanceId => $ambulanceId");
  bool hasRegistered =
      prefs.getBool('ambulanceRegistered') ?? false;

  log("ambulanceId => $ambulanceId");
  log("ambulanceRegistered => $hasRegistered");

ref.read(ambulanceIdProvider.notifier).state =
    prefs.getString('ambulanceId');

  ref.read(ambulanceIdProvider.notifier).state =
      ambulanceId ?? '';

  log("provider value => $ambulanceId");
}


  Future<void> _callNumber(String phone) async {
  if (phone.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid phone number')),
    );
    return;
  }

  var status = await Permission.phone.request();

  if (status.isGranted) {
    bool? res = await FlutterPhoneDirectCaller.callNumber(phone);

    if (res != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Call failed')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone permission denied')),
    );
  }
}

  Future<void> _openMap(double lat, double lon) async {
    final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open map')),
      );
    }
  }

  void _refreshData() {
   
    _fetchAmbulances();
   //  _refreshAmbulanceId();
    
  }

  String _normalize(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final trimmed = value.trim();
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }

  // Extract distinct countries from current ambulance list
  List<String> getFilteredCountries() {
   // final ambulanceList = ref.read(ambulanceListProvider);
final isOffline =
    ref.watch(isOfflineProvider);

final ambulanceList = isOffline
    ? _filterOfflineData(
        ref.watch(allAmbulancesProvider),
      )
    : ref.watch(ambulanceListProvider);
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
   final isOffline = ref.read(isOfflineProvider);

final ambulanceList = isOffline
    ? ref.read(allAmbulancesProvider)
    : ref.read(ambulanceListProvider);
    final states = <String>{};
    for (final ambulance in ambulanceList) {
      final address = ambulance['address'] ?? {};
      final rawCountry = address['country']?.toString().trim() ?? '';
      final ambulanceCountry = _normalize(rawCountry);
      if (ambulanceCountry == normalizedCountry) {
        final rawState = address['state']?.toString().trim() ?? '';
        final state = _normalize(rawState);
        if (state.isNotEmpty) states.add(state);
      }
    }
    return states.toList()..sort();
  }

  List<String> getFilteredDistricts(String country, String state) {
    if (country.isEmpty || state.isEmpty) return [];
    final normalizedCountry = _normalize(country);
    final normalizedState = _normalize(state);
    final isOffline = ref.read(isOfflineProvider);

final ambulanceList = isOffline
    ? ref.read(allAmbulancesProvider)
    : ref.read(ambulanceListProvider);
    final districts = <String>{};
    for (final ambulance in ambulanceList) {
      final address = ambulance['address'] ?? {};
      final rawCountry = address['country']?.toString().trim() ?? '';
      final ambulanceCountry = _normalize(rawCountry);
      final rawState = address['state']?.toString().trim() ?? '';
      final ambulanceState = _normalize(rawState);
      if (ambulanceCountry == normalizedCountry && ambulanceState == normalizedState) {
        final rawDistrict = address['district']?.toString().trim() ?? '';
        final district = _normalize(rawDistrict);
        if (district.isNotEmpty) districts.add(district);
      }
    }
    return districts.toList()..sort();
  }

  List<String> getFilteredPlaces(String country, String state, String district) {
    if (country.isEmpty || state.isEmpty || district.isEmpty) return [];
    final normalizedCountry = _normalize(country);
    final normalizedState = _normalize(state);
    final normalizedDistrict = _normalize(district);
  final isOffline = ref.read(isOfflineProvider);

final ambulanceList = isOffline
    ? ref.read(allAmbulancesProvider)
    : ref.read(ambulanceListProvider);
    final places = <String>{};
    for (final ambulance in ambulanceList) {
      final address = ambulance['address'] ?? {};
      final rawCountry = address['country']?.toString().trim() ?? '';
      final ambulanceCountry = _normalize(rawCountry);
      final rawState = address['state']?.toString().trim() ?? '';
      final ambulanceState = _normalize(rawState);
      final rawDistrict = address['district']?.toString().trim() ?? '';
      final ambulanceDistrict = _normalize(rawDistrict);
      if (ambulanceCountry == normalizedCountry &&
          ambulanceState == normalizedState &&
          ambulanceDistrict == normalizedDistrict) {
        final rawPlace = address['place']?.toString().trim() ?? '';
        final place = _normalize(rawPlace);
        if (place.isNotEmpty) places.add(place);
      }
    }
    return places.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLoading = ref.watch(isLoadingProvider);
  final isOffline = ref.watch(isOfflineProvider);

final ambulanceList = isOffline
    ? _filterOfflineData(
        ref.watch(allAmbulancesProvider),
      )
    : ref.watch(ambulanceListProvider); // already filtered by backend
    final ambulanceId = ref.watch(ambulanceIdProvider);
    log("ambulanceId${ambulanceId}");

  log("userId => $userId");
  log("ambulanceId => $ambulanceId");
  log("ambulanceList count => ${ambulanceList.length}");
final hasMyAmbulance = ambulanceList.any(
  (amb) => amb['userId']?.toString() == userId,
);

log("hasMyAmbulance => $hasMyAmbulance");
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
                        child:
                      TextField(
  controller: _searchController,
  onChanged: (value) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
_debounce = Timer(const Duration(milliseconds: 500), () async {

  ref.read(searchQueryProvider.notifier).state =
      value.trim();

  await _fetchAmbulances(showLoader: false);

});
  },
  decoration: InputDecoration(
    hintText: "Search ambulance service...",
    hintStyle: TextStyle(fontSize: screenWidth * 0.035),
    prefixIcon: Icon(
      Icons.search,
      color: Colors.grey,
      size: screenWidth * 0.06,
    ),
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(screenWidth * 0.03),
      borderSide: BorderSide.none,
    ),
    contentPadding: EdgeInsets.symmetric(
      vertical: screenHeight * 0.0125,
    ),
  ),
)
                      ),
                      SizedBox(width: screenWidth * 0.02),
                 if (!isOffline &&
    (userId == null || !hasMyAmbulance))
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.015,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.025),
                            ),
                          ),
                          onPressed: () async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');

  if (userId == null) {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Signin()),
    );
    return;
  }

  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AmbulanceRegister()),
  );
if (result != null && result["refresh"] == true) {
  ref.invalidate(ambulanceListProvider);
  ref.invalidate(allAmbulancesProvider);

  await _fetchAmbulances(showLoader: true);
}
},
                          child: Text("Register", style: TextStyle(color: Colors.white)),
                        ),
                    ],
                  ),
                ),
                _buildLocationAndClearButton(context, screenWidth, screenHeight),
                Expanded(
                  child: ambulanceList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: screenWidth * 0.15,
                                color: Colors.grey,
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Text(
                                "No ambulances found",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              // Text(
                              //   "Try adjusting your filters",
                              //   style: TextStyle(
                              //     fontSize: screenWidth * 0.035,
                              //     color: Colors.grey,
                              //   ),
                              //   textAlign: TextAlign.center,
                              // ),
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
                          ),
                        )
                      : ListView.builder(
                          itemCount: ambulanceList.length,
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                          itemBuilder: (context, index) {
                            final amb = ambulanceList[index];
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
                                                      amb["latitude"].toString()) ?? 0;
                                              double lon = double.tryParse(
                                                      amb["longitude"].toString()) ?? 0;
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

  Widget _buildLocationAndClearButton(BuildContext context, double screenWidth, double screenHeight) {
    return Padding(
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
              _fetchAmbulances();
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
  }

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
                      const DropdownMenuItem(
                        value: '',
                        child: Text("Select Country", style: TextStyle(color: Colors.grey)),
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
                        const DropdownMenuItem(
                          value: '',
                          child: Text("Select State", style: TextStyle(color: Colors.grey)),
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
                        const DropdownMenuItem(
                          value: '',
                          child: Text("Select District", style: TextStyle(color: Colors.grey)),
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
                        const DropdownMenuItem(
                          value: '',
                          child: Text("Select Place", style: TextStyle(color: Colors.grey)),
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
                      _fetchAmbulances();  // apply filters
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