import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/providers/specialities-provider.dart';
import 'package:hosta/services/socket-service.dart';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

class Specialties extends ConsumerStatefulWidget {
  const Specialties({super.key});

  @override
  ConsumerState<Specialties> createState() => _SpecialitesState();
}

class _SpecialitesState extends ConsumerState<Specialties> {
  Timer? _debounceTimer;
  late Function(dynamic) _onSpecialityEvent;

  @override
  void initState() {
    super.initState();
    _onSpecialityEvent = (_) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          _refreshSpecialties();
        }
      });
    };
    SocketService().addListener(
      [
        'SPECIALITY_REGISTERED',
        'SPECIALITY_UPDATED',
        'SPECIALITY_DELETED',
      ],
      _onSpecialityEvent,
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    SocketService().removeListener("SPECIALITY_REGISTERED", _onSpecialityEvent);
    SocketService().removeListener("SPECIALITY_UPDATED", _onSpecialityEvent);
    SocketService().removeListener("SPECIALITY_DELETED", _onSpecialityEvent);
    super.dispose();
  }

  String toTitleCase(String text) {
    if (text.trim().isEmpty) return text;

    return text.trim().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  List<Map<String, dynamic>> removeDuplicateSpecialties(
      List<Map<String, dynamic>> specialties) {
    final Map<String, Map<String, dynamic>> unique = {};

    for (final specialty in specialties) {
      final name = (specialty['name'] ?? '').toString().trim().toLowerCase();

      if (!unique.containsKey(name)) {
        unique[name] = specialty;
      }
    }

    return unique.values.toList();
  }

  void _refreshSpecialties() {
    final searchQuery = ref.read(searchQueryProvider);
    ref.invalidate(specialtiesProvider(searchQuery));
  }

  void _showErrorSnackbar(String message) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double snackFontSize = _clamp(screenWidth * 0.04, 12, 20);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: snackFontSize),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive clamped values
    final double appBarTitleSize = _clamp(screenWidth * 0.05, 16, 24);
    final double backIconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double searchBoxPaddingH = _clamp(screenWidth * 0.04, 12, 24);
    final double searchBoxPaddingV = _clamp(screenHeight * 0.015, 8, 20);
    final double searchHintFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double searchIconSize = _clamp(screenWidth * 0.06, 20, 32);
    final double searchBorderRadius = _clamp(screenWidth * 0.03, 8, 16);
    final double gridPaddingH = _clamp(screenWidth * 0.04, 12, 24);
    final double gridPaddingV = _clamp(screenHeight * 0.01, 4, 16);
    final double gridMainSpacing = _clamp(screenWidth * 0.032, 8, 16);
    final double gridCrossSpacing = _clamp(screenWidth * 0.032, 8, 16);
    final double cardRadius = _clamp(screenWidth * 0.035, 10, 20);
    final double cardShadowBlur = _clamp(screenWidth * 0.008, 2, 6);
    final double avatarSize = _clamp(screenWidth * 0.22, 60, 120);
    final double avatarBorderWidth = _clamp(screenWidth * 0.005, 1, 3);
    final double specialtyIconSize = _clamp(screenWidth * 0.18, 40, 80);
    final double specialtyNameFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double loadingStrokeWidth = _clamp(screenWidth * 0.008, 2, 6);
    final double emptyIconSize = _clamp(screenWidth * 0.15, 50, 100);
    final double emptyTextSize = _clamp(screenWidth * 0.04, 14, 22);
    final double retryButtonPadH = _clamp(screenWidth * 0.06, 16, 40);
    final double retryButtonPadV = _clamp(screenHeight * 0.0125, 6, 20);
    final double retryButtonFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double progressValueStroke = _clamp(screenWidth * 0.005, 2, 4);
    final double bottomSheetRadius = _clamp(screenWidth * 0.05, 16, 32);
    final double sheetInitialChildSize = 0.7;
    final double sheetMinChildSize = 0.4;
    final double sheetMaxChildSize = 0.95;
    final double sheetHeaderFontSize = _clamp(screenWidth * 0.045, 16, 24);
    final double closeIconSize = _clamp(screenWidth * 0.06, 20, 32);
    final double dividerThickness = _clamp(screenWidth * 0.0025, 0.5, 2);
    final double hospitalCountFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double hospitalCardElevation = _clamp(screenWidth * 0.0075, 2, 6);
    final double hospitalCardRadius = _clamp(screenWidth * 0.03, 8, 16);
    final double hospitalCardPadding = _clamp(screenWidth * 0.04, 12, 24);
    final double hospitalAvatarSize = _clamp(screenWidth * 0.15, 40, 80);
    final double hospitalNameFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double hospitalDetailFontSize = _clamp(screenWidth * 0.0325, 11, 18);
    final double hospitalDetailSmallFontSize =
        _clamp(screenWidth * 0.03, 10, 16);
    final double hospitalIconSize = _clamp(screenWidth * 0.035, 12, 20);
    final double arrowIconSize = _clamp(screenWidth * 0.04, 14, 22);

    final searchQuery = ref.watch(searchQueryProvider);
    final specialtiesAsync = ref.watch(specialtiesProvider(searchQuery));
    final hospitalOps = ref.read(hospitalOperationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Medical Specialties",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: appBarTitleSize,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: backIconSize,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ===== Search Box =====
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: searchBoxPaddingH,
                vertical: searchBoxPaddingV,
              ),
              child: TextField(
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
                decoration: InputDecoration(
                  hintText: 'Search specialties...',
                  hintStyle: TextStyle(fontSize: searchHintFontSize),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: searchIconSize,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: searchBoxPaddingH,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(searchBorderRadius),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ===== Grid =====
            specialtiesAsync.when(
              data: (specialties) {
                final uniqueSpecialties = removeDuplicateSpecialties(
                    List<Map<String, dynamic>>.from(specialties));

                if (uniqueSpecialties.isEmpty) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: emptyIconSize, color: Colors.grey),
                          SizedBox(height: _clamp(screenHeight * 0.02, 12, 24)),
                          Text(
                            searchQuery.isEmpty
                                ? "No specialties found"
                                : "No matching specialties",
                            style: TextStyle(
                                fontSize: emptyTextSize, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: gridPaddingH,
                        vertical: gridPaddingV,
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: gridMainSpacing,
                          crossAxisSpacing: gridCrossSpacing,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: uniqueSpecialties.length,
                        itemBuilder: (context, index) {
                          final specialty = uniqueSpecialties[index];
                          final name =
                              specialty['name']?.toString() ?? 'Unknown';
                          const s3BaseUrl =
                              "https://hostahealthcare.s3.eu-north-1.amazonaws.com/";

                          String imageUrl =
                              specialty["imageUrl"]?.toString().trim() ?? "";

                          if (imageUrl.isNotEmpty &&
                              imageUrl != "null" &&
                              !imageUrl.startsWith("http")) {
                            imageUrl = "$s3BaseUrl$imageUrl";
                          }

                          return GestureDetector(
                            onTap: () async {
                              final originalSpecialtyName =
                                  specialty['name']?.toString() ?? '';
                              try {
                                await hospitalOps.fetchHospitalsForSpecialty(
                                    originalSpecialtyName);
                                if (mounted) {
                                  _showHospitalPopup(
                                      context, originalSpecialtyName);
                                }
                              } catch (e) {
                                // error handling
                              }
                            },
                            child: _buildCard(
                              name,
                              imageUrl,
                              screenWidth,
                              screenHeight,
                              cardRadius,
                              cardShadowBlur,
                              avatarSize,
                              avatarBorderWidth,
                              specialtyIconSize,
                              specialtyNameFontSize,
                              progressValueStroke,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              loading: () => Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.green,
                        strokeWidth: loadingStrokeWidth,
                      ),
                      SizedBox(height: _clamp(screenHeight * 0.02, 12, 24)),
                      Text(
                        "Loading specialties...",
                        style: TextStyle(
                          fontSize: emptyTextSize,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              error: (error, stack) => Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: emptyIconSize,
                        color: Colors.grey,
                      ),
                      SizedBox(height: _clamp(screenHeight * 0.02, 12, 24)),
                      Text(
                        "No specialties available",
                        style: TextStyle(
                          fontSize: emptyTextSize,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: _clamp(screenHeight * 0.02, 12, 24)),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(specialtiesProvider(searchQuery));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(
                            horizontal: retryButtonPadH,
                            vertical: retryButtonPadV,
                          ),
                        ),
                        child: Text(
                          "Retry",
                          style: TextStyle(
                            fontSize: retryButtonFontSize,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    String name,
    String imageUrl,
    double screenWidth,
    double screenHeight,
    double cardRadius,
    double cardShadowBlur,
    double avatarSize,
    double avatarBorderWidth,
    double specialtyIconSize,
    double specialtyNameFontSize,
    double progressValueStroke,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: cardShadowBlur,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imageUrl.isNotEmpty)
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.grey[300]!, width: avatarBorderWidth),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.medical_services,
                    size: specialtyIconSize,
                    color: Colors.green,
                  ),
                ),
              ),
            )
          else
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.grey[300]!, width: avatarBorderWidth),
              ),
              child: Icon(
                Icons.medical_services,
                size: specialtyIconSize,
                color: Colors.green,
              ),
            ),
          SizedBox(height: _clamp(screenHeight * 0.01, 4, 12)),
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: _clamp(screenWidth * 0.015, 4, 10)),
            child: Text(
              toTitleCase(name),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: specialtyNameFontSize,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: _clamp(screenHeight * 0.01, 4, 12)),
        ],
      ),
    );
  }

  void _showHospitalPopup(BuildContext context, String specialtyName) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final hospitalOps = ref.read(hospitalOperationsProvider);
    final hospitalsList = ref.watch(hospitalsForSpecialtyProvider);
    final isLoading = ref.read(hospitalsLoadingProvider);

    // Responsive values for bottom sheet
    final double bottomSheetRadius = _clamp(screenWidth * 0.05, 16, 32);
    final double headerFontSize = _clamp(screenWidth * 0.045, 16, 24);
    final double closeIconSize = _clamp(screenWidth * 0.06, 20, 32);
    final double dividerThickness = _clamp(screenWidth * 0.0025, 0.5, 2);
    final double countFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double loadingStrokeWidth = _clamp(screenWidth * 0.008, 2, 6);
    final double emptyIconSize = _clamp(screenWidth * 0.15, 50, 100);
    final double emptyTextSize = _clamp(screenWidth * 0.04, 14, 22);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(bottomSheetRadius)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              child: Column(
                children: [
                  // --- Header with Close Button ---
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _clamp(screenWidth * 0.04, 12, 24),
                      vertical: _clamp(screenHeight * 0.015, 8, 20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${specialtyName.toUpperCase()} HOSPITALS",
                            style: TextStyle(
                              fontSize: headerFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: closeIconSize,
                          ),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                      height: _clamp(screenHeight * 0.001, 0.5, 2),
                      thickness: dividerThickness),

                  // --- Hospital Count ---
                  Padding(
                    padding: EdgeInsets.symmetric(
                        vertical: _clamp(screenHeight * 0.015, 8, 20)),
                    child: Text(
                      "Found ${hospitalsList.length} hospitals",
                      style: TextStyle(
                        fontSize: countFontSize,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // --- Loading Indicator ---
                  if (isLoading)
                    Padding(
                      padding:
                          EdgeInsets.all(_clamp(screenWidth * 0.04, 12, 24)),
                      child: CircularProgressIndicator(
                        color: Colors.green,
                        strokeWidth: loadingStrokeWidth,
                      ),
                    )
                  else if (hospitalsList.isEmpty)
                    // --- No Hospitals Found ---
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_hospital_outlined,
                              size: emptyIconSize,
                              color: Colors.grey,
                            ),
                            SizedBox(
                                height: _clamp(screenHeight * 0.02, 12, 24)),
                            Text(
                              "No hospitals found",
                              style: TextStyle(
                                fontSize: emptyTextSize,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "for this specialty",
                              style: TextStyle(
                                fontSize: _clamp(screenWidth * 0.035, 12, 18),
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // --- Scrollable Hospital List ---
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: hospitalsList.length,
                        itemBuilder: (context, index) {
                          final hospital = hospitalsList[index];
                          return _buildHospitalCard(
                            context,
                            hospital,
                            specialtyName,
                            screenWidth,
                            screenHeight,
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHospitalCard(
    BuildContext context,
    Map<String, dynamic> hospital,
    String specialtyName,
    double screenWidth,
    double screenHeight,
  ) {
    final hospitalOps = ref.read(hospitalOperationsProvider);

    // Responsive values for hospital card
    final double cardMarginH = _clamp(screenWidth * 0.04, 12, 24);
    final double cardMarginV = _clamp(screenHeight * 0.01, 4, 16);
    final double cardElevation = _clamp(screenWidth * 0.0075, 2, 6);
    final double cardRadius = _clamp(screenWidth * 0.03, 8, 16);
    final double cardPadding = _clamp(screenWidth * 0.04, 12, 24);
    final double avatarSize = _clamp(screenWidth * 0.15, 40, 80);
    final double avatarBorderWidth = _clamp(screenWidth * 0.005, 1, 3);
    final double hospitalNameFontSize = _clamp(screenWidth * 0.04, 14, 22);
    final double detailFontSize = _clamp(screenWidth * 0.0325, 11, 18);
    final double smallDetailFontSize = _clamp(screenWidth * 0.03, 10, 16);
    final double iconSize = _clamp(screenWidth * 0.035, 12, 20);
    final double arrowIconSize = _clamp(screenWidth * 0.04, 14, 22);
    final double arrowPaddingLeft = _clamp(screenWidth * 0.02, 4, 12);

    // Handle image
    String imageUrl = '';
    final image = hospital['image'];
    if (image is Map) {
      imageUrl = image['imageUrl']?.toString() ?? '';
    } else if (image is String) {
      imageUrl = image;
    }

    final hospitalName =
        hospital['name']?.toString() ?? 'Hospital ${hospital['hospitalId']}';

    String addressText = '';
    final address = hospital['address'];
    if (address is Map) {
      final parts = <String>[];
      if (address['place'] != null) parts.add(address['place']);
      if (address['district'] != null) parts.add(address['district']);
      if (address['state'] != null) parts.add(address['state']);
      if (address['pincode'] != null) parts.add(address['pincode'].toString());
      addressText = parts.join(', ');
    } else if (address is String) {
      addressText = address;
    }

    final phone = hospital['phone']?.toString() ?? '';

    String hospitalId = '';
    if (hospital['id'] != null) {
      hospitalId = hospital['id'].toString();
    } else if (hospital['_id'] != null) {
      hospitalId = hospital['_id'].toString();
    } else if (hospital['hospitalId'] != null) {
      final rawId = hospital['hospitalId'].toString();
      if (!rawId.startsWith('#')) {
        hospitalId = rawId;
      }
    }

    final specialtyDoctorsCount =
        hospitalOps.getDoctorsCountForSpecialty(hospital, specialtyName);
    final totalDoctorsCount = hospitalOps.getTotalDoctorsCount(hospital);

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: cardMarginH,
        vertical: cardMarginV,
      ),
      elevation: cardElevation,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius)),
      child: InkWell(
        onTap: () {
          if (hospitalId.isNotEmpty) {
            hospitalOps.navigateToDoctorsPage(
                context, hospitalId, specialtyName, hospitalName);
          } else {
            _showErrorSnackbar("Hospital ID not available");
          }
        },
        borderRadius: BorderRadius.circular(cardRadius),
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHospitalAvatar(
                  imageUrl, screenWidth, avatarSize, avatarBorderWidth),
              SizedBox(width: _clamp(screenWidth * 0.03, 6, 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospitalName,
                      style: TextStyle(
                        fontSize: hospitalNameFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: _clamp(screenHeight * 0.0075, 4, 12)),
                    Row(
                      children: [
                        Icon(
                          Icons.medical_services,
                          size: iconSize,
                          color: Colors.green,
                        ),
                        SizedBox(width: _clamp(screenWidth * 0.01, 2, 8)),
                        Expanded(
                          child: Text(
                            "$specialtyDoctorsCount $specialtyName doctors",
                            style: TextStyle(
                              fontSize: detailFontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.green,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _clamp(screenHeight * 0.0025, 2, 4)),
                    Row(
                      children: [
                        Icon(
                          Icons.people_alt_outlined,
                          size: iconSize,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: _clamp(screenWidth * 0.01, 2, 8)),
                        Text(
                          "$totalDoctorsCount total doctors",
                          style: TextStyle(
                            fontSize: smallDetailFontSize,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _clamp(screenHeight * 0.0075, 4, 12)),
                    if (addressText.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: iconSize,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: _clamp(screenWidth * 0.01, 2, 8)),
                          Expanded(
                            child: Text(
                              addressText,
                              style: TextStyle(
                                fontSize: smallDetailFontSize,
                                color: Colors.grey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (phone.isNotEmpty) ...[
                      SizedBox(height: _clamp(screenHeight * 0.005, 2, 8)),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: iconSize,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: _clamp(screenWidth * 0.01, 2, 8)),
                          Text(
                            phone,
                            style: TextStyle(
                              fontSize: smallDetailFontSize,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: arrowPaddingLeft),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: arrowIconSize,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalAvatar(
    String imageUrl,
    double screenWidth,
    double avatarSize,
    double avatarBorderWidth,
  ) {
    if (imageUrl.isNotEmpty) {
      return Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.grey[300]!, width: avatarBorderWidth),
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.blue[100],
                child: Center(
                  child: Icon(
                    Icons.local_hospital,
                    size: _clamp(screenWidth * 0.06, 20, 40),
                    color: Colors.green,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } else {
      return Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          color: Colors.green[100],
          shape: BoxShape.circle,
          border:
              Border.all(color: Colors.grey[300]!, width: avatarBorderWidth),
        ),
        child: Center(
          child: Icon(
            Icons.local_hospital,
            size: _clamp(screenWidth * 0.06, 20, 40),
            color: Colors.green,
          ),
        ),
      );
    }
  }
}
