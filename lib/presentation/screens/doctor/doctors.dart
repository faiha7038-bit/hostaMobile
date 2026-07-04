import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hosta/common/login_dialoge.dart';
import 'package:hosta/presentation/screens/booking/register_booking.dart';
import 'package:hosta/services/api_service.dart';
import 'package:hosta/services/socket-service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/doctor/doctor_detail.dart';
import '../../../data/models/doctor_model.dart';

// Helper to clamp responsive values between safe limits
double _clamp(double value, double min, double max) =>
    value.clamp(min, max) as double;

class Doctors extends ConsumerStatefulWidget {
  final String hospitalId;
  final String specialty;

  const Doctors({super.key, required this.hospitalId, required this.specialty});

  @override
  ConsumerState<Doctors> createState() => _DoctorsState();
}

class _DoctorsState extends ConsumerState<Doctors> {
  String searchQuery = '';
  List<Doctor> doctors = [];
  bool isLoading = true;
  String? errorMessage;
  Timer? _debounceTimer;
  final ScrollController _scrollController = ScrollController();
  late Function(dynamic) _onDoctorEvent;
  int currentPage = 1;
  bool hasNextPage = true;
  bool isPaginationLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
    _setupSocket();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isPaginationLoading &&
          hasNextPage) {
        _fetchDoctors(loadMore: true);
      }
    });
  }

  void _setupSocket() {
    _onDoctorEvent = (_) {
      doctors.clear();
      currentPage = 1;
      hasNextPage = true;
      _fetchDoctors();
    };
    SocketService().addListener(
      [
        "DOCTOR_REGISTERED",
        "DOCTOR_UPDATED",
        "DOCTOR_DELETED",
        "DOCTOR_PASSWORD_RESET",
        "DOCTOR_PASSWORD_CHANGED",
      ],
      _onDoctorEvent,
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    SocketService().removeListener("DOCTOR_REGISTERED", _onDoctorEvent);
    SocketService().removeListener("DOCTOR_UPDATED", _onDoctorEvent);
    SocketService().removeListener("DOCTOR_DELETED", _onDoctorEvent);
    SocketService().removeListener("DOCTOR_PASSWORD_RESET", _onDoctorEvent);
    SocketService().removeListener("DOCTOR_PASSWORD_CHANGED", _onDoctorEvent);
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => searchQuery = value);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      doctors.clear();
      currentPage = 1;
      hasNextPage = true;
      _fetchDoctors(search: value.isEmpty ? null : value);
    });
  }

  Future<void> _fetchDoctors({
    String? search,
    bool loadMore = false,
  }) async {
    if (isPaginationLoading) return;
    if (!mounted) return;

    try {
      if (loadMore) {
        setState(() {
          isPaginationLoading = true;
        });
      } else {
        setState(() {
          isLoading = true;
          errorMessage = null;
          currentPage = 1;
        });
      }

      final response = await ApiService().getDoctors(
        hospitalId: widget.hospitalId,
        speciality: widget.specialty,
        searchQuery: search,
        page: currentPage,
        limit: 10,
      );

      if (!mounted) return;

      if (response.data['success'] == true) {
        final doctorsData = response.data['data'];
        final pagination = response.data['pagination'];
        final List<Doctor> newDoctors =
            doctorsData.map<Doctor>((e) => Doctor.fromJson(e)).toList();

        setState(() {
          if (loadMore) {
            doctors.addAll(newDoctors);
          } else {
            doctors = newDoctors;
          }
          hasNextPage = pagination['hasNextPage'] ?? false;
          if (hasNextPage) {
            currentPage++;
          }
          isLoading = false;
          isPaginationLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        isPaginationLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Responsive clamped values
    final double appBarTitleSize = _clamp(screenWidth * 0.055, 16, 24);
    final double backIconSize = _clamp(screenWidth * 0.055, 20, 32);
    final double searchBarHeight = _clamp(screenHeight * 0.06, 40, 60);
    final double searchBarRadius = _clamp(screenWidth * 0.04, 10, 20);
    final double searchBarPadding = _clamp(screenWidth * 0.05, 12, 24);
    final double searchIconSize = _clamp(screenWidth * 0.055, 16, 28);
    final double searchHintFontSize = _clamp(screenWidth * 0.035, 12, 18);
    final double emptyIconSize = _clamp(screenWidth * 0.2, 60, 120);
    final double emptyTitleSize = _clamp(screenWidth * 0.048, 16, 24);
    final double emptySubtitleSize = _clamp(screenWidth * 0.04, 14, 20);
    final double gridPadding = _clamp(screenWidth * 0.04, 12, 24);
    final double crossAxisSpacing = _clamp(screenWidth * 0.04, 12, 24);
    final double mainAxisSpacing = _clamp(screenWidth * 0.04, 12, 24);
    final double cardRadius = _clamp(screenWidth * 0.04, 12, 24);
    final double shadowBlur = _clamp(screenWidth * 0.02, 6, 16);
    final double cardPadding = _clamp(screenWidth * 0.03, 8, 16);
    final double avatarSize = _clamp(screenWidth * 0.12, 36, 56);
    final double avatarFontSize = _clamp(screenWidth * 0.048, 14, 24);
    final double nameFontSize = _clamp(screenWidth * 0.038, 12, 18);
    final double specialtyFontSize = _clamp(screenWidth * 0.03, 10, 14);
    final double qualificationFontSize = _clamp(screenWidth * 0.027, 9, 13);
    final double feeIconSize = _clamp(screenWidth * 0.032, 10, 16);
    final double feeFontSize = _clamp(screenWidth * 0.032, 10, 16);
    final double feeLabelSize = _clamp(screenWidth * 0.027, 9, 13);
    final double consultationFontSize = _clamp(screenWidth * 0.025, 8, 12);
    final double buttonPaddingV = _clamp(screenHeight * 0.015, 8, 14);
    final double buttonRadius = _clamp(screenWidth * 0.025, 8, 16);
    final double buttonFontSize = _clamp(screenWidth * 0.032, 10, 16);
    final double loadingStrokeWidth = _clamp(screenWidth * 0.008, 2, 6);
    final double gridChildAspectRatio = 0.75;

    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          "Doctors",
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
        bottom: false,
        child: Column(
          children: [
            _buildSearchBar(
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              searchBarHeight: searchBarHeight,
              searchBarRadius: searchBarRadius,
              searchBarPadding: searchBarPadding,
              searchIconSize: searchIconSize,
              searchHintFontSize: searchHintFontSize,
            ),
            Expanded(
              child: _buildContent(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                gridPadding: gridPadding,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                childAspectRatio: gridChildAspectRatio,
                cardRadius: cardRadius,
                shadowBlur: shadowBlur,
                cardPadding: cardPadding,
                avatarSize: avatarSize,
                avatarFontSize: avatarFontSize,
                nameFontSize: nameFontSize,
                specialtyFontSize: specialtyFontSize,
                qualificationFontSize: qualificationFontSize,
                feeIconSize: feeIconSize,
                feeFontSize: feeFontSize,
                feeLabelSize: feeLabelSize,
                consultationFontSize: consultationFontSize,
                buttonPaddingV: buttonPaddingV,
                buttonRadius: buttonRadius,
                buttonFontSize: buttonFontSize,
                loadingStrokeWidth: loadingStrokeWidth,
                emptyIconSize: emptyIconSize,
                emptyTitleSize: emptyTitleSize,
                emptySubtitleSize: emptySubtitleSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar({
    required double screenWidth,
    required double screenHeight,
    required double searchBarHeight,
    required double searchBarRadius,
    required double searchBarPadding,
    required double searchIconSize,
    required double searchHintFontSize,
  }) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(searchBarPadding),
      child: Container(
        height: searchBarHeight,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(searchBarRadius),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            SizedBox(width: _clamp(screenWidth * 0.04, 8, 20)),
            Icon(
              Icons.search_rounded,
              color: Colors.grey[500],
              size: searchIconSize,
            ),
            SizedBox(width: _clamp(screenWidth * 0.03, 6, 16)),
            Expanded(
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search doctors ',
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: searchHintFontSize,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required double screenWidth,
    required double screenHeight,
    required double gridPadding,
    required double crossAxisSpacing,
    required double mainAxisSpacing,
    required double childAspectRatio,
    required double cardRadius,
    required double shadowBlur,
    required double cardPadding,
    required double avatarSize,
    required double avatarFontSize,
    required double nameFontSize,
    required double specialtyFontSize,
    required double qualificationFontSize,
    required double feeIconSize,
    required double feeFontSize,
    required double feeLabelSize,
    required double consultationFontSize,
    required double buttonPaddingV,
    required double buttonRadius,
    required double buttonFontSize,
    required double loadingStrokeWidth,
    required double emptyIconSize,
    required double emptyTitleSize,
    required double emptySubtitleSize,
  }) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.green,
          strokeWidth: loadingStrokeWidth,
        ),
      );
    }
    if (errorMessage != null) {
      // error widget unchanged (no responsive changes needed)
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: emptyIconSize, color: Colors.grey),
            const SizedBox(height: 16),
            Text(errorMessage!),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _fetchDoctors(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // No doctors at all (initial load, no search query)
    if (doctors.isEmpty && searchQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_services,
              size: emptyIconSize,
              color: Colors.grey[300],
            ),
            SizedBox(height: screenHeight * 0.025),
            Text(
              'No Doctors found',
              style: TextStyle(
                fontSize: emptyTitleSize,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    // No results for the search
    if (doctors.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_information,
              size: emptyIconSize,
              color: Colors.grey[300],
            ),
            SizedBox(height: screenHeight * 0.025),
            Text(
              'No doctors found',
              style: TextStyle(
                fontSize: emptyTitleSize,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            // Text('Try adjusting your search', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }

    // Display doctors
    return Padding(
      padding: EdgeInsets.all(gridPadding),
      child: GridView.builder(
        controller: _scrollController,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: doctors.length + (isPaginationLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == doctors.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(_clamp(screenWidth * 0.04, 8, 20)),
                child: CircularProgressIndicator(
                  strokeWidth: loadingStrokeWidth,
                ),
              ),
            );
          }
          return _buildDoctorCard(
            doctor: doctors[index],
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            cardRadius: cardRadius,
            shadowBlur: shadowBlur,
            cardPadding: cardPadding,
            avatarSize: avatarSize,
            avatarFontSize: avatarFontSize,
            nameFontSize: nameFontSize,
            specialtyFontSize: specialtyFontSize,
            qualificationFontSize: qualificationFontSize,
            feeIconSize: feeIconSize,
            feeFontSize: feeFontSize,
            feeLabelSize: feeLabelSize,
            consultationFontSize: consultationFontSize,
            buttonPaddingV: buttonPaddingV,
            buttonRadius: buttonRadius,
            buttonFontSize: buttonFontSize,
          );
        },
      ),
    );
  }

  Widget _buildDoctorCard({
    required Doctor doctor,
    required double screenWidth,
    required double screenHeight,
    required double cardRadius,
    required double shadowBlur,
    required double cardPadding,
    required double avatarSize,
    required double avatarFontSize,
    required double nameFontSize,
    required double specialtyFontSize,
    required double qualificationFontSize,
    required double feeIconSize,
    required double feeFontSize,
    required double feeLabelSize,
    required double consultationFontSize,
    required double buttonPaddingV,
    required double buttonRadius,
    required double buttonFontSize,
  }) {
    String firstLetter = doctor.displayName.isNotEmpty
        ? doctor.displayName[0].toUpperCase()
        : (doctor.firstName.isNotEmpty ? doctor.firstName[0].toUpperCase() : 'D');
    String consultationInfo = "";
    if (doctor.outDoorConsulting != null) {
      consultationInfo = "🏥 ${doctor.outDoorConsulting!.place}";
    } else if (doctor.consulting.morningSession != null || doctor.consulting.eveningSession != null) {
      consultationInfo = "⏰ Available Today";
    } else {
      consultationInfo = "Consultation Available";
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctor: doctor)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(cardRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: shadowBlur,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(cardPadding),
              child: Row(
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        firstLetter,
                        style: TextStyle(
                          fontSize: avatarFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: _clamp(screenWidth * 0.025, 6, 16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor.name,
                          style: TextStyle(
                            fontSize: nameFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: screenHeight * 0.004),
                        Text(
                          doctor.specialty,
                          style: TextStyle(
                            fontSize: specialtyFontSize,
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: cardPadding),
              child: Text(
                doctor.qualification,
                style: TextStyle(
                  fontSize: qualificationFontSize,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: cardPadding, vertical: screenHeight * 0.005),
              child: Row(
                children: [
                  Icon(
                    Icons.currency_rupee,
                    size: feeIconSize,
                    color: Colors.grey,
                  ),
                  SizedBox(width: _clamp(screenWidth * 0.005, 2, 6)),
                  Text(
                    doctor.fees,
                    style: TextStyle(
                      fontSize: feeFontSize,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    " fee",
                    style: TextStyle(
                      fontSize: feeLabelSize,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (consultationInfo.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: cardPadding, vertical: screenHeight * 0.002),
                child: Text(
                  consultationInfo,
                  style: TextStyle(
                    fontSize: consultationFontSize,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const Spacer(),
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(cardPadding),
              child: ElevatedButton(
                onPressed: (doctor.bookingOpen && doctor.isActive)
                    ? () async {
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString('userId') ?? '';
                        if (userId.isEmpty) {
                          showLoginRequiredDialog(context);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegisterBooking(
                              doctor: doctor,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (doctor.bookingOpen && doctor.isActive)
                      ? Colors.green
                      : Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: buttonPaddingV),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(buttonRadius),
                  ),
                ),
                child: Text(
                  (doctor.bookingOpen && doctor.isActive)
                      ? 'BOOK NOW'
                      : 'CLOSED',
                  style: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}