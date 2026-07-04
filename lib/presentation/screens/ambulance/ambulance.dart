import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/common/login_dialoge.dart';
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

  // Helper to clamp responsive values
  double _clamp(double value, double min, double max) =>
      value.clamp(min, max) as double;

  List<dynamic> _filterOfflineData(
    List<dynamic> list,
  ) {
    final query = ref.read(searchQueryProvider).toLowerCase();

    final country = ref.read(selectedCountryProvider);

    final state = ref.read(selectedStateProvider);

    final district = ref.read(selectedDistrictProvider);

    final place = ref.read(selectedPlaceProvider);

    return list.where((amb) {
      final address = amb['address'] ?? {};

      final serviceName = (amb['serviceName'] ?? '').toString().toLowerCase();

      final vehicleType = (amb['vehicleType'] ?? '').toString().toLowerCase();

      final ambCountry = (address['country'] ?? '').toString().toLowerCase();

      final ambState = (address['state'] ?? '').toString().toLowerCase();

      final ambDistrict = (address['district'] ?? '').toString().toLowerCase();

      final ambPlace = (address['place'] ?? '').toString().toLowerCase();

      final matchesSearch = query.isEmpty ||
          serviceName.contains(query) ||
          vehicleType.contains(query);

      final matchesCountry =
          country.isEmpty || ambCountry == country.toLowerCase();

      final matchesState = state.isEmpty || ambState == state.toLowerCase();

      final matchesDistrict =
          district.isEmpty || ambDistrict == district.toLowerCase();

      final matchesPlace = place.isEmpty || ambPlace == place.toLowerCase();

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
        final hasInternet = !results.contains(ConnectivityResult.none);

        ref.read(isOfflineProvider.notifier).state = !hasInternet;
      });
    });
  }

  void _setupSocketListener() {
    _onAmbulanceEvent = (_) async {
      if (!mounted) return;

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

    final hasInternet = !results.contains(ConnectivityResult.none);

    ref.read(isOfflineProvider.notifier).state = !hasInternet;
  }

  Future<void> _fetchAmbulances({bool showLoader = true}) async {
    try {
      if (showLoader) ref.read(isLoadingProvider.notifier).state = true;
      await ref.read(ambulanceListProvider.notifier).fetchAmbulances();
      await _refreshAmbulanceId();
    } catch (e) {
      // ...
    } finally {
      if (showLoader) ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _refreshAmbulanceId() async {
    final prefs = await SharedPreferences.getInstance();

    String? ambulanceId = prefs.getString('ambulanceId');

    bool hasRegistered = prefs.getBool('ambulanceRegistered') ?? false;

    ref.read(ambulanceIdProvider.notifier).state =
        prefs.getString('ambulanceId');

    ref.read(ambulanceIdProvider.notifier).state = ambulanceId ?? '';
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
    final uri =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lon");
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
  }

  String _normalize(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    final trimmed = value.trim();
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }

  List<String> getFilteredCountries() {
    final isOffline = ref.watch(isOfflineProvider);

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
      if (ambulanceCountry == normalizedCountry &&
          ambulanceState == normalizedState) {
        final rawDistrict = address['district']?.toString().trim() ?? '';
        final district = _normalize(rawDistrict);
        if (district.isNotEmpty) districts.add(district);
      }
    }
    return districts.toList()..sort();
  }

  List<String> getFilteredPlaces(
      String country, String state, String district) {
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
        : ref.watch(ambulanceListProvider);
    final ambulanceId = ref.watch(ambulanceIdProvider);

    final hasMyAmbulance = ambulanceList.any(
      (amb) => amb['userId']?.toString() == userId,
    );

    // Responsive values
    final double titleSize = _clamp(screenWidth * 0.05, 16, 24);
    final double iconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double searchHintSize = _clamp(screenWidth * 0.035, 12, 18);
    final double searchPrefixSize = _clamp(screenWidth * 0.06, 20, 32);
    final double searchRadius = _clamp(screenWidth * 0.03, 10, 20);
    final double smallPaddingH = screenWidth * 0.04;
    final double smallPaddingV = screenHeight * 0.0125;
    final double mediumPaddingH = screenWidth * 0.03;
    final double mediumPaddingV = screenHeight * 0.01;
    final double cardRadius = _clamp(screenWidth * 0.03, 8, 18);
    final double elevation = _clamp(screenWidth * 0.0075, 2, 8);
    final double iconSizeBig = _clamp(screenWidth * 0.075, 30, 50);
    final double iconSizeCall = _clamp(screenWidth * 0.07, 28, 44);
    final double fontSizeBody = _clamp(screenWidth * 0.04, 14, 22);
    final double fontSizeSmall = _clamp(screenWidth * 0.0325, 12, 18);
    final double fontSizeExtraSmall = _clamp(screenWidth * 0.03, 11, 16);
    final double buttonPaddingH = screenWidth * 0.04;
    final double buttonPaddingV = screenHeight * 0.015;
    final double clearIconSize = _clamp(screenWidth * 0.05, 20, 30);
    final double modalRadius = _clamp(screenWidth * 0.05, 20, 40);
    final double dropdownRadius = _clamp(screenWidth * 0.025, 8, 16);
    final double dropdownFontSize = _clamp(screenWidth * 0.035, 13, 18);
    final double modalTitleSize = _clamp(screenWidth * 0.045, 18, 28);
    final double dividerThickness = _clamp(screenWidth * 0.0025, 0.5, 2);

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        title: Text(
          "Ambulances",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: titleSize,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: iconSize,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.green,
                strokeWidth: _clamp(screenWidth * 0.008, 2, 6),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: smallPaddingH,
                    vertical: smallPaddingV,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          if (_debounce?.isActive ?? false) {
                            _debounce!.cancel();
                          }
                          _debounce = Timer(const Duration(milliseconds: 500),
                              () async {
                            ref.read(searchQueryProvider.notifier).state =
                                value.trim();

                            await _fetchAmbulances(showLoader: false);
                          });
                        },
                        decoration: InputDecoration(
                          hintText: "Search ambulance service...",
                          hintStyle: TextStyle(fontSize: searchHintSize),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey,
                            size: searchPrefixSize,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(searchRadius),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: smallPaddingV,
                          ),
                        ),
                      )),
                      SizedBox(width: screenWidth * 0.02),
                      if (!isOffline && (userId == null || !hasMyAmbulance))
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(
                              horizontal: buttonPaddingH,
                              vertical: buttonPaddingV,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  _clamp(screenWidth * 0.025, 8, 16)),
                            ),
                          ),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            final userId = prefs.getString('userId');

                            if (userId == null) {
                              final shouldLogin =
                                  await showLoginRequiredDialog(context);

                              if (shouldLogin == true) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const Signin(),
                                  ),
                                );
                              }

                              return;
                            }

                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AmbulanceRegister(),
                              ),
                            );

                            if (result != null && result["refresh"] == true) {
                              ref.invalidate(ambulanceListProvider);
                              ref.invalidate(allAmbulancesProvider);

                              await _fetchAmbulances(showLoader: true);
                            }
                          },
                          child: Text("Register",
                              style: TextStyle(color: Colors.white)),
                        ),
                    ],
                  ),
                ),
                _buildLocationAndClearButton(
                    context, screenWidth, screenHeight),
                Expanded(
                  child: ambulanceList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: _clamp(screenWidth * 0.15, 60, 100),
                                color: Colors.grey,
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Text(
                                "No ambulances found",
                                style: TextStyle(
                                  fontSize: fontSizeBody,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
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
                                    fontSize:
                                        _clamp(screenWidth * 0.035, 14, 20),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: ambulanceList.length,
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03),
                          itemBuilder: (context, index) {
                            final amb = ambulanceList[index];
                            final address = amb['address'] ?? {};

                            return Card(
                              margin: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.01),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(cardRadius)),
                              elevation: elevation,
                              child: Padding(
                                padding: EdgeInsets.all(mediumPaddingH),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: EdgeInsets.all(
                                          _clamp(screenWidth * 0.03, 8, 16)),
                                      child: Icon(
                                        Icons.local_hospital,
                                        color: Colors.green,
                                        size: iconSizeBig,
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            amb["serviceName"] ?? "Unknown",
                                            style: TextStyle(
                                              fontSize: fontSizeBody,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.005),
                                          Text(
                                            "${address["place"] ?? ""}",
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: fontSizeSmall),
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.0025),
                                          Text(
                                            "${address["district"] ?? ""}, ${address["state"] ?? ""}, ${address["country"] ?? ""}",
                                            style: TextStyle(
                                                fontSize: fontSizeExtraSmall,
                                                color: Colors.black45),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.005),
                                          Text(
                                            "${amb["vehicleType"] ?? "N/A"}",
                                            style: TextStyle(
                                                fontSize: fontSizeSmall,
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
                                            size: iconSizeCall,
                                          ),
                                        ),
                                        if (amb["latitude"] != null &&
                                            amb["longitude"] != null)
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
                                              size: iconSizeCall,
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

  Widget _buildLocationAndClearButton(
      BuildContext context, double screenWidth, double screenHeight) {
    final double clearIconSize = _clamp(screenWidth * 0.05, 20, 30);
    final double fontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double borderWidth = _clamp(screenWidth * 0.0025, 0.5, 2);
    final double radius = _clamp(screenWidth * 0.025, 8, 16);

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04, vertical: screenHeight * 0.005),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () =>
                  _openLocationFilter(context, screenWidth, screenHeight),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenHeight * 0.0125),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.grey.shade300, width: borderWidth),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Text(
                  ref.watch(selectedCountryProvider).isEmpty
                      ? "Select Location"
                      : "${ref.watch(selectedCountryProvider)} > ${ref.watch(selectedStateProvider)} > ${ref.watch(selectedDistrictProvider)} > ${ref.watch(selectedPlaceProvider)}",
                  style: TextStyle(
                    fontSize: fontSize,
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
            icon: Icon(Icons.clear, color: Colors.red, size: clearIconSize),
            label: Text(
              "Clear",
              style: TextStyle(
                color: Colors.red,
                fontSize: fontSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openLocationFilter(
      BuildContext context, double screenWidth, double screenHeight) {
    String tempCountry = ref.read(selectedCountryProvider);
    String tempState = ref.read(selectedStateProvider);
    String tempDistrict = ref.read(selectedDistrictProvider);
    String tempPlace = ref.read(selectedPlaceProvider);

    final double modalRadius = _clamp(screenWidth * 0.05, 20, 40);
    final double fontSize = _clamp(screenWidth * 0.035, 13, 18);
    final double titleSize = _clamp(screenWidth * 0.045, 18, 28);
    final double dropdownRadius = _clamp(screenWidth * 0.025, 8, 16);
    final double dividerThickness = _clamp(screenWidth * 0.0025, 0.5, 2);
    final double buttonFontSize = _clamp(screenWidth * 0.04, 14, 22);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(modalRadius)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          final countries = getFilteredCountries();
          final filteredStates = getFilteredStates(tempCountry);
          final filteredDistricts =
              getFilteredDistricts(tempCountry, tempState);
          final filteredPlaces =
              getFilteredPlaces(tempCountry, tempState, tempDistrict);

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
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Divider(thickness: dividerThickness),
                  DropdownButtonFormField<String>(
                    value: tempCountry.isEmpty ? null : tempCountry,
                    decoration: InputDecoration(
                      labelText: "Country *",
                      labelStyle: TextStyle(fontSize: fontSize),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(dropdownRadius),
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
                        child: Text("Select Country",
                            style: TextStyle(color: Colors.grey)),
                      ),
                      ...countries.map((country) {
                        return DropdownMenuItem(
                          value: country,
                          child: Text(country,
                              style: TextStyle(fontSize: fontSize)),
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
                        labelStyle: TextStyle(fontSize: fontSize),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(dropdownRadius),
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
                          child: Text("Select State",
                              style: TextStyle(color: Colors.grey)),
                        ),
                        ...filteredStates.map((state) {
                          return DropdownMenuItem(
                            value: state,
                            child: Text(state,
                                style: TextStyle(fontSize: fontSize)),
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
                        labelStyle: TextStyle(fontSize: fontSize),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(dropdownRadius),
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
                          child: Text("Select District",
                              style: TextStyle(color: Colors.grey)),
                        ),
                        ...filteredDistricts.map((district) {
                          return DropdownMenuItem(
                            value: district,
                            child: Text(district,
                                style: TextStyle(fontSize: fontSize)),
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
                  if (tempCountry.isNotEmpty &&
                      tempState.isNotEmpty &&
                      tempDistrict.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      value: tempPlace.isEmpty ? null : tempPlace,
                      decoration: InputDecoration(
                        labelText: "Place",
                        labelStyle: TextStyle(fontSize: fontSize),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(dropdownRadius),
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
                          child: Text("Select Place",
                              style: TextStyle(color: Colors.grey)),
                        ),
                        ...filteredPlaces.map((place) {
                          return DropdownMenuItem(
                            value: place,
                            child: Text(place,
                                style: TextStyle(fontSize: fontSize)),
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
                      ref.read(selectedCountryProvider.notifier).state =
                          tempCountry;
                      ref.read(selectedStateProvider.notifier).state =
                          tempState;
                      ref.read(selectedDistrictProvider.notifier).state =
                          tempDistrict;
                      ref.read(selectedPlaceProvider.notifier).state =
                          tempPlace;
                      Navigator.pop(context);
                      _fetchAmbulances();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding:
                          EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            _clamp(screenWidth * 0.03, 10, 20)),
                      ),
                    ),
                    child: Text(
                      "Apply Filter",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: buttonFontSize,
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
